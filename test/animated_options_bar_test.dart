import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animated_options_bar/animated_options_bar.dart';

class TestItem {
  final String id;
  final String label;

  const TestItem({required this.id, required this.label});
}

// Test configuration for use in tests
final _testConfig = OptionsBarConfig(
  textPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
  borderRadius: 25.0,
  itemSpacing: 12.0,
  scrollEdgePadding: 16.0,
  activeTextColor: Colors.blue,
  inactiveTextColor: Colors.grey,
  selectionColor: Colors.blue,
  animationDuration: Duration(milliseconds: 300),
);

void main() {
  group('OptionsBarConfig', () {
    test('test config has correct values', () {
      final config = _testConfig;
      expect(config.borderRadius, 25.0);
      expect(config.activeTextColor, Colors.blue);
      expect(config.inactiveTextColor, Colors.grey);
      expect(config.textPadding.left, 20.0);
      expect(config.textPadding.top, 10.0);
    });

    test('custom config can be created', () {
      final config = OptionsBarConfig(
        textPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        borderRadius: 25.0,
        itemSpacing: 12.0,
        scrollEdgePadding: 16.0,
        activeTextColor: Colors.blue,
        inactiveTextColor: Colors.grey,
        selectionColor: Colors.blue,
      );
      expect(config.borderRadius, 25.0);
      expect(config.activeTextColor, Colors.blue);
      expect(config.selectionColor, Colors.blue);
      expect(config.textPadding.left, 20.0);
      expect(config.textPadding.top, 10.0);
      expect(config.textPadding.horizontal, 40.0); // 2x horizontalPadding
      expect(config.textPadding.vertical, 20.0); // 2x verticalPadding
    });
  });

  group('AnimatedOptionsBar with String items', () {
    testWidgets('renders with String items without getId/getLabel', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionsBar<String>(
              items: const ['Option 1', 'Option 2', 'Option 3'],
              selectedId: 'Option 1',
              onItemSelected: (_) {},
              config: _testConfig,
            ),
          ),
        ),
      );

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Option 3'), findsOneWidget);
    });

    testWidgets('handles empty items list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionsBar<String>(
              items: const [],
              selectedId: 'Option 1',
              onItemSelected: (_) {},
              config: _testConfig,
            ),
          ),
        ),
      );

      // Should render empty widget
      expect(find.byType(AnimatedOptionsBar<String>), findsOneWidget);
    });

    testWidgets('handles invalid selectedId', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionsBar<String>(
              items: const ['Option 1', 'Option 2'],
              selectedId: 'Invalid',
              onItemSelected: (_) {},
              config: _testConfig,
            ),
          ),
        ),
      );

      // When selectedId is invalid, widget returns empty (graceful degradation)
      expect(find.byType(AnimatedOptionsBar<String>), findsOneWidget);
    });

    testWidgets('calls onItemSelected when item is tapped', (tester) async {
      String? selectedId;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionsBar<String>(
              items: const ['Option 1', 'Option 2', 'Option 3'],
              selectedId: 'Option 1',
              onItemSelected: (id) => selectedId = id,
              config: _testConfig,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Option 2'));
      expect(selectedId, 'Option 2');
    });
  });

  group('AnimatedOptionsBar with custom items', () {
    testWidgets('renders with custom items using getId/getLabel', (
      tester,
    ) async {
      const items = [
        TestItem(id: '1', label: 'First'),
        TestItem(id: '2', label: 'Second'),
        TestItem(id: '3', label: 'Third'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionsBar<TestItem>(
              items: items,
              selectedId: '1',
              onItemSelected: (_) {},
              getId: (item) => item.id,
              getLabel: (item) => item.label,
              config: _testConfig,
            ),
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
    });

    testWidgets('calls onItemSelected with correct id for custom items', (
      tester,
    ) async {
      String? selectedId;
      const items = [
        TestItem(id: '1', label: 'First'),
        TestItem(id: '2', label: 'Second'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionsBar<TestItem>(
              items: items,
              selectedId: '1',
              onItemSelected: (id) => selectedId = id,
              getId: (item) => item.id,
              getLabel: (item) => item.label,
              config: _testConfig,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Second'));
      expect(selectedId, '2');
    });
  });

  group('AnimatedOptionsBar layout modes', () {
    testWidgets('uses scrollbar mode when items overflow', (tester) async {
      // Create many items that will overflow
      final items = List.generate(10, (i) => 'Option ${i + 1}');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Narrow width to force scrollbar mode
              child: AnimatedOptionsBar<String>(
                items: items,
                selectedId: 'Option 1',
                onItemSelected: (_) {},
                config: _testConfig,
              ),
            ),
          ),
        ),
      );

      // Should find SingleChildScrollView for scrollbar mode
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('uses tabbar mode when items fit', (tester) async {
      // Create few items that will fit
      const items = ['Option 1', 'Option 2', 'Option 3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800, // Wide width to allow tabbar mode
              child: AnimatedOptionsBar<String>(
                items: items,
                selectedId: 'Option 1',
                onItemSelected: (_) {},
                config: _testConfig,
              ),
            ),
          ),
        ),
      );

      // Should not find SingleChildScrollView for tabbar mode
      expect(find.byType(SingleChildScrollView), findsNothing);
    });
  });

  group('AnimatedOptionsBar animations', () {
    testWidgets('skips animation on first build', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionsBar<String>(
              items: const ['Option 1', 'Option 2'],
              selectedId: 'Option 1',
              onItemSelected: (_) {},
              config: _testConfig,
            ),
          ),
        ),
      );

      // First build should complete immediately
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('animates when selection changes', (tester) async {
      String selectedId = 'Option 1';
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: AnimatedOptionsBar<String>(
                  items: const ['Option 1', 'Option 2'],
                  selectedId: selectedId,
                  onItemSelected: (id) => setState(() => selectedId = id),
                  config: _testConfig,
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Option 2'));
      await tester.pump();

      // Should trigger animation
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Option 2'), findsOneWidget);
    });
  });

  group('AnimatedOptionsBar edge cases', () {
    testWidgets('handles single item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionsBar<String>(
              items: const ['Only Option'],
              selectedId: 'Only Option',
              onItemSelected: (_) {},
              config: _testConfig,
            ),
          ),
        ),
      );

      expect(find.text('Only Option'), findsOneWidget);
    });

    testWidgets('handles very long item labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: AnimatedOptionsBar<String>(
                items: const [
                  'Very Long Option Name That Will Overflow',
                  'Another Long Option',
                ],
                selectedId: 'Very Long Option Name That Will Overflow',
                onItemSelected: (_) {},
                config: _testConfig,
              ),
            ),
          ),
        ),
      );

      // Should still render and use scrollbar mode
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('handles rapid selection changes', (tester) async {
      String selectedId = 'Option 1';
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: AnimatedOptionsBar<String>(
                  items: const ['Option 1', 'Option 2', 'Option 3'],
                  selectedId: selectedId,
                  onItemSelected: (id) => setState(() => selectedId = id),
                  config: _testConfig,
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Option 2'));
      await tester.pump();
      await tester.tap(find.text('Option 3'));
      await tester.pump();
      await tester.tap(find.text('Option 1'));
      await tester.pump();

      expect(find.text('Option 1'), findsOneWidget);
    });
  });

  group('AnimatedOptionsBar accessibility', () {
    testWidgets('includes Semantics widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedOptionsBar<String>(
              items: const ['Option 1', 'Option 2'],
              selectedId: 'Option 1',
              onItemSelected: (_) {},
              config: _testConfig,
            ),
          ),
        ),
      );

      // Should find Semantics widgets
      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
