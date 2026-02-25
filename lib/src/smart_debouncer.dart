import 'dart:async';
import 'dart:ui' show VoidCallback;

/// A smart debouncer that dynamically adjusts its delay based on the user's
/// actual typing speed using the Exponential Moving Average (EMA) algorithm.
///
/// Unlike a traditional debouncer with a fixed delay, [SmartDebouncer]
/// continuously learns the user's typing rhythm and adapts accordingly:
/// - **Fast typers** get a shorter debounce delay for snappy responsiveness.
/// - **Slow typers** get a longer delay to avoid premature API calls.
///
/// ## Algorithm
///
/// 1. **EMA Update**: On each keystroke, the interval between keystrokes is
///    smoothed via EMA:
///    ```
///    currentEma = (interval * alpha) + (currentEma * (1 - alpha))
///    ```
///
/// 2. **Dynamic Delay**: The actual debounce delay is calculated as:
///    ```
///    dynamicDelay = currentEma * multiplier
///    ```
///
/// 3. **Safety Clamp**: The delay is clamped between [minDelay] and [maxDelay].
///
/// 4. **Pause Filtering**: If the interval exceeds [pauseThreshold], it's
///    treated as a natural pause (not typing), and the EMA is not updated.
///
/// ## Usage
///
/// ```dart
/// final debouncer = SmartDebouncer();
///
/// TextField(
///   onChanged: (value) {
///     debouncer.run(() {
///       // Call your search API here
///       searchApi(value);
///     });
///   },
/// );
///
/// // Don't forget to dispose!
/// @override
/// void dispose() {
///   debouncer.dispose();
///   super.dispose();
/// }
/// ```
class SmartDebouncer {
  /// Creates a [SmartDebouncer] with configurable parameters.
  ///
  /// - [minDelay]: Minimum debounce delay in milliseconds. Default: `150`.
  /// - [maxDelay]: Maximum debounce delay in milliseconds. Default: `800`.
  /// - [alpha]: EMA smoothing factor (0.0–1.0). Higher values make the EMA
  ///   react faster to recent input. Default: `0.3`.
  /// - [pauseThreshold]: If the interval between two keystrokes exceeds this
  ///   value (in ms), the interval is ignored for EMA calculation. Default: `1500`.
  /// - [multiplier]: Factor applied to the EMA to compute the actual delay.
  ///   Default: `1.5`.
  SmartDebouncer({
    this.minDelay = 150,
    this.maxDelay = 800,
    this.alpha = 0.3,
    this.pauseThreshold = 1500,
    this.multiplier = 1.5,
  }) : _currentEma = (minDelay + maxDelay) / 2;

  /// Minimum debounce delay in milliseconds.
  final int minDelay;

  /// Maximum debounce delay in milliseconds.
  final int maxDelay;

  /// EMA smoothing factor (0.0–1.0).
  ///
  /// Higher values give more weight to the most recent interval,
  /// making the debouncer react faster to changes in typing speed.
  final double alpha;

  /// Threshold in milliseconds to detect natural pauses.
  ///
  /// If the interval between two keystrokes exceeds this value,
  /// the interval is ignored and the EMA is not updated.
  final int pauseThreshold;

  /// Multiplier applied to the EMA to compute the debounce delay.
  ///
  /// A value > 1.0 ensures the delay is always slightly longer than
  /// the average typing interval, preventing premature triggers.
  final double multiplier;

  /// Internal timer used to schedule the debounced callback.
  Timer? _timer;

  /// Timestamp (in milliseconds since epoch) of the last [run] call.
  int _lastCallTime = 0;

  /// The current Exponential Moving Average of typing intervals.
  double _currentEma;

  /// Returns the current EMA value (for debugging/testing purposes).
  double get currentEma => _currentEma;

  /// Returns the current calculated dynamic delay in milliseconds,
  /// clamped between [minDelay] and [maxDelay].
  int get currentDelay {
    final dynamic = (_currentEma * multiplier).round();
    return dynamic.clamp(minDelay, maxDelay);
  }

  /// Executes [action] after a dynamically calculated debounce delay.
  ///
  /// Each call to [run] cancels any previously scheduled [action].
  /// The delay is computed using the EMA algorithm based on the interval
  /// between consecutive calls.
  ///
  /// If the interval between this call and the previous call exceeds
  /// [pauseThreshold], the EMA is not updated (pause filtering).
  void run(VoidCallback action) {
    // Cancel any existing timer
    _timer?.cancel();

    final now = DateTime.now().millisecondsSinceEpoch;

    // Update EMA if this is not the first call
    if (_lastCallTime > 0) {
      final interval = now - _lastCallTime;

      // Only update EMA if the interval is within the pause threshold
      // (i.e., the user is actively typing, not pausing)
      if (interval < pauseThreshold) {
        _currentEma = (interval * alpha) + (_currentEma * (1 - alpha));
      }
    }

    _lastCallTime = now;

    // Calculate dynamic delay and clamp it within bounds
    final dynamicDelay = (_currentEma * multiplier).round();
    final clampedDelay = dynamicDelay.clamp(minDelay, maxDelay);

    // Schedule the action with the calculated delay
    _timer = Timer(Duration(milliseconds: clampedDelay), action);
  }

  /// Cancels the current timer to prevent memory leaks.
  ///
  /// Always call this method when the debouncer is no longer needed,
  /// typically in the `dispose()` method of a `StatefulWidget`.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
