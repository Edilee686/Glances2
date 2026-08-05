import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glances/data/mock_people.dart';
import 'package:glances/main.dart';
import 'package:glances/services/api.dart';
import 'package:glances/state/app_state.dart';

void main() {
  testWidgets('splash shows the wordmark', (tester) async {
    await tester.pumpWidget(GlancesApp(state: AppState(MockApi(List.of(mockPeople)))));
    expect(find.text('GLANCES'), findsOneWidget);
    expect(find.text('See. Like. Date.'), findsOneWidget);
  });

  testWidgets('range never leaves 5-20 m', (tester) async {
    final state = AppState(MockApi(List.of(mockPeople)));
    state.setRange(40);
    expect(state.rangeMeters, 20);
    state.setRange(1);
    expect(state.rangeMeters, 5);
  });
}
