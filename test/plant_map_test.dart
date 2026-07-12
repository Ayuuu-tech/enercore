import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:enercore_app/features/dashboard/presentation/widgets/plant_map_view.dart';

void main() {
  const sites = [
    PlantSite(name: 'Hollister', position: LatLng(28.0965, 76.6055)),
    PlantSite(name: 'Caparo Maruti India Ltd Bawal', position: LatLng(28.0902, 76.5808)),
    PlantSite(name: 'Hella India', position: LatLng(28.4778, 76.9485), active: false),
  ];

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('map preview labels every pin with its site name', (tester) async {
    await tester.pumpWidget(host(PlantMapPreview(sites: sites, onTap: () {})));
    await tester.pump();

    for (final s in sites) {
      expect(find.text(s.name), findsOneWidget, reason: '${s.name} should be labelled on the map');
    }
    // One pin per site.
    expect(find.byIcon(Icons.location_on), findsNWidgets(sites.length));
  });

  testWidgets('an inactive site is pinned in red, an active one in the brand colour', (tester) async {
    await tester.pumpWidget(host(PlantMapPreview(sites: sites, onTap: () {})));
    await tester.pump();

    final pins = tester.widgetList<Icon>(find.byIcon(Icons.location_on)).toList();
    expect(pins.any((i) => i.color == const Color(0xFFEF4444)), isTrue); // Hella (inactive)
    expect(pins.any((i) => i.color == const Color(0xFF2A8C6E)), isTrue); // the active ones
  });
}
