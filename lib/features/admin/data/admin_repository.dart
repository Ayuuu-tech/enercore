import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/http_helper.dart';
import '../../auth/data/auth_repository.dart';
import '../../ticketing/domain/plant_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.read(authRepositoryProvider));
});

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  return ref.read(adminRepositoryProvider).listUsers();
});

final adminAnalyticsProvider = FutureProvider<AdminAnalytics>((ref) async {
  return ref.read(adminRepositoryProvider).getAnalytics();
});

final adminSubscriptionsProvider = FutureProvider<List<SubscriptionModel>>((ref) async {
  return ref.read(adminRepositoryProvider).listSubscriptions();
});

final adminPaymentsProvider = FutureProvider<List<PaymentModel>>((ref) async {
  return ref.read(adminRepositoryProvider).listPayments();
});

final adminPlantsProvider = FutureProvider<List<AdminPlant>>((ref) async {
  return ref.read(adminRepositoryProvider).listPlants();
});

final adminAuditLogsProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  return ref.read(adminRepositoryProvider).listAuditLogs();
});

/// All client-app modules an admin can grant/revoke per user.
const kAllModules = <String, String>{
  'dashboard': 'Dashboard',
  'plants': 'Plants / Solar Grid',
  'telemetry': 'Telemetry',
  'reports': 'Reports',
  'billing': 'Billing',
  'tickets': 'Tickets',
  'marketplace': 'Marketplace',
  'notifications': 'Notifications',
};

/// Plants assigned to (accessible by) a specific user.
final userPlantsProvider =
    FutureProvider.family<List<PlantModel>, String>((ref, userId) async {
  return ref.read(adminRepositoryProvider).getUserPlants(userId);
});

class AdminRepository {
  final AuthRepository _auth;
  AdminRepository(this._auth);

  Map<String, String> get _headers {
    final token = _auth.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String get _base => _auth.baseUrl;

  Future<List<AdminUser>> listUsers() async {
    final res = await httpGet(Uri.parse('$_base/admin/users'), headers: _headers);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => AdminUser.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load users: ${res.statusCode}');
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final res = await httpPost(
      Uri.parse('$_base/admin/users'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      String msg = 'Failed to create user: ${res.statusCode}';
      try {
        final e = jsonDecode(res.body);
        if (e['message'] != null) msg = e['message'].toString();
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<void> setActive(String userId, bool isActive) async {
    final res = await httpPut(
      Uri.parse('$_base/admin/users/$userId/active'),
      headers: _headers,
      body: jsonEncode({'isActive': isActive}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update status: ${res.statusCode}');
    }
  }

  Future<void> setRole(String userId, String role) async {
    final res = await httpPut(
      Uri.parse('$_base/admin/users/$userId/role'),
      headers: _headers,
      body: jsonEncode({'role': role}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update role: ${res.statusCode}');
    }
  }

  Future<List<PlantModel>> getUserPlants(String userId) async {
    final res = await httpGet(Uri.parse('$_base/admin/users/$userId/plants'), headers: _headers);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => PlantModel.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load user plants: ${res.statusCode}');
  }

  Future<void> setUserPlants(String userId, List<String> plantIds) async {
    final res = await httpPut(
      Uri.parse('$_base/admin/users/$userId/plants'),
      headers: _headers,
      body: jsonEncode({'plantIds': plantIds}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update plant access: ${res.statusCode}');
    }
  }

  // ── Analytics ──────────────────────────────────────────────────────────────
  Future<AdminAnalytics> getAnalytics() async {
    final res = await httpGet(Uri.parse('$_base/admin/analytics'), headers: _headers);
    if (res.statusCode == 200) {
      return AdminAnalytics.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load analytics: ${res.statusCode}');
  }

  // ── Subscriptions ────────────────────────────────────────────────────────────
  Future<List<SubscriptionModel>> listSubscriptions() async {
    final res = await httpGet(Uri.parse('$_base/admin/subscriptions'), headers: _headers);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => SubscriptionModel.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load subscriptions: ${res.statusCode}');
  }

  Future<void> createSubscription({
    required String userId,
    required String plan,
    required num amount,
    bool activate = true,
  }) async {
    final res = await httpPost(
      Uri.parse('$_base/admin/subscriptions'),
      headers: _headers,
      body: jsonEncode({'userId': userId, 'plan': plan, 'amount': amount, 'activate': activate}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create subscription: ${res.statusCode}');
    }
  }

  Future<void> setSubscriptionStatus(String id, String status) async {
    final res = await httpPut(
      Uri.parse('$_base/admin/subscriptions/$id/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode != 200) throw Exception('Failed to update subscription: ${res.statusCode}');
  }

  Future<void> renewSubscription(String id) async {
    final res = await httpPost(Uri.parse('$_base/admin/subscriptions/$id/renew'), headers: _headers);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to renew subscription: ${res.statusCode}');
    }
  }

  // ── Payments ─────────────────────────────────────────────────────────────────
  Future<List<PaymentModel>> listPayments() async {
    final res = await httpGet(Uri.parse('$_base/admin/payments'), headers: _headers);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => PaymentModel.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load payments: ${res.statusCode}');
  }

  Future<void> recordPayment({
    required String userId,
    required num amount,
    required String status,
    String? method,
  }) async {
    final res = await httpPost(
      Uri.parse('$_base/admin/payments'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'amount': amount,
        'status': status,
        if (method != null && method.isNotEmpty) 'method': method,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to record payment: ${res.statusCode}');
    }
  }

  Future<void> updatePaymentStatus(String id, String status) async {
    final res = await httpPut(
      Uri.parse('$_base/admin/payments/$id/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode != 200) throw Exception('Failed to update payment: ${res.statusCode}');
  }

  // ── Plant management ─────────────────────────────────────────────────────────
  Future<List<AdminPlant>> listPlants() async {
    final res = await httpGet(Uri.parse('$_base/admin/plants'), headers: _headers);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => AdminPlant.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load plants: ${res.statusCode}');
  }

  Future<void> createPlant({
    required String name,
    required String location,
    required num peakCapacity,
  }) async {
    final res = await httpPost(
      Uri.parse('$_base/plants'),
      headers: _headers,
      body: jsonEncode({'name': name, 'location': location, 'peakCapacity': peakCapacity}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create plant: ${res.statusCode}');
    }
  }

  Future<void> updatePlant(String id, {String? name, String? location, num? peakCapacity, String? status}) async {
    final res = await httpPut(
      Uri.parse('$_base/plants/$id'),
      headers: _headers,
      body: jsonEncode({
        'name': ?name,
        'location': ?location,
        'peakCapacity': ?peakCapacity,
        'status': ?status,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to update plant: ${res.statusCode}');
  }

  Future<void> deletePlant(String id) async {
    final res = await httpDelete(Uri.parse('$_base/plants/$id'), headers: _headers);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete plant: ${res.statusCode}');
    }
  }

  Future<void> transferOwnership(String plantId, String newOwnerId) async {
    final res = await httpPut(
      Uri.parse('$_base/admin/plants/$plantId/owner'),
      headers: _headers,
      body: jsonEncode({'ownerId': newOwnerId}),
    );
    if (res.statusCode != 200) throw Exception('Failed to transfer ownership: ${res.statusCode}');
  }

  // ── Module permissions ───────────────────────────────────────────────────────
  Future<void> setUserModules(String userId, List<String> modules) async {
    final res = await httpPut(
      Uri.parse('$_base/admin/users/$userId/modules'),
      headers: _headers,
      body: jsonEncode({'modules': modules}),
    );
    if (res.statusCode != 200) throw Exception('Failed to update modules: ${res.statusCode}');
  }

  // ── Audit logs ───────────────────────────────────────────────────────────────
  Future<List<AuditLogEntry>> listAuditLogs() async {
    final res = await httpGet(Uri.parse('$_base/admin/audit-logs'), headers: _headers);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((j) => AuditLogEntry.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load audit logs: ${res.statusCode}');
  }
}

class AuditLogEntry {
  final String id;
  final String actorName;
  final String action;
  final String? targetType;
  final String? detail;
  final DateTime createdAt;

  AuditLogEntry({
    required this.id,
    required this.actorName,
    required this.action,
    required this.targetType,
    required this.detail,
    required this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> j) => AuditLogEntry(
        id: j['id'] as String,
        actorName: j['actorName'] as String? ?? '',
        action: j['action'] as String? ?? '',
        targetType: j['targetType'] as String?,
        detail: j['detail'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      );
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final List<String> modules;
  final String? phone;
  final int ownedPlants;
  final int grantedPlants;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.modules,
    required this.phone,
    required this.ownedPlants,
    required this.grantedPlants,
  });

  int get totalPlants => ownedPlants + grantedPlants;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'CLIENT',
      isActive: json['isActive'] as bool? ?? true,
      modules: (json['modules'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      phone: json['phone'] as String?,
      ownedPlants: (json['ownedPlants'] as num?)?.toInt() ?? 0,
      grantedPlants: (json['grantedPlants'] as num?)?.toInt() ?? 0,
    );
  }
}

class RecentUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  RecentUser(this.id, this.name, this.email, this.role, this.isActive, this.createdAt);
  factory RecentUser.fromJson(Map<String, dynamic> j) => RecentUser(
        j['id'] as String,
        j['name'] as String? ?? '',
        j['email'] as String? ?? '',
        j['role'] as String? ?? 'CLIENT',
        j['isActive'] as bool? ?? true,
        DateTime.parse(j['createdAt'] as String).toLocal(),
      );
}

class ExpiredSub {
  final String userName;
  final String plan;
  final DateTime expiryDate;
  ExpiredSub(this.userName, this.plan, this.expiryDate);
  factory ExpiredSub.fromJson(Map<String, dynamic> j) => ExpiredSub(
        j['userName'] as String? ?? '',
        j['plan'] as String? ?? '',
        DateTime.parse(j['expiryDate'] as String).toLocal(),
      );
}

class AdminAnalytics {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final int pendingSubscriptions;
  final num totalRevenue;
  final num monthlyRevenue;
  final List<RecentUser> recentUsers;
  final List<ExpiredSub> recentlyExpired;

  AdminAnalytics({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.activeSubscriptions,
    required this.expiredSubscriptions,
    required this.pendingSubscriptions,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.recentUsers,
    required this.recentlyExpired,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> j) => AdminAnalytics(
        totalUsers: (j['totalUsers'] as num?)?.toInt() ?? 0,
        activeUsers: (j['activeUsers'] as num?)?.toInt() ?? 0,
        inactiveUsers: (j['inactiveUsers'] as num?)?.toInt() ?? 0,
        activeSubscriptions: (j['activeSubscriptions'] as num?)?.toInt() ?? 0,
        expiredSubscriptions: (j['expiredSubscriptions'] as num?)?.toInt() ?? 0,
        pendingSubscriptions: (j['pendingSubscriptions'] as num?)?.toInt() ?? 0,
        totalRevenue: (j['totalRevenue'] as num?) ?? 0,
        monthlyRevenue: (j['monthlyRevenue'] as num?) ?? 0,
        recentUsers: ((j['recentUsers'] as List<dynamic>?) ?? [])
            .map((e) => RecentUser.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentlyExpired: ((j['recentlyExpired'] as List<dynamic>?) ?? [])
            .map((e) => ExpiredSub.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SubscriptionModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String plan; // MONTHLY | YEARLY
  final String status; // ACTIVE | EXPIRED | PENDING | SUSPENDED | CANCELLED
  final num amount;
  final DateTime startDate;
  final DateTime expiryDate;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.plan,
    required this.status,
    required this.amount,
    required this.startDate,
    required this.expiryDate,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> j) => SubscriptionModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        userName: j['userName'] as String? ?? '',
        userEmail: j['userEmail'] as String? ?? '',
        plan: j['plan'] as String? ?? 'MONTHLY',
        status: j['status'] as String? ?? 'PENDING',
        amount: (j['amount'] as num?) ?? 0,
        startDate: DateTime.parse(j['startDate'] as String).toLocal(),
        expiryDate: DateTime.parse(j['expiryDate'] as String).toLocal(),
      );
}

class AdminPlant {
  final String id;
  final String name;
  final String location;
  final num peakCapacity;
  final String status;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final int grantedUsers;

  AdminPlant({
    required this.id,
    required this.name,
    required this.location,
    required this.peakCapacity,
    required this.status,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.grantedUsers,
  });

  factory AdminPlant.fromJson(Map<String, dynamic> j) => AdminPlant(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        location: j['location'] as String? ?? '',
        peakCapacity: (j['peakCapacity'] as num?) ?? 0,
        status: j['status'] as String? ?? 'Active',
        ownerId: j['ownerId'] as String? ?? '',
        ownerName: j['ownerName'] as String? ?? '',
        ownerEmail: j['ownerEmail'] as String? ?? '',
        grantedUsers: (j['grantedUsers'] as num?)?.toInt() ?? 0,
      );
}

class PaymentModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final num amount;
  final String status; // SUCCESS | PENDING | FAILED | REFUNDED
  final String? method;
  final DateTime? paidAt;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.amount,
    required this.status,
    required this.method,
    required this.paidAt,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        userName: j['userName'] as String? ?? '',
        userEmail: j['userEmail'] as String? ?? '',
        amount: (j['amount'] as num?) ?? 0,
        status: j['status'] as String? ?? 'PENDING',
        method: j['method'] as String?,
        paidAt: j['paidAt'] != null ? DateTime.parse(j['paidAt'] as String).toLocal() : null,
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      );
}
