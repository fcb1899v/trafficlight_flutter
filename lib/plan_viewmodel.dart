import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final planProvider = StateNotifierProvider<PlanNotifier, PlanState>(
  (ref) => PlanNotifier()
);

@immutable
class PlanState {
  const PlanState({
    this.isPremium = false,
  });
  final bool isPremium;
}

class PlanNotifier extends StateNotifier<PlanState> {
  PlanNotifier(): super(const PlanState());

  setCurrentPlan(bool isPremium) {
    state = PlanState(isPremium: isPremium,);
  }
}

