## 0.0.2

* **Fixed**: Renamed internal variable `dynamic` to `rawDelay` to avoid Dart keyword shadowing.
* **Added**: Constructor assertions for parameter validation (`minDelay <= maxDelay`, `alpha` in range, etc.).
* **Added**: Use-after-dispose guard — calling `run()` after `dispose()` now throws an assertion error.
* **Added**: `reset()` method to reset EMA to initial value (useful when search context changes).
* **Improved**: Replaced `dart:ui` import with `void Function()` for better portability.

## 0.0.1

* Initial release.
* `SmartDebouncer` class with EMA-based dynamic delay calculation.
* Configurable parameters: `minDelay`, `maxDelay`, `alpha`, `pauseThreshold`, `multiplier`.
* Pause detection to filter out natural typing pauses.
* Safety clamping to keep delay within min/max bounds.
