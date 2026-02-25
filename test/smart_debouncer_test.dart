import 'package:flutter_test/flutter_test.dart';
import 'package:smart_debouncer/smart_debouncer.dart';

void main() {
  group('SmartDebouncer', () {
    late SmartDebouncer debouncer;

    setUp(() {
      debouncer = SmartDebouncer();
    });

    tearDown(() {
      debouncer.dispose();
    });

    test('initializes with correct default values', () {
      expect(debouncer.minDelay, 150);
      expect(debouncer.maxDelay, 800);
      expect(debouncer.alpha, 0.3);
      expect(debouncer.pauseThreshold, 1500);
      expect(debouncer.multiplier, 1.5);
    });

    test('initial EMA is (minDelay + maxDelay) / 2', () {
      expect(debouncer.currentEma, (150 + 800) / 2);
      expect(debouncer.currentEma, 475.0);
    });

    test('initial currentDelay is clamped correctly', () {
      // Default EMA = 475.0, multiplier = 1.5
      // dynamicDelay = 475.0 * 1.5 = 712.5 → 713
      // Clamped to [150, 800] → 713
      expect(debouncer.currentDelay, 713);
    });

    test('accepts custom parameters', () {
      final custom = SmartDebouncer(
        minDelay: 200,
        maxDelay: 1000,
        alpha: 0.5,
        pauseThreshold: 2000,
        multiplier: 2.0,
      );

      expect(custom.minDelay, 200);
      expect(custom.maxDelay, 1000);
      expect(custom.alpha, 0.5);
      expect(custom.pauseThreshold, 2000);
      expect(custom.multiplier, 2.0);
      expect(custom.currentEma, 600.0); // (200 + 1000) / 2

      custom.dispose();
    });

    test('run() calls the callback after delay', () async {
      var called = false;

      debouncer.run(() {
        called = true;
      });

      // Should not be called immediately
      expect(called, false);

      // Wait for longer than maxDelay to ensure callback fires
      await Future.delayed(const Duration(milliseconds: 900));

      expect(called, true);
    });

    test('run() cancels previous timer when called again', () async {
      var firstCalled = false;
      var secondCalled = false;

      debouncer.run(() {
        firstCalled = true;
      });

      // Call again quickly — should cancel the first
      await Future.delayed(const Duration(milliseconds: 50));

      debouncer.run(() {
        secondCalled = true;
      });

      // Wait for the callback to fire
      await Future.delayed(const Duration(milliseconds: 900));

      expect(firstCalled, false);
      expect(secondCalled, true);
    });

    test('EMA updates correctly with rapid typing', () async {
      // Use a debouncer with known parameters for predictable math
      final d = SmartDebouncer(
        minDelay: 100,
        maxDelay: 500,
        alpha: 0.3,
        pauseThreshold: 1500,
        multiplier: 1.5,
      );

      // Initial EMA = (100 + 500) / 2 = 300.0
      expect(d.currentEma, 300.0);

      // Simulate rapid keystrokes (50ms apart)
      d.run(() {});
      await Future.delayed(const Duration(milliseconds: 50));
      d.run(() {});

      // After second call, EMA should have been updated:
      // interval ≈ 50ms, alpha = 0.3
      // newEma = (50 * 0.3) + (300 * 0.7) = 15 + 210 = 225.0
      // Allow some tolerance for timing
      expect(d.currentEma, lessThan(300.0));
      expect(d.currentEma, greaterThan(150.0));

      d.dispose();
    });

    test('EMA is NOT updated when interval exceeds pauseThreshold', () async {
      final d = SmartDebouncer(
        pauseThreshold: 100, // Very short threshold for testing
      );

      final initialEma = d.currentEma;

      d.run(() {});

      // Wait longer than pauseThreshold
      await Future.delayed(const Duration(milliseconds: 150));

      d.run(() {});

      // EMA should NOT have changed because interval > pauseThreshold
      expect(d.currentEma, initialEma);

      d.dispose();
    });

    test('currentDelay is clamped to minDelay', () {
      // Create debouncer where EMA * multiplier would be < minDelay
      final d = SmartDebouncer(
        minDelay: 300,
        maxDelay: 800,
        multiplier: 0.1, // Very low multiplier
      );

      // EMA = (300 + 800) / 2 = 550
      // dynamicDelay = 550 * 0.1 = 55 → clamped to 300
      expect(d.currentDelay, 300);

      d.dispose();
    });

    test('currentDelay is clamped to maxDelay', () {
      // Create debouncer where EMA * multiplier would be > maxDelay
      final d = SmartDebouncer(
        minDelay: 100,
        maxDelay: 400,
        multiplier: 3.0, // High multiplier
      );

      // EMA = (100 + 400) / 2 = 250
      // dynamicDelay = 250 * 3.0 = 750 → clamped to 400
      expect(d.currentDelay, 400);

      d.dispose();
    });

    test('dispose() cancels pending timer', () async {
      var called = false;

      debouncer.run(() {
        called = true;
      });

      debouncer.dispose();

      // Wait for the original delay
      await Future.delayed(const Duration(milliseconds: 900));

      expect(called, false);
    });

    test('dispose() can be called multiple times safely', () {
      debouncer.dispose();
      debouncer.dispose(); // Should not throw
    });

    test('multiple rapid calls converge EMA toward actual interval', () async {
      final d = SmartDebouncer(
        minDelay: 50,
        maxDelay: 1000,
        alpha: 0.5, // High alpha for faster convergence
        pauseThreshold: 1500,
        multiplier: 1.0,
      );

      // Initial EMA = (50 + 1000) / 2 = 525.0
      expect(d.currentEma, 525.0);

      // Simulate 5 rapid keystrokes ~30ms apart
      for (var i = 0; i < 5; i++) {
        d.run(() {});
        await Future.delayed(const Duration(milliseconds: 30));
      }

      // EMA should have converged significantly toward ~30ms
      // After multiple iterations, it should be much less than initial 525
      expect(d.currentEma, lessThan(300.0));

      d.dispose();
    });
  });
}
