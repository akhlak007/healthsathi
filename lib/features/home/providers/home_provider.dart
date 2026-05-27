import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bangladeshHealthTips = [
  "Dengue Awareness: Always sleep under a mosquito net (Koshuri) and wear full-length garments. Clear stagnant water inside flower pots, coolers, or trays in your Dhaka layout every 3 days to eliminate Aedes mosquito breeding grounds.",
  "Summer Heat Protection: To fight dehydration during high humidity, drink safe pure tube-well water or Oral Rehydration Saline (ORS). Avoid drinking direct tap water in municipalities without boiling.",
  "Arsenic Precaution: Always trace whether the local ground tube-wells are painted green (arsenic-safe) or red (arsenic-compromised). Only cook and drink with green tube-well water.",
  "Monsoon Viral Safety: Boil water for at least 20 minutes to filter out cholera and typhoid markers during monsoon flash flood phases. Wash hands with soap before crushing street snacks.",
  "Hypertension Control: Lower your salt (pata-noon) intake. Excess raw salt during meals escalates blood pressure indicators in clinical cohorts.",
];

final randomHealthTipProvider = StateNotifierProvider<RandomHealthTipNotifier, String>((ref) {
  return RandomHealthTipNotifier();
});

class RandomHealthTipNotifier extends StateNotifier<String> {
  RandomHealthTipNotifier() : super(bangladeshHealthTips[0]);

  void fetchRandomTip() {
    final rand = Random();
    int index = rand.nextInt(bangladeshHealthTips.length);
    state = bangladeshHealthTips[index];
  }
}
