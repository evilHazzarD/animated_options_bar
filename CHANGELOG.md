# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-01-14

### Added
- `centerOptions` parameter to `OptionsBarConfig` for centering option items within the bar
  - When `true`, items are tightly grouped in the center with natural widths
  - When `false` (default), maintains original behavior (expanded in tabbar mode, left-aligned in scrollbar mode)
  - Particularly useful in tabbar mode when items don't fill the entire width

### Changed
- Updated minimum SDK constraint from `^3.9.2` to `>=2.17.0` for broader compatibility
- Updated example SDK constraint to match package requirements

### Fixed
- Selection indicator positioning when `centerOptions` is enabled
- Text alignment with selection indicator in centered mode
- Item width calculation for proper alignment in centered tabbar mode

## [0.1.0] - 2025-12-05

### Added
- Initial release of `animated_options_bar` package
- `AnimatedOptionsBar` widget with smooth sliding and resizing animations
- Automatic layout mode detection (tabbar vs scrollbar)
- `OptionsBarConfig` for customizable styling
- Support for String items with auto-detection (getId/getLabel optional)
- Support for custom item types with getId/getLabel functions
- Built-in accessibility support with Semantics widgets
- Comprehensive error handling and edge case management
- Cached text measurements for performance optimization
- Comprehensive test suite

### Features
- Smooth selection animations with configurable duration
- Automatic switching between tabbar mode (full width) and scrollbar mode (horizontal scrolling)
- Configurable colors, padding, spacing, and border radius
- Optional scroll arrows for scrollbar mode
- Optional background color and custom text styles

