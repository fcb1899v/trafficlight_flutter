import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'extension.dart';
import 'dart:io';
import 'constant.dart';

class AdBannerWidget extends HookWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {

    final adLoaded = useState(false);
    final adFailedLoading = useState(false);
    final bannerAd = useState<BannerAd?>(null);
    // Ref, not state: consent callbacks can resolve after dispose, and a disposed ValueNotifier asserts in debug.
    final isAdRequested = useRef(false);
    // final testIdentifiers = ['2793ca2a-5956-45a2-96c0-16fafddc1a15'];

    // Banner ad unit id
    String bannerUnitId() =>
        (!kDebugMode && Platform.isIOS) ? dotenv.get("IOS_BANNER_UNIT_ID"):
        (!kDebugMode && Platform.isAndroid) ? dotenv.get("ANDROID_BANNER_UNIT_ID"):
        (Platform.isIOS) ? iosBannerTestId:
        // Debug on Android takes the test unit here.
        // Falling through to the production unit puts development traffic on the live ad unit.
        androidBannerTestId;

    Future<void> loadAdBanner() async {
      // largeBanner asked for a fixed 320x100 inside a box sized by admobWidth and admobHeight.
      // Inline adaptive asks for that box's width and height.
      final cap = context.admobHeight().toInt();
      final size = AdSize.getInlineAdaptiveBannerAdSize(
          context.admobWidth().toInt(), cap);
      final adBanner = BannerAd(
        adUnitId: bannerUnitId(),
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) async {
            'Ad: $ad loaded.'.debugPrint();
            // Mount first; the await below only feeds a debug line
            adLoaded.value = true;
            if (kDebugMode) {
              // Requested and served together: neither alone tells the size asked for from the creative served.
              final served = await (ad as BannerAd).getPlatformAdSize();
              'AdSize: ${size.width} x cap $cap / served: ${served?.width} x ${served?.height}'.debugPrint();
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            'Ad: $ad failed to load: $error'.debugPrint();
            adFailedLoading.value = true;
            Future.delayed(const Duration(seconds: 30), () {
              if (!adLoaded.value && !adFailedLoading.value) loadAdBanner();
            });
          },
        ),
      );
      adBanner.load();
      bannerAd.value = adBanner;
    }

    // The single gate for the ad request.
    // canRequestAds is the SDK's own verdict (region, TCF, Additional Consent), so the app must not read ConsentStatus itself.
    Future<void> requestAdIfAllowed() async {
      if (isAdRequested.value) return;
      if (!await ConsentInformation.instance.canRequestAds()) return;
      // Both callers race across that await.
      // Claiming happens with no await in between, so no second BannerAd is created for the same slot.
      if (isAdRequested.value) return;
      isAdRequested.value = true;
      await loadAdBanner();
    }

    useEffect(() {
      ConsentInformation.instance.requestConsentInfoUpdate(ConsentRequestParameters(
        // consentDebugSettings: ConsentDebugSettings(
        //   debugGeography: DebugGeography.debugGeographyEea,
        //   testIdentifiers: testIdentifiers,
        // ),
      ), () async {
        // The SDK decides whether a form is required.
        // Do not load the ad from the form callback: it fires on close no matter what the user chose.
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            "formError: ${formError.errorCode}: ${formError.message}".debugPrint();
          }
          await requestAdIfAllowed();
        });
      }, (FormError error) async {
        // The update failed, but earlier consent can still make canRequestAds true, so do not stop here.
        "error: ${error.errorCode}: ${error.message}".debugPrint();
        await requestAdIfAllowed();
      });
      "bannerAd: ${bannerAd.value}".debugPrint();
      return () => bannerAd.value?.dispose();      // Dispose ad on unmount
    }, []);

    return SizedBox(
      width: context.admobWidth(),
      height: context.admobHeight(),
      child: (adLoaded.value) ? AdWidget(ad: bannerAd.value!): null,
    );
  }
}

