# Hasana App Store Readiness

Date: 2026-05-26
Status: In progress

## Current Build

- Scheme: Hasana
- Bundle ID: `sa.Alrashed.Azzam.Hasana`
- Display name: `حسنة`
- Category: Education
- Version: `0.0.1`
- Build: `2`
- Minimum iOS: `18.6`
- Built with: iOS SDK `26.5`
- App Store icon: present at `Hasana/Hasana/Resources/Assets.xcassets/AppIcon.appiconset/1024.png`

## Completed In Repo

- Debug and Release builds pass for generic iOS with code signing disabled.
- Privacy manifest added for app-only `UserDefaults` usage.
- No tracking domains declared.
- No collected data types declared for the current local-only app (all calculations, user inputs, and logs remain local).
- Location permission copy configured in Info.plist for Qibla calculation and local prayer times.
- Notification permission configured in Info.plist for scheduling daily Athan alerts.
- Payment/support screen remains disabled and clearly states no payment is collected.
- Arabic and English app copy exist across all utility screens and dashboards in code.

## App Store Connect Metadata Draft

### App Name

Hasana - حسنة

### Subtitle

A calm garden for daily worship.

### Promotional Text

Tend a private lifelong garden through prayer, Quran, dhikr, and gentle daily return.

### Description

Hasana is a calm daily companion for Muslim professionals who want to return to meaningful worship with privacy and beauty.

Build a lifelong garden by tending small daily practices such as prayer, Quran, adhkar, and Witr. Missing a day does not erase your growth; Hasana is designed around gentle continuity rather than pressure, public scores, or comparison.

The current MVP stores your garden locally on your device, supports Arabic and English, and includes appearance, theme, and app icon settings.

### Keywords

Islam,Muslim,prayer,Quran,dhikr,worship,habits,spirituality,Arabic,reflection

### Review Notes

Hasana currently stores all worship progress locally on device using UserDefaults. The support/donation screen is a disabled placeholder and does not process payments or collect payment information.

## Privacy Answers

- Data collection: none for the current MVP, because worship progress and settings remain local on device.
- Tracking: no.
- Third-party SDKs: none currently present in the Xcode project.
- Sensitive information: worship activity may be sensitive, but it is not transmitted off device in the current MVP.
- Privacy policy URL: still required in App Store Connect before submission.

## Required Before Submission

- Create and publish a privacy policy URL that matches the local-only data model.
- Confirm the public launch version with App Store Connect, likely `1.0.0` instead of the current `0.0.1`.
- Capture one to ten App Store screenshots for required iPhone and iPad sizes (include garden, prayer times timer, Quran reflection view, Tasbih clicker, and Islamic hub compass).
- Complete App Store age rating questionnaire.
- Complete export compliance answers.
- Run manual QA on at least one small iPhone, one large iPhone, and one iPad in Arabic and English.
- Review worship labels and religious copy before release.
- Ensure proper user prompt strings are defined for Location and Notification permissions.

## Manual QA Checklist

- First launch shows splash, then onboarding.
- Onboarding language switch updates copy and layout direction.
- Skip and start both enter the garden and do not show onboarding again.
- Garden pan and zoom work and persist after relaunch.
- Tapping each practice opens the log sheet focused on that practice.
- Tending and untending each practice persists after relaunch.
- Reset view recenters and persists.
- Command palette opens settings, payments, and all sub-feature dashboards.
- Settings language, appearance, theme, and app icon choices persist.
- Support screen cannot initiate a real payment.
- Dynamic Type does not clip primary actions on common device sizes.
- VoiceOver can identify each garden practice by name, status, growth stage, and tended/untended/dormant state.
- VoiceOver hints explain how to open logging, tend, untend, change logging day, and use onboarding/settings controls.
- Garden and logging surfaces communicate tended, untended, and dormant states with text or symbols in addition to color.
- Calendar day chips, garden practice targets, floating action button, onboarding navigation, and settings choice controls have comfortable tap targets.
- Arabic and English onboarding, logging, and settings text do not clip on iPhone SE, standard iPhone, and large iPhone layouts at default and large Dynamic Type.
- Settings theme and app icon grids collapse or wrap without truncating Arabic labels on narrow iPhone widths.
- Location permission prompts when viewing Qibla compass or opening Prayer Times.
- Notification permission prompts when enabling Athan alarms.
- Prayer Times calculation updates correctly when location coordinates or methods are changed.
- Tasbih Counter increments on tap, plays correct haptics, and handles target-reached triggers (33/99/100).
- Custom Dhikr can be added, deleted, and tracked.
- Quran Khatm target can be configured and daily pages logged.
- Reflection notes are successfully saved in the Quran journal list.
- Sunnah Checklist logs 12 rawatib prayers, Witr, and Sadaqah, and updates Witr plant on the garden canvas.
- Spiritual Analytics charts load data correctly and represent consistency percentages.
- Qibla compass pointer rotates dynamically according to device headings.
- Categorized Duas can be browsed, searched, and read in English and Arabic.
- Hijri calendar correctly matches the corresponding Gregorian dates.
