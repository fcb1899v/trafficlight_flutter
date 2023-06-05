import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'common_extension.dart';
import 'dart:io';

class AdBannerWidget extends HookWidget {
  const AdBannerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final adLoaded = useState(false);
    final adFailedLoading = useState(false);
    final bannerAd = useState<BannerAd?>(null);

    // バナー広告ID
    String bannerUnitId() =>
        (!kDebugMode && Platform.isIOS) ? dotenv.get("IOS_BANNER_UNIT_ID"):
        (!kDebugMode && Platform.isAndroid) ? dotenv.get("ANDROID_BANNER_UNIT_ID"):
        (Platform.isIOS) ? dotenv.get("IOS_BANNER_TEST_ID"):
        dotenv.get("ANDROID_BANNER_UNIT_ID");

    Future<void> loadAdBanner() async {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        final adBanner = BannerAd(
          adUnitId: bannerUnitId(),
          size: AdSize.largeBanner,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdLoaded: (Ad ad) {
              'Ad: $ad loaded.'.debugPrint();
              adLoaded.value = true;
            },
            onAdFailedToLoad: (ad, error) {
              ad.dispose();
              'Ad: $ad failed to load: $error'.debugPrint();
              adFailedLoading.value = true;
              Future.delayed(const Duration(seconds: 30), () {
                if (!adLoaded.value && !adFailedLoading.value) {
                  loadAdBanner();
                }
              });
            },
          ),
        );
        adBanner.load();
        bannerAd.value = adBanner;
      }
    }

    useEffect(() {
      loadAdBanner();
      "bannerAd: ${bannerAd.value}".debugPrint();
      return () {
        bannerAd.value?.dispose(); // アンマウント時に広告を破棄する
      };
    }, []);

    return SizedBox(
      width: context.admobWidth(),
      height: context.admobHeight(),
      child: (adLoaded.value) ? AdWidget(ad: bannerAd.value!): null,
    );
  }
}