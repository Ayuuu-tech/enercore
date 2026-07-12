import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:enercore_app/features/billing/domain/invoice_model.dart';
import 'package:enercore_app/features/dashboard/presentation/widgets/plant_map_view.dart';
import 'package:enercore_app/features/telemetry/data/telemetry_repository.dart';

void main() {
  // Both providers (Trackso, IO.Next) are normalised to one device shape by the
  // backend. If that contract drifts, every device screen silently breaks — so
  // pin the parsing rather than the pixels.
  group('DeviceModel.fromJson', () {
    test('parses a live inverter', () {
      final d = DeviceModel.fromJson({
        'id': '130:Inverter_1',
        'name': 'Inverter_1',
        'type': 'INVERTER',
        'status': 'ACTIVE',
        'capacity': null,
        'activePowerKw': 65.18,
        'dailyEnergyKwh': 245.2,
        'acVoltage': 242.8,
        'acCurrent': 266.5,
        'acFrequency': 50.03,
      });

      expect(d.name, 'Inverter_1');
      expect(d.type, 'INVERTER');
      expect(d.status, 'ACTIVE');
      expect(d.activePowerKw, 65.18);
      expect(d.acFrequency, 50.03);
    });

    test('falls back safely when optional fields are missing', () {
      final d = DeviceModel.fromJson({'id': 'x'});

      expect(d.type, 'OTHER');
      expect(d.status, 'UNKNOWN');
      expect(d.activePowerKw, 0);
    });
  });

  group('InvoiceModel.fromJson', () {
    test('parses a generated solar bill', () {
      final i = InvoiceModel.fromJson({
        'id': 'inv1',
        'invoiceNumber': 'ENERCORE/017',
        'amount': 131528.0,
        'period': 'January 2026',
        'status': 'PENDING',
        'dueDate': '2026-02-15T00:00:00.000Z',
        'paidAt': null,
        'userId': 'u1',
        'plantId': 'p1',
      });

      expect(i.invoiceNumber, 'ENERCORE/017');
      expect(i.amount, 131528.0);
      expect(i.status, 'PENDING');
      expect(i.paidAt, isNull);
      expect(i.dueDate.toUtc().day, 15); // bills always fall due on the 15th
    });
  });

  // The map only plots a plant it has coordinates for; an unmapped plant is
  // dropped rather than pinned somewhere wrong.
  group('plantCoordinatesFor', () {
    test('maps each monitored site, including the IO.Next one', () {
      expect(plantCoordinatesFor('Hollister'), isA<LatLng>());
      expect(plantCoordinatesFor('Caparo Maruti India Ltd Bawal'), isA<LatLng>());

      final hella = plantCoordinatesFor('Hella India');
      expect(hella, isNotNull);
      expect(hella!.latitude, closeTo(28.4778, 0.001));
      expect(hella.longitude, closeTo(76.9485, 0.001));
    });

    test('matches on name case-insensitively', () {
      expect(plantCoordinatesFor('HELLA INDIA'), isNotNull);
    });

    test('returns null for a plant it does not know', () {
      expect(plantCoordinatesFor('Some New Site'), isNull);
    });
  });
}
