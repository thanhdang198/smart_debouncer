# SmartDebouncer

A smart debouncer for Flutter that **dynamically adjusts** its delay based on the user's actual typing speed using the **Exponential Moving Average (EMA)** algorithm.

Unlike a traditional debouncer with a hardcoded delay, `SmartDebouncer` continuously learns the user's typing rhythm and adapts accordingly — fast typers get shorter delays, slow typers get longer ones.

## ✨ Features

- 🧠 **Adaptive delay** — Automatically adjusts based on typing speed via EMA
- ⏱️ **Pause detection** — Ignores natural pauses between words/thoughts
- 🔒 **Safety bounds** — Delay is always clamped between `minDelay` and `maxDelay`
- 🪶 **Zero dependencies** — Pure Dart, no external packages required
- 📱 **Flutter-ready** — Designed for `TextField` autocomplete/search use cases

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  smart_debouncer:
    path: ../smart_debouncer  # or from pub.dev
```

## 🚀 Quick Start

```dart
import 'package:smart_debouncer/smart_debouncer.dart';

final debouncer = SmartDebouncer();

TextField(
  onChanged: (value) {
    debouncer.run(() {
      searchApi(value);
    });
  },
);

// Don't forget to dispose!
@override
void dispose() {
  debouncer.dispose();
  super.dispose();
}
```

## ⚙️ Configuration

| Parameter        | Type     | Default | Description                                        |
|------------------|----------|---------|----------------------------------------------------|
| `minDelay`       | `int`    | `150`   | Minimum debounce delay (ms)                        |
| `maxDelay`       | `int`    | `800`   | Maximum debounce delay (ms)                        |
| `alpha`          | `double` | `0.3`   | EMA smoothing factor (0.0–1.0)                     |
| `pauseThreshold` | `int`    | `1500`  | Pause detection threshold (ms)                     |
| `multiplier`     | `double` | `1.5`   | Multiplier applied to EMA for final delay          |

```dart
final debouncer = SmartDebouncer(
  minDelay: 200,
  maxDelay: 1000,
  alpha: 0.4,
  pauseThreshold: 2000,
  multiplier: 1.8,
);
```

## 🧮 How It Works

1. **EMA Update**: On each keystroke, the interval is smoothed:
   ```
   currentEma = (interval × alpha) + (currentEma × (1 - alpha))
   ```

2. **Dynamic Delay**: The debounce delay is calculated as:
   ```
   dynamicDelay = currentEma × multiplier
   ```

3. **Safety Clamp**: The delay is clamped: `minDelay ≤ dynamicDelay ≤ maxDelay`

4. **Pause Filter**: Intervals > `pauseThreshold` are ignored (natural pauses)

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
