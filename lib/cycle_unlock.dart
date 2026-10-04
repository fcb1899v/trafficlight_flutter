import 'package:flutter/foundation.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'analytics.dart';
import 'extension.dart';
import 'plan_provider.dart';

/// Finished crosswalk cycles that unlock the car signal for free
const int cycleUnlockTarget = 999;

/// Cycle counts that send a cycle_milestone event
const List<int> cycleMilestones = [100, 300, 500];

/// Buckets the cycle count for analytics, so the parameter has a handful of values.
/// The edges line up with [cycleMilestones] and [cycleUnlockTarget].
String cycleBucket(int count) =>
  count <= 0 ? '0':
  count < 10 ? '1-9':
  count < 50 ? '10-49':
  count < 100 ? '50-99':
  count < 300 ? '100-299':
  count < 500 ? '300-499':
  count < cycleUnlockTarget ? '500-998':
  '999+';

/// Saved cycle progress
@immutable
class CycleState {
  /// Finished cycles, not counting the car-signal trial's own cycle
  final int count;
  /// True once [count] reached [cycleUnlockTarget]; never goes back to false
  final bool unlocked;

  const CycleState({this.count = 0, this.unlocked = false});
}

/// The cycle count and the free unlock, saved as key_cycleCount and key_cycleUnlocked
final cycleProvider = NotifierProvider<CycleNotifier, CycleState>(CycleNotifier.new);

/// The single entry to the car signal: bought, or unlocked by playing.
/// Ads and the settings card still follow [PlanState.isPremium] alone.
final carSignalProvider = Provider<bool>((ref) =>
  ref.watch(planProvider).isPremium || ref.watch(cycleProvider).unlocked);

class CycleNotifier extends Notifier<CycleState> {
  @override
  CycleState build() {
    final count = "cycleCount".getSettingsValueInt(0);
    return CycleState(count: count, unlocked: "cycleUnlocked".getSettingsValueBool(false) || count >= cycleUnlockTarget);
  }

  /// Counts one finished cycle and returns true when this cycle unlocked the car signal.
  /// A purchaser who reaches the target is marked unlocked without a cycle_unlock event.
  bool recordCycle() {
    final count = state.count + 1;
    final unlocksNow = !state.unlocked && count >= cycleUnlockTarget;
    state = CycleState(count: count, unlocked: state.unlocked || unlocksNow);
    Settings.setValue<int>('key_cycleCount', count);
    if (unlocksNow) {
      Settings.setValue<bool>('key_cycleUnlocked', true);
      if (!ref.read(planProvider).isPremium) SignalAnalytics.log('cycle_unlock');
    }
    if (cycleMilestones.contains(count)) SignalAnalytics.log('cycle_milestone', {'milestone': count});
    return unlocksNow;
  }
}
