import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/http/http_helper.dart';
import '../../auth/data/auth_repository.dart';
import '../../ticketing/data/plants_repository.dart';

final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return TelemetryRepository(authRepository);
});

final telemetryDashboardProvider = FutureProvider<TelemetryDashboardModel>((ref) async {
  final repo = ref.read(telemetryRepositoryProvider);
  return repo.getDashboard();
});

/// Energy generated (kWh) over day / week / month / year across all sites.
final periodYieldProvider = FutureProvider<PeriodYield>((ref) async {
  return ref.read(telemetryRepositoryProvider).getPeriodYields();
});

/// Today's generation curve summed across all of the user's plants (24h window).
final combinedGenerationSeriesProvider = FutureProvider<List<TelemetrySeriesPoint>>((ref) async {
  final plants = await ref.read(plantsRepositoryProvider).getPlants();
  final repo = ref.read(telemetryRepositoryProvider);
  final allSeries = await Future.wait(plants.map((p) => repo.getSeries(p.id, 24)));

  final merged = <int, TelemetrySeriesPoint>{};
  for (final series in allSeries) {
    for (final point in series) {
      final key = point.timestamp.millisecondsSinceEpoch;
      final existing = merged[key];
      merged[key] = existing == null
          ? point
          : TelemetrySeriesPoint(
              timestamp: point.timestamp,
              avgVoltage: (existing.avgVoltage + point.avgVoltage) / 2,
              totalCurrent: existing.totalCurrent + point.totalCurrent,
              avgTemperature: (existing.avgTemperature + point.avgTemperature) / 2,
              totalGeneration: existing.totalGeneration + point.totalGeneration,
            );
    }
  }
  final points = merged.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return points;
});

class TelemetryRepository {
  final AuthRepository _authRepository;

  TelemetryRepository(this._authRepository);

  Future<TelemetryDashboardModel> getDashboard() async {
    final token = _authRepository.token;
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/telemetry/dashboard'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return TelemetryDashboardModel.fromJson(data);
    } else {
      throw Exception('Failed to fetch dashboard metrics: ${response.statusCode}');
    }
  }

  /// Energy generated (kWh) over day/week/month/year across all sites.
  Future<PeriodYield> getPeriodYields() async {
    final token = _authRepository.token;
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/telemetry/period-yield'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return PeriodYield.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch period yields: ${response.statusCode}');
  }

  /// Fetches the plant's real Trackso devices (inverters/meters) with live status.
  Future<List<DeviceModel>> getDevices(String plantId) async {
    final token = _authRepository.token;
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/telemetry/plant/$plantId/devices'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => DeviceModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch devices: ${response.statusCode}');
    }
  }

  /// Fetches time-bucketed telemetry aggregates for a plant.
  Future<List<TelemetrySeriesPoint>> getSeries(String plantId, int hours) async {
    final token = _authRepository.token;
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/telemetry/plant/$plantId/series?hours=$hours'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TelemetrySeriesPoint.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch telemetry series: ${response.statusCode}');
    }
  }

  /// Generates a Trackso site report (xlsx). Returns the file bytes and name.
  Future<({List<int> bytes, String filename})> generateSiteReport({
    required String plantId,
    required String frequency, // DAILY | WEEKLY | MONTHLY | YEARLY
    required DateTime date,
  }) async {
    final token = _authRepository.token;
    // Report generation proxies to Trackso and can take a while; use a longer timeout.
    final response = await http
        .post(
          Uri.parse('${_authRepository.baseUrl}/telemetry/reports/site'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'plantId': plantId,
            'frequency': frequency,
            'date': date.millisecondsSinceEpoch,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final disposition = response.headers['content-disposition'] ?? '';
      final match = RegExp('filename="(.+)"').firstMatch(disposition);
      final filename = match?.group(1) ?? 'enercore-report.xlsx';
      return (bytes: response.bodyBytes, filename: filename);
    }

    String message = 'Failed to generate report: ${response.statusCode}';
    try {
      final err = jsonDecode(response.body);
      if (err['message'] != null) message = err['message'].toString();
    } catch (_) {}
    throw Exception(message);
  }
}

class TelemetryDashboardModel {
  final double totalPower;
  final double todayYield;
  final double lifetimeYield;
  final double performanceRatio;
  final Map<String, PlantMetricModel> plants;
  final List<AlertModel> alerts;

  TelemetryDashboardModel({
    required this.totalPower,
    required this.todayYield,
    required this.lifetimeYield,
    required this.performanceRatio,
    required this.plants,
    required this.alerts,
  });

  factory TelemetryDashboardModel.fromJson(Map<String, dynamic> json) {
    final plantsJson = json['plants'] as Map<String, dynamic>? ?? {};
    final plantsMap = plantsJson.map((key, value) => MapEntry(
          key,
          PlantMetricModel.fromJson(value as Map<String, dynamic>),
        ));

    final alertsList = json['alerts'] as List<dynamic>? ?? [];
    final alertsMap = alertsList.map((a) => AlertModel.fromJson(a as Map<String, dynamic>)).toList();

    return TelemetryDashboardModel(
      totalPower: (json['totalPower'] as num?)?.toDouble() ?? 0.0,
      todayYield: (json['todayYield'] as num?)?.toDouble() ?? 0.0,
      lifetimeYield: (json['lifetimeYield'] as num?)?.toDouble() ?? 0.0,
      performanceRatio: (json['performanceRatio'] as num?)?.toDouble() ?? 82.0,
      plants: plantsMap,
      alerts: alertsMap,
    );
  }
}

class PlantMetricModel {
  final String siteName;
  final double livePower;
  final double dailyEnergy;
  final double totalEnergy;
  final double specificYield;
  final double cuf;
  final String status;

  PlantMetricModel({
    required this.siteName,
    required this.livePower,
    required this.dailyEnergy,
    required this.totalEnergy,
    required this.specificYield,
    required this.cuf,
    required this.status,
  });

  factory PlantMetricModel.fromJson(Map<String, dynamic> json) {
    return PlantMetricModel(
      siteName: json['siteName'] as String? ?? '',
      livePower: (json['livePower'] as num?)?.toDouble() ?? 0.0,
      dailyEnergy: (json['dailyEnergy'] as num?)?.toDouble() ?? 0.0,
      totalEnergy: (json['totalEnergy'] as num?)?.toDouble() ?? 0.0,
      specificYield: (json['specificYield'] as num?)?.toDouble() ?? 0.0,
      cuf: (json['cuf'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Active',
    );
  }
}

class AlertModel {
  final String type;
  final String title;
  final String location;
  final String time;

  AlertModel({
    required this.type,
    required this.title,
    required this.location,
    required this.time,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      type: json['type'] as String? ?? 'INFO',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      time: json['time'] as String? ?? '',
    );
  }
}

class PeriodYield {
  final double day;
  final double week;
  final double month;
  final double year;

  PeriodYield({required this.day, required this.week, required this.month, required this.year});

  factory PeriodYield.fromJson(Map<String, dynamic> json) {
    return PeriodYield(
      day: (json['day'] as num?)?.toDouble() ?? 0,
      week: (json['week'] as num?)?.toDouble() ?? 0,
      month: (json['month'] as num?)?.toDouble() ?? 0,
      year: (json['year'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DeviceModel {
  final String id;
  final String name;
  final String type; // INVERTER | METER | OTHER
  final String status; // ACTIVE | ERROR | INACTIVE | UNKNOWN
  final double? capacity;
  final double activePowerKw;
  final double dailyEnergyKwh;
  final double acVoltage; // avg of 3 phases (V)
  final double acCurrent; // sum of 3 phases (A)
  final double acFrequency; // Hz

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.capacity,
    required this.activePowerKw,
    required this.dailyEnergyKwh,
    required this.acVoltage,
    required this.acCurrent,
    required this.acFrequency,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'OTHER',
      status: json['status'] as String? ?? 'UNKNOWN',
      capacity: (json['capacity'] as num?)?.toDouble(),
      activePowerKw: (json['activePowerKw'] as num?)?.toDouble() ?? 0,
      dailyEnergyKwh: (json['dailyEnergyKwh'] as num?)?.toDouble() ?? 0,
      acVoltage: (json['acVoltage'] as num?)?.toDouble() ?? 0,
      acCurrent: (json['acCurrent'] as num?)?.toDouble() ?? 0,
      acFrequency: (json['acFrequency'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TelemetrySeriesPoint {
  final DateTime timestamp;
  final double avgVoltage;
  final double totalCurrent;
  final double avgTemperature;
  final double totalGeneration;

  TelemetrySeriesPoint({
    required this.timestamp,
    required this.avgVoltage,
    required this.totalCurrent,
    required this.avgTemperature,
    required this.totalGeneration,
  });

  factory TelemetrySeriesPoint.fromJson(Map<String, dynamic> json) {
    return TelemetrySeriesPoint(
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      avgVoltage: (json['avgVoltage'] as num?)?.toDouble() ?? 0.0,
      totalCurrent: (json['totalCurrent'] as num?)?.toDouble() ?? 0.0,
      avgTemperature: (json['avgTemperature'] as num?)?.toDouble() ?? 0.0,
      totalGeneration: (json['totalGeneration'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
