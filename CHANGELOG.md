## 0.0.1

* Initial release.
* `SmartDebouncer` class with EMA-based dynamic delay calculation.
* Configurable parameters: `minDelay`, `maxDelay`, `alpha`, `pauseThreshold`, `multiplier`.
* Pause detection to filter out natural typing pauses.
* Safety clamping to keep delay within min/max bounds.
