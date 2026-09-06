-keep class com.google.android.gms.safetynet.** { *; }
-dontwarn com.google.android.gms.safetynet.**

# google_mobile_ads pulls play-services-ads-api, which pulls
# androidx.work:work-runtime:2.7.0, which pulls androidx.room:room-runtime:2.2.5.
# Room 2.2.5 ships this consumer rule, with no member spec:
#
#     -keep class * extends androidx.room.RoomDatabase
#
# Under R8 full mode (the default from AGP 9) that keeps WorkDatabase_Impl but
# removes its default constructor. Room instantiates the class through
# Class.newInstance(), which then throws InstantiationException, so the app dies
# before the first frame:
#
#     FATAL EXCEPTION: main
#     Unable to get provider androidx.startup.InitializationProvider:
#       Failed to create an instance of androidx.work.impl.WorkDatabase
#
# Confirmed on letselevatorneo 1.5.26+73: Play rejected the build and dexdump
# showed "Direct methods -" for androidx.work.impl.WorkDatabase_Impl.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
