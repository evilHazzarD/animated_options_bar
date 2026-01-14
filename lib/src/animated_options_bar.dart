import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A reusable animated options bar widget with smooth selection animations.
///
/// The widget automatically detects whether to use tabbar mode (full width
/// distribution) or scrollbar mode (horizontal scrolling) based on available
/// space. It provides smooth sliding and resizing animations when selection changes.
///
/// For String items, [getId] and [getLabel] are optional and will be auto-detected.
/// For custom types, these parameters are required.
///
/// Example with String items:
/// ```dart
/// AnimatedOptionsBar<String>(
///   items: ['Option 1', 'Option 2', 'Option 3'],
///   selectedId: 'Option 1',
///   onItemSelected: (id) => setState(() => selectedId = id),
///   config: OptionsBarConfig.lvl0,
/// )
/// ```
///
/// Example with custom items:
/// ```dart
/// class MyItem {
///   final String id;
///   final String label;
///   MyItem({required this.id, required this.label});
/// }
///
/// AnimatedOptionsBar<MyItem>(
///   items: [MyItem(id: '1', label: 'First'), ...],
///   selectedId: '1',
///   onItemSelected: (id) => setState(() => selectedId = id),
///   getId: (item) => item.id,
///   getLabel: (item) => item.label,
///   config: OptionsBarConfig(...),
/// )
/// ```
///
/// Configuration class for styling the animated options bar.
///
/// Provides preset configurations and allows custom styling for the
/// animated options bar widget.
class OptionsBarConfig {
  /// Padding around text inside each item's selection container
  ///
  /// Can use [EdgeInsets.symmetric], [EdgeInsets.all], [EdgeInsets.fromLTRB], etc.
  /// Example: `EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0)`
  EdgeInsets textPadding;

  /// Border radius for the selection container
  double borderRadius;

  /// Spacing between items
  double itemSpacing;

  /// Edge padding for scrollable mode (left and right sides)
  double scrollEdgePadding;

  /// Text color when item is active/selected
  Color activeTextColor;

  /// Text color when item is inactive
  Color inactiveTextColor;

  /// Background alpha of the scroll arrow buttons
  double arrowBackgroundAlpha;

  /// Text style for items (optional, defaults to fontSize 14 if not provided)
  TextStyle? textStyle;

  /// Color of the selection container
  Color selectionColor;

  /// Background color of the options bar
  ///
  /// If null, the background is transparent.
  Color? backgroundColor;

  /// Duration of the slide/resize animation
  Duration animationDuration;

  /// Distance of scroll arrows from parent container edges (in pixels)
  ///
  /// This controls how far the < and > arrows are positioned from the
  /// edges of the parent container. Default is 4.0 pixels.
  double arrowInset;

  /// Size of the scroll arrow buttons (in pixels)
  ///
  /// This controls the width and height of the circular arrow buttons.
  /// Default is 20.0 pixels.
  double arrowButtonSize;

  /// Whether to center the options items within the bar
  ///
  /// When true, items will be centered using MainAxisAlignment.center.
  /// When false (default), items will be aligned to the start.
  /// This is particularly useful in tabbar mode when items don't fill the entire width.
  bool centerOptions;

  OptionsBarConfig({
    required this.textPadding,
    required this.borderRadius,
    required this.itemSpacing,
    required this.scrollEdgePadding,
    required this.activeTextColor,
    required this.inactiveTextColor,
    required this.selectionColor,
    this.backgroundColor,
    this.animationDuration = const Duration(milliseconds: 300),
    this.textStyle,
    this.arrowInset = 4.0,
    this.arrowButtonSize = 20.0,
    this.arrowBackgroundAlpha = 0.1,
    this.centerOptions = false,
  });
}

class AnimatedOptionsBar<T> extends StatefulWidget {
  /// List of items to display
  final List<T> items;

  /// Currently selected item ID
  final String selectedId;

  /// Callback when an item is selected
  final void Function(String) onItemSelected;

  /// Function to extract ID from an item
  ///
  /// Optional for String items (defaults to identity function).
  /// Required for other types.
  final String Function(T)? getId;

  /// Function to extract label from an item
  ///
  /// Optional for String items (defaults to identity function).
  /// Required for other types.
  final String Function(T)? getLabel;

  /// Configuration for styling
  final OptionsBarConfig config;

  const AnimatedOptionsBar({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onItemSelected,
    this.getId,
    this.getLabel,
    required this.config,
  });

  @override
  State<AnimatedOptionsBar<T>> createState() => _AnimatedOptionsBarState<T>();
}

class _AnimatedOptionsBarState<T> extends State<AnimatedOptionsBar<T>> {
  // Constants for fallback and minimum values
  static const double _fallbackHeight = 50.0;
  static const double _minimumContainerHeight = 32.0;

  String? _previousSelectedId;
  bool _isFirstBuild = true;
  bool _shouldScrollToSelected = false;
  Map<int, Size>? _cachedItemSizes;
  // Cache for item IDs and labels to avoid repeated function calls
  Map<T, String>? _itemIdCache;
  Map<T, String>? _itemLabelCache;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedOptionsBar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update previous ID when selection changes
    if (oldWidget.selectedId != widget.selectedId) {
      _previousSelectedId = oldWidget.selectedId;
      _isFirstBuild = false;
      _shouldScrollToSelected =
          true; // Mark that we should scroll on next build
    } else {
      _shouldScrollToSelected = false; // Selection didn't change, don't scroll
    }

    // Granular cache invalidation - only invalidate when properties that affect
    // text measurement change
    final itemsChanged = oldWidget.items.length != widget.items.length ||
        !identical(oldWidget.items, widget.items);
    final textMeasurementChanged =
        oldWidget.config.textStyle != widget.config.textStyle ||
            oldWidget.config.textPadding != widget.config.textPadding;
    final getIdChanged = oldWidget.getId != widget.getId;
    final getLabelChanged = oldWidget.getLabel != widget.getLabel;

    if (itemsChanged ||
        textMeasurementChanged ||
        getIdChanged ||
        getLabelChanged) {
      _cachedItemSizes = null;
      _itemIdCache = null;
      _itemLabelCache = null;
    }
  }

  /// Scroll to make the selected item fully visible
  void _scrollToSelectedItem({
    required double currentPosition,
    required double currentWidth,
    required double viewportWidth,
  }) {
    if (_scrollController == null || !_scrollController!.hasClients) {
      return;
    }

    final scrollOffset = _scrollController!.offset;
    final itemLeft = currentPosition;
    final itemRight = itemLeft + currentWidth;
    final viewportLeft = scrollOffset;
    final viewportRight = scrollOffset + viewportWidth;

    double targetOffset = scrollOffset;

    // If item is partially or fully outside viewport, scroll to make it fully visible
    if (itemLeft < viewportLeft) {
      // Item is to the left of viewport, scroll left
      targetOffset = itemLeft;
    } else if (itemRight > viewportRight) {
      // Item is to the right of viewport, scroll right
      targetOffset = itemRight - viewportWidth;
    }

    // Only scroll if we need to
    if ((targetOffset - scrollOffset).abs() > 0.1) {
      _scrollController!.animateTo(
        targetOffset.clamp(0.0, _scrollController!.position.maxScrollExtent),
        duration: widget.config.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  String _getId(T item) {
    // Use cache to avoid repeated function calls
    _itemIdCache ??= <T, String>{};
    return _itemIdCache!.putIfAbsent(item, () {
      if (widget.getId != null) {
        return widget.getId!(item);
      }
      // Auto-detect for String
      if (item is String) {
        return item;
      }
      throw StateError('getId must be provided for non-String types');
    });
  }

  String _getLabel(T item) {
    // Use cache to avoid repeated function calls
    _itemLabelCache ??= <T, String>{};
    return _itemLabelCache!.putIfAbsent(item, () {
      if (widget.getLabel != null) {
        return widget.getLabel!(item);
      }
      // Auto-detect for String
      if (item is String) {
        return item;
      }
      throw StateError('getLabel must be provided for non-String types');
    });
  }

  /// Measure and cache item sizes
  Map<int, Size> _measureItemSizes(BuildContext context) {
    if (_cachedItemSizes != null) {
      return _cachedItemSizes!;
    }

    final textStyle = widget.config.textStyle ??
        TextStyle(fontSize: MediaQuery.textScalerOf(context).scale(14));

    final textDirection = Directionality.of(context);

    final sizes = <int, Size>{};
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final textPainter = TextPainter(
        text: TextSpan(text: _getLabel(item), style: textStyle),
        textDirection: textDirection,
      )..layout();
      sizes[i] = Size(
        textPainter.size.width + widget.config.textPadding.horizontal,
        textPainter.size.height + widget.config.textPadding.vertical,
      );
    }

    _cachedItemSizes = sizes;
    return sizes;
  }

  /// Calculate total width needed for all items in scrollbar mode
  double _calculateTotalWidth(Map<int, Size> itemSizes) {
    if (itemSizes.isEmpty) return 0.0;
    // Left padding + all items + spacing + right padding
    double total = widget.config.scrollEdgePadding; // Left padding
    for (int i = 0; i < widget.items.length; i++) {
      total += itemSizes[i]!.width;
      if (i < widget.items.length - 1) {
        total += widget.config.itemSpacing;
      }
    }
    total += widget.config.scrollEdgePadding; // Right padding
    return total;
  }

  @override
  Widget build(BuildContext context) {
    // Validate inputs
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find current index
    final currentIndex = widget.items.indexWhere(
      (item) => _getId(item) == widget.selectedId,
    );

    if (currentIndex < 0) {
      // Invalid selectedId - provide better error handling
      assert(() {
        final availableIds =
            widget.items.map((item) => _getId(item)).join(", ");
        debugPrint(
          'AnimatedOptionsBar: selectedId "${widget.selectedId}" not found in items. '
          'Available IDs: $availableIds',
        );
        return true;
      }());
      // In release mode, fallback to first item if available
      if (widget.items.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onItemSelected(_getId(widget.items[0]));
          }
        });
      }
      return const SizedBox.shrink();
    }

    // Measure item sizes
    final itemSizes = _measureItemSizes(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Auto-detect layout mode
        // Use scrollbar mode if items overflow (need scrolling)
        final totalWidth = _calculateTotalWidth(itemSizes);
        // Switch to scrollbar mode if total width exceeds available width
        final isTabBar = totalWidth <= constraints.maxWidth;

        // Find previous index
        final previousIndex = _previousSelectedId != null &&
                _previousSelectedId != widget.selectedId &&
                widget.items.any((item) => _getId(item) == _previousSelectedId)
            ? widget.items.indexWhere(
                (item) => _getId(item) == _previousSelectedId,
              )
            : -1;

        // Calculate positions and widths
        double currentPosition, previousPosition;
        double currentWidth, previousWidth;
        double itemWidth = 0;

        if (isTabBar && !widget.config.centerOptions) {
          // Traditional tabbar mode: items expand to fill width
          final availableWidth =
              constraints.maxWidth - (widget.config.scrollEdgePadding * 2);
          itemWidth = availableWidth / widget.items.length;

          double getTabPosition(int index) {
            final slotLeft =
                widget.config.scrollEdgePadding + (index * itemWidth);
            final indicatorWidth = itemSizes[index]!.width;
            return slotLeft + (itemWidth - indicatorWidth) / 2;
          }

          currentPosition = getTabPosition(currentIndex);
          previousPosition = previousIndex >= 0
              ? getTabPosition(previousIndex)
              : currentPosition;
          currentWidth = itemSizes[currentIndex]!.width;
          previousWidth = previousIndex >= 0
              ? itemSizes[previousIndex]!.width
              : currentWidth;
        } else {
          // Scrollbar mode OR tabbar mode with centering: items use natural width
          double calculatePosition(int index) {
            // Start from 0 since we removed edge padding (handled by arrows now)
            double pos = 0.0;
            for (int i = 0; i < index; i++) {
              pos += itemSizes[i]!.width + widget.config.itemSpacing;
            }
            return pos;
          }

          // Calculate base position (cumulative width)
          final baseCurrentPosition = calculatePosition(currentIndex);
          final basePreviousPosition = previousIndex >= 0
              ? calculatePosition(previousIndex)
              : baseCurrentPosition;

          // If in tabbar mode with centering, add offset for centered group
          if (isTabBar && widget.config.centerOptions) {
            // Calculate total width of all items with spacing
            final totalContentWidth = _calculateTotalWidth(itemSizes) -
                (widget.config.scrollEdgePadding * 2);
            final availableWidth = constraints.maxWidth;
            final centerOffset = (availableWidth - totalContentWidth) / 2;

            currentPosition = baseCurrentPosition + centerOffset;
            previousPosition = basePreviousPosition + centerOffset;
          } else {
            // Scrollbar mode: no offset needed
            currentPosition = baseCurrentPosition;
            previousPosition = basePreviousPosition;
          }

          currentWidth = itemSizes[currentIndex]!.width;
          previousWidth = previousIndex >= 0
              ? itemSizes[previousIndex]!.width
              : currentWidth;
        }

        // Determine if we should animate
        final shouldAnimate = !_isFirstBuild &&
            previousIndex >= 0 &&
            previousIndex != currentIndex;

        // Build content
        final content = _buildContent(
          context: context,
          itemSizes: itemSizes,
          currentIndex: currentIndex,
          isTabBar: isTabBar,
          itemWidth: itemWidth,
          currentPosition: currentPosition,
          previousPosition: previousPosition,
          currentWidth: currentWidth,
          previousWidth: previousWidth,
          shouldAnimate: shouldAnimate,
        );

        // Wrap content with background color if provided
        Widget wrappedContent = content;
        if (widget.config.backgroundColor != null) {
          wrappedContent = Container(
            color: widget.config.backgroundColor,
            child: content,
          );
        }

        if (isTabBar) {
          return wrappedContent;
        } else {
          // Scroll to selected item only when selection changes
          if (_shouldScrollToSelected) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _scrollController?.hasClients == true) {
                // Calculate actual viewport width (excluding arrow buttons)
                final arrowButtonWidth = widget.config.arrowInset * 2 +
                    widget.config.arrowButtonSize; // Total width per arrow
                final actualViewportWidth =
                    constraints.maxWidth - (arrowButtonWidth * 2);

                _scrollToSelectedItem(
                  currentPosition: currentPosition,
                  currentWidth: currentWidth,
                  viewportWidth: actualViewportWidth,
                );
                // Reset flag after scrolling
                _shouldScrollToSelected = false;
              }
            });
          }

          // Wrap content with explicit width so SingleChildScrollView knows the scrollable extent
          // Since we removed padding from _buildContent in scrollbar mode, we subtract it here
          final layoutWidth =
              totalWidth - (widget.config.scrollEdgePadding * 2);

          final scrollableContent = SizedBox(
            width: layoutWidth,
            child: wrappedContent,
          );

          final scrollView = ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              scrollbars: false,
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: scrollableContent,
            ),
          );

          // Show scroll arrows when scrolling is available
          // Use Row layout: [Left Arrow] [Scrollable Content] [Right Arrow]
          // Ensure height honors the minimum container height if items are smaller
          final contentHeight =
              itemSizes.isNotEmpty ? itemSizes[0]!.height : _fallbackHeight;
          final containerHeight = contentHeight < _minimumContainerHeight
              ? _minimumContainerHeight
              : contentHeight;

          return SizedBox(
            height: containerHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left arrow (fixed width, positioned at screen edge)
                _ScrollArrowButton(
                  controller: _scrollController!,
                  direction: _ScrollDirection.left,
                  arrowColor: widget.config.inactiveTextColor,
                  arrowBackgroundAlpha: widget.config.arrowBackgroundAlpha,
                  inset: widget.config.arrowInset,
                  buttonSize: widget.config.arrowButtonSize,
                ),
                // Scrollable content (takes remaining space)
                Expanded(
                  child: Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent &&
                          _scrollController!.hasClients) {
                        final newOffset =
                            _scrollController!.offset + event.scrollDelta.dy;
                        _scrollController!.jumpTo(
                          newOffset.clamp(
                            0.0,
                            _scrollController!.position.maxScrollExtent,
                          ),
                        );
                      }
                    },
                    child: scrollView,
                  ),
                ),
                // Right arrow (fixed width, positioned at screen edge)
                _ScrollArrowButton(
                  controller: _scrollController!,
                  direction: _ScrollDirection.right,
                  arrowColor: widget.config.inactiveTextColor,
                  arrowBackgroundAlpha: widget.config.arrowBackgroundAlpha,
                  inset: widget.config.arrowInset,
                  buttonSize: widget.config.arrowButtonSize,
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required Map<int, Size> itemSizes,
    required int currentIndex,
    required bool isTabBar,
    required double itemWidth,
    required double currentPosition,
    required double previousPosition,
    required double currentWidth,
    required double previousWidth,
    required bool shouldAnimate,
  }) {
    final textStyle = widget.config.textStyle ??
        TextStyle(fontSize: MediaQuery.textScalerOf(context).scale(14));

    final stack = Stack(
      clipBehavior: isTabBar ? Clip.hardEdge : Clip.none,
      children: [
        // Animated selection container
        if (currentIndex >= 0)
          TweenAnimationBuilder<double>(
            key: ValueKey(
              '${isTabBar ? 'tabbar' : 'scrollbar'}-${widget.selectedId}',
            ),
            duration:
                shouldAnimate ? widget.config.animationDuration : Duration.zero,
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeInOut,
            builder: (context, t, child) {
              final animatedLeft = shouldAnimate
                  ? previousPosition + (currentPosition - previousPosition) * t
                  : currentPosition;
              final animatedWidth = shouldAnimate
                  ? previousWidth + (currentWidth - previousWidth) * t
                  : currentWidth;

              return Positioned(
                left: animatedLeft,
                child: RepaintBoundary(
                  child: Container(
                    width: animatedWidth,
                    height: itemSizes[currentIndex]!.height,
                    padding: widget.config.textPadding,
                    decoration: BoxDecoration(
                      color: widget.config.selectionColor,
                      borderRadius: BorderRadius.circular(
                        widget.config.borderRadius,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        // Text row with items
        Padding(
          padding: EdgeInsets.only(
            left: isTabBar && !widget.config.centerOptions
                ? widget.config.scrollEdgePadding
                : 0,
            right: isTabBar && !widget.config.centerOptions
                ? widget.config.scrollEdgePadding
                : 0,
          ),
          child: Row(
            mainAxisSize: isTabBar ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: widget.config.centerOptions
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              // Cache ID and label lookups
              final itemId = _getId(item);
              final itemLabel = _getLabel(item);
              final isActive = itemId == widget.selectedId;

              Widget itemWidget = Semantics(
                label: itemLabel,
                selected: isActive,
                button: true,
                child: GestureDetector(
                  onTap: () => widget.onItemSelected(itemId),
                  child: SizedBox(
                    width: isTabBar && !widget.config.centerOptions
                        ? null
                        : itemSizes[index]!.width,
                    height: itemSizes[index]!.height,
                    child: Center(
                      child: _AnimatedText(
                        text: itemLabel,
                        isActive: isActive,
                        config: widget.config,
                        textStyle: textStyle,
                        animationDuration: widget.config.animationDuration,
                        skipAnimation: _isFirstBuild,
                      ),
                    ),
                  ),
                ),
              );

              if (isTabBar && !widget.config.centerOptions) {
                // In tabbar mode without centering, expand items to fill width
                return Expanded(child: itemWidget);
              } else {
                // In scrollbar mode OR tabbar mode with centering, use natural width with spacing
                final isLast = index == widget.items.length - 1;
                return Padding(
                  padding: EdgeInsets.only(
                    right: isLast ? 0 : widget.config.itemSpacing,
                  ),
                  key: ValueKey('item-$index'),
                  child: itemWidget,
                );
              }
            }).toList(),
          ),
        ),
      ],
    );

    return SizedBox(
      height: itemSizes.isNotEmpty ? itemSizes[0]!.height : _fallbackHeight,
      child: stack,
    );
  }
}

/// Direction for scroll arrow buttons
enum _ScrollDirection { left, right }

/// Individual scroll arrow button widget
class _ScrollArrowButton extends StatefulWidget {
  final ScrollController controller;
  final _ScrollDirection direction;
  final Color arrowColor;
  final double arrowBackgroundAlpha;
  final double inset;
  final double buttonSize;

  const _ScrollArrowButton({
    required this.controller,
    required this.direction,
    required this.arrowColor,
    required this.inset,
    required this.buttonSize,
    required this.arrowBackgroundAlpha,
  });

  @override
  State<_ScrollArrowButton> createState() => _ScrollArrowButtonState();
}

class _ScrollArrowButtonState extends State<_ScrollArrowButton> {
  bool _canScroll = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateScrollState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollState());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateScrollState);
    super.dispose();
  }

  void _updateScrollState() {
    if (!widget.controller.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateScrollState();
      });
      return;
    }

    try {
      final position = widget.controller.position;
      final canScroll = widget.direction == _ScrollDirection.left
          ? position.pixels > 1.0
          : position.pixels < position.maxScrollExtent - 1.0;

      if (mounted && _canScroll != canScroll) {
        setState(() => _canScroll = canScroll);
      }
    } catch (e) {
      // Position not available yet - this is expected during initialization
      assert(() {
        debugPrint('AnimatedOptionsBar: Scroll position not available yet: $e');
        return true;
      }());
    }
  }

  void _scroll() {
    if (!widget.controller.hasClients) return;

    final position = widget.controller.position;
    final viewportWidth = position.viewportDimension;
    final currentOffset = position.pixels;

    final targetOffset = widget.direction == _ScrollDirection.left
        ? (currentOffset - viewportWidth).clamp(0.0, position.maxScrollExtent)
        : (currentOffset + viewportWidth).clamp(0.0, position.maxScrollExtent);

    widget.controller.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Icon size scales with button size (80% of button size)
  static const double _iconSizeRatio = 0.8;
  static const double _arrowPadding = 2.0;

  @override
  Widget build(BuildContext context) {
    final arrowBorderRadius = widget.buttonSize / 2;
    final arrowIconSize = widget.buttonSize * _iconSizeRatio;

    if (!_canScroll) {
      return SizedBox(width: widget.inset * 2 + widget.buttonSize);
    }

    return SizedBox(
      width: widget.inset * 2 + widget.buttonSize,
      child: Align(
        alignment: widget.direction == _ScrollDirection.left
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(
            left: widget.direction == _ScrollDirection.left ? widget.inset : 0,
            right:
                widget.direction == _ScrollDirection.right ? widget.inset : 0,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _scroll,
              child: Container(
                width: widget.buttonSize,
                height: widget.buttonSize,
                padding: EdgeInsets.all(_arrowPadding),
                decoration: BoxDecoration(
                  color: widget.arrowColor.withAlpha(
                    (widget.arrowBackgroundAlpha * 255).toInt(),
                  ), // ~10% opacity
                  borderRadius: BorderRadius.circular(arrowBorderRadius),
                ),
                child: Icon(
                  widget.direction == _ScrollDirection.left
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: widget.arrowColor,
                  size: arrowIconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget for animating text color changes
class _AnimatedText extends StatelessWidget {
  final String text;
  final bool isActive;
  final OptionsBarConfig config;
  final TextStyle textStyle;
  final Duration animationDuration;
  final bool skipAnimation;

  // Delay before text color changes (as fraction of animation duration)
  static const double _textColorChangeDelay = 0.85;

  const _AnimatedText({
    required this.text,
    required this.isActive,
    required this.config,
    required this.textStyle,
    required this.animationDuration,
    required this.skipAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: skipAnimation
          ? Duration.zero
          : Duration(milliseconds: animationDuration.inMilliseconds + 50),
      tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
      curve: Curves.easeInOut,
      builder: (context, textValue, child) {
        final shouldChangeColor =
            skipAnimation ? isActive : textValue >= _textColorChangeDelay;
        final textColor = shouldChangeColor
            ? (isActive ? config.activeTextColor : config.inactiveTextColor)
            : config.inactiveTextColor;

        return Text(text, style: textStyle.copyWith(color: textColor));
      },
    );
  }
}
