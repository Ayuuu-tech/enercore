import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enercore_app/features/telemetry/data/telemetry_repository.dart';
import 'package:enercore_app/features/telemetry/presentation/widgets/single_line_diagram.dart';

DeviceModel device({
  required String name,
  required String type,
  String status = 'ACTIVE',
  double power = 0,
  double today = 0,
}) {
  return DeviceModel.fromJson({
    'id': name,
    'name': name,
    'type': type,
    'status': status,
    'activePowerKw': power,
    'dailyEnergyKwh': today,
    'acVoltage': 240,
    'acCurrent': 100,
    'acFrequency': 50,
  });
}

void main() {
  testWidgets('single-line diagram renders the plant, inverters and gensets', (tester) async {
    final devices = [
      device(name: 'Inverter_1', type: 'INVERTER', power: 77, today: 240),
      device(name: 'Inverter_2', type: 'INVERTER', power: 83.8, today: 254),
      device(name: 'Inverter_3', type: 'INVERTER', power: 84.5, today: 251),
      device(name: 'DG_1010KVA', type: 'OTHER', status: 'INACTIVE'),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 360, // a phone width, to catch horizontal overflow
            child: SingleLineDiagram(capacityKwp: 450, devices: devices),
          ),
        ),
      ),
    ));
    await tester.pump();

    // No overflow/layout exception was thrown, and the key nodes are present.
    expect(find.text('SOLAR PLANT'), findsOneWidget);
    expect(find.text('Inverter_1'), findsOneWidget);
    expect(find.text('Inverter_3'), findsOneWidget);
    expect(find.text('GENERATION TODAY'), findsOneWidget);
    expect(find.text('DG_1010KVA'), findsOneWidget);
    expect(find.text('OFF'), findsOneWidget); // inactive genset

    // Total today's generation = 240 + 254 + 251 = 745 kWh.
    expect(find.text('745 kWh'), findsOneWidget);
  });

  testWidgets('handles a plant with no gensets', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: SingleLineDiagram(
            capacityKwp: 500,
            devices: [
              device(name: '1 Solis 125kW', type: 'INVERTER', power: 60, today: 274),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('SOLAR PLANT'), findsOneWidget);
    expect(find.text('1 Solis 125kW'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
