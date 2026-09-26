# trafficlight_flutter

App-specific implementation notes only.
Cross-app conventions are maintained separately and out of scope for this file.

## Ads
- The upgrade page promises buyers "all ads disappear" (`removeAllAds`). Premium users must never see any ad format: gate every ad, including any future rewarded or interstitial ad, behind `isPremium`.
