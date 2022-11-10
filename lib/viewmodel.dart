import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

final planProvider = StateNotifierProvider<PlanNotifier, PlanState>(
  (ref) => PlanNotifier()
);

@immutable
class PlanState {
  const PlanState({
    this.isCars = false,
    this.isNoAds = false,
    this.isPremium = false,
  });
  final bool isCars;
  final bool isNoAds;
  final bool isPremium;
}

class PlanNotifier extends StateNotifier<PlanState> {
  PlanNotifier(): super(const PlanState());

  setCurrentPlan(bool isCars, bool isNoAds, bool isPremium) {
    state = PlanState(
      isCars: isCars,
      isNoAds: isNoAds,
      isPremium: isPremium,
    );
  }
}

