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
    // Ref, not state: the consent callbacks resolve after this widget can be
    // gone, and writing to a disposed ValueNotifier asserts in debug
    final isAdRequested = useRef(false);
    // final testIdentifiers = ['2793ca2a-5956-45a2-96c0-16fafddc1a15'];

    // バナー広告ID
    String bannerUnitId() =>
        (!kDebugMode && Platform.isIOS) ? dotenv.get("IOS_BANNER_UNIT_ID"):
        (!kDebugMode && Platform.isAndroid) ? dotenv.get("ANDROID_BANNER_UNIT_ID"):
        (Platform.isIOS) ? iosBannerTestId:
        // Debug on Android used to fall through to the production unit, so
        // development traffic landed on the live ad unit
        androidBannerTestId;

    Future<void> loadAdBanner() async {
      // largeBanner asked for a fixed 320x100 inside a box sized by admobWidth
      // and admobHeight. Inline adaptive asks for that box's width and height
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
              // Requested and served together: neither alone separates the size
              // asked for from the creative Google had to hand
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

    // The single gate for the ad request. canRequestAds is the SDK's own
    // verdict: it already weighs the region, the TCF consent string and
    // Additional Consent, so the app must not read ConsentStatus and decide for
    // itself. A false answer also covers "the SDK could not tell", and letting
    // that through is exactly what serving without consent looks like in the EEA
    Future<void> requestAdIfAllowed() async {
      if (isAdRequested.value) return;
      if (!await ConsentInformation.instance.canRequestAds()) return;
      // Both callers below race across that await. Claiming the request happens
      // with no await in between, so whoever resumes second always sees the
      // flag and no second BannerAd is created for the same slot
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
        // The SDK decides whether a form is required, loads it and presents it.
        // The old flow called loadAdBanner from the consent form callback, which
        // fires when the form closes no matter what the user chose, so a user
        // who declined still got an ad request
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            "formError: ${formError.errorCode}: ${formError.message}".debugPrint();
          }
          await requestAdIfAllowed();
        });
      }, (FormError error) async {
        // The update failed, but consent given in an earlier session still
        // stands and canRequestAds can still say yes. Stopping here would throw
        // away impressions the SDK would have allowed
        "error: ${error.errorCode}: ${error.message}".debugPrint();
        await requestAdIfAllowed();
      });
      "bannerAd: ${bannerAd.value}".debugPrint();
      return () => bannerAd.value?.dispose();      // unmount時に広告を破棄する
    }, []);

    return SizedBox(
      width: context.admobWidth(),
      height: context.admobHeight(),
      child: (adLoaded.value) ? AdWidget(ad: bannerAd.value!): null,
    );
  }
}

