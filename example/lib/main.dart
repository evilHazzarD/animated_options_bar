import 'package:flutter/material.dart';
import 'package:animated_options_bar/animated_options_bar.dart';

// Color constants
const _orangeColor = Colors.orange;
const _blackColor = Colors.black;
const _whiteColor = Colors.white;
const _greenColor = Colors.green;
const _redColor = Colors.red;
const _greyColor = Colors.grey;

// Level 0 configuration (pill shape, black text when selected)
final _lvl0Config = OptionsBarConfig(
  textPadding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
  borderRadius: 50.0,
  itemSpacing: 16.0,
  scrollEdgePadding: 16.0,
  activeTextColor: _blackColor,
  inactiveTextColor: _whiteColor,
  selectionColor: _orangeColor,
  animationDuration: Duration(milliseconds: 300),
  arrowInset: 4.0, // 4px from screen edge (parent has no horizontal padding)
  centerOptions: true, // Center items in the bar
);

// Level 1 configuration (rounded rectangle, white text when selected)
final _lvl1Config = OptionsBarConfig(
  textPadding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
  borderRadius: 20.0,
  itemSpacing: 8.0,
  scrollEdgePadding: 8.0,
  activeTextColor: _whiteColor,
  inactiveTextColor: _blackColor,
  selectionColor: _orangeColor,
  animationDuration: Duration(milliseconds: 300),
  arrowInset: 4.0, // Positioned from widget edge
  centerOptions: false, // Keep default alignment
);

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animated Options Bar Example',
      theme: ThemeData(primarySwatch: _orangeColor, useMaterial3: true),
      home: const SetConfiguratorExampleScreen(),
    );
  }
}

/// Example item class
class ExampleItem {
  final String id;
  final String label;
  final bool enabled;

  const ExampleItem({
    required this.id,
    required this.label,
    this.enabled = true,
  });
}

/// Example screen similar to SetConfiguratorScreen
class SetConfiguratorExampleScreen extends StatefulWidget {
  const SetConfiguratorExampleScreen({super.key});

  @override
  State<SetConfiguratorExampleScreen> createState() =>
      _SetConfiguratorExampleScreenState();
}

class _SetConfiguratorExampleScreenState
    extends State<SetConfiguratorExampleScreen> {
  // Level 0 items (bottom bar): Main navigation options
  final List<ExampleItem> _optionsLvl0 = [
    ExampleItem(id: 'Option1', label: 'Option1'),
    ExampleItem(id: 'Option2', label: 'Option2'),
    ExampleItem(id: 'Option3', label: 'Option3'),
  ];

  // Level 1 items (above level 0): Configuration options
  final List<ExampleItem> _optionsLvl1 = [
    ExampleItem(id: 'Option1', label: 'Option1'),
    ExampleItem(id: 'Option2', label: 'Option 2 Long Title'),
    ExampleItem(id: 'Option3', label: 'Option3'),
    ExampleItem(id: 'Option4', label: 'Option 4 Long Title'),
    ExampleItem(id: 'Option5', label: 'Option5'),
    ExampleItem(id: 'Option6', label: 'Option 6 Long Title'),
    ExampleItem(id: 'Option7', label: 'Option7'),
  ];

  late String _selectedLvl0 = _optionsLvl0.first.id;
  late String _selectedLvl1 = _optionsLvl1.first.id;

  int _lvl0Counter = 4; // Start from 4 (after Option1, Option2, Option3)
  int _lvl1Counter = 8; // Start from 8 (after Option1-7)

  void _selectLvl0(String id) {
    setState(() {
      _selectedLvl0 = id;
    });
  }

  void _selectLvl1(String id) {
    setState(() {
      _selectedLvl1 = id;
    });
  }

  void _addLvl0Item() {
    setState(() {
      final newId = 'Option$_lvl0Counter';
      _optionsLvl0.add(ExampleItem(id: newId, label: newId));
      _lvl0Counter++;
      // Keep current selection unchanged
    });
  }

  void _removeLvl0Item() {
    if (_optionsLvl0.length <= 1) return; // Keep at least one item

    setState(() {
      // Remove last item
      final removedItem = _optionsLvl0.removeLast();
      // If removed item was selected, select first item
      if (removedItem.id == _selectedLvl0 && _optionsLvl0.isNotEmpty) {
        _selectedLvl0 = _optionsLvl0.first.id;
      }
    });
  }

  void _addLvl1Item() {
    setState(() {
      final newId = 'Option$_lvl1Counter';
      _optionsLvl1.add(ExampleItem(id: newId, label: newId));
      _lvl1Counter++;
      // Keep current selection unchanged
    });
  }

  void _removeLvl1Item() {
    if (_optionsLvl1.length <= 1) return; // Keep at least one item

    setState(() {
      // Remove last item
      final removedItem = _optionsLvl1.removeLast();
      // If removed item was selected, select first item
      if (removedItem.id == _selectedLvl1 && _optionsLvl1.isNotEmpty) {
        _selectedLvl1 = _optionsLvl1.first.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabledLvl0 = _optionsLvl0.where((item) => item.enabled).toList();
    final enabledLvl1 = _optionsLvl1.where((item) => item.enabled).toList();

    return Scaffold(
      backgroundColor: _whiteColor,
      extendBody: true,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: _blackColor,
        elevation: 0,
        title: const Text(
          'Example Project',
          style: TextStyle(
            color: _whiteColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: _whiteColor),
            onPressed: () {
              // Example menu action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selected Level 0: $_selectedLvl0',
                      style: TextStyle(color: _blackColor, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selected Level 1: $_selectedLvl1',
                      style: TextStyle(color: _blackColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              color: _whiteColor,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Level 1 controls (first)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Level 1 (${_optionsLvl1.length} items):',
                        style: TextStyle(color: _blackColor, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, size: 20),
                        color:
                            _optionsLvl1.length <= 1 ? _greyColor : _redColor,
                        onPressed:
                            _optionsLvl1.length <= 1 ? null : _removeLvl1Item,
                        tooltip: 'Remove item from Level 1',
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 20),
                        color: _greenColor,
                        onPressed: _addLvl1Item,
                        tooltip: 'Add item to Level 1',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Level 0 controls (second)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Level 0 (${_optionsLvl0.length} items):',
                        style: TextStyle(color: _blackColor, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, size: 20),
                        color:
                            _optionsLvl0.length <= 1 ? _greyColor : _redColor,
                        onPressed:
                            _optionsLvl0.length <= 1 ? null : _removeLvl0Item,
                        tooltip: 'Remove item from Level 0',
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 20),
                        color: _greenColor,
                        onPressed: _addLvl0Item,
                        tooltip: 'Add item to Level 0',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Separator - full width
          SafeArea(
            top: false,
            bottom: false,
            child: Container(
              width: double.infinity,
              height: 1,
              color: _greyColor[300],
            ),
          ),
          // Scrolling tabs bar (Size, Position, etc.) - 2nd from bottom
          SafeArea(
            top: false,
            bottom: false,
            child: Container(
              width: double.infinity,
              color: _greyColor[100],
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: AnimatedOptionsBar<ExampleItem>(
                items: enabledLvl1,
                selectedId: _selectedLvl1,
                onItemSelected: _selectLvl1,
                getId: (item) => item.id,
                getLabel: (item) => item.label,
                config: _lvl1Config,
              ),
            ),
          ),
          // Separator - full width
          SafeArea(
            top: false,
            bottom: false,
            child: Container(
              width: double.infinity,
              height: 1,
              color: _greyColor[300],
            ),
          ),
          // Bottom action buttons - auto-detects tabbar vs scrollbar mode
          SafeArea(
            top: false,
            bottom: false,
            child: Container(
              width: double.infinity,
              color: _blackColor,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: AnimatedOptionsBar<ExampleItem>(
                items: enabledLvl0,
                selectedId: _selectedLvl0,
                onItemSelected: _selectLvl0,
                getId: (item) => item.id,
                getLabel: (item) => item.label,
                config: _lvl0Config,
              ),
            ),
          ),
          // Controls at the bottom - Level 1 first, then Level 0
        ],
      ),
    );
  }
}
