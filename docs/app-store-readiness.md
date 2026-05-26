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
- No collected data types declared for the current MVP because core worship logging and settings remain local on device.
- Payment/support screen remains disabled and clearly states that payments are not live.
- Arabic and English app copy exist for the MVP garden, onboarding, settings, and support surfaces.

## MVP Claim Boundaries

- Hasana is a gentle worship consistency garden. It is not a medical, mental health, counseling, or wellbeing treatment app.
- Hasana does not claim religious authority. MVP copy should use neutral worship labels and avoid issuing rulings, fatwas, or source-heavy guidance without review.
- Core worship logging is local-only in MVP. Do not claim cloud sync, account backup, social sharing, end-to-end encryption, or server-side privacy protections unless those systems are implemented and reviewed.
- Payment support is disabled in MVP. Do not claim live donations, zakat, sadaqah processing, subscriptions, purchases, or charitable collection.
- Arabic and English copy should stay warm, humble, and accurate. Prefer encouragement such as "return", "tend", and "continue" over shame, spiritual ranking, or guaranteed outcomes.

## App Store Connect Metadata Draft

### App Name

Hasana - حسنة

### Subtitle

A calm garden for daily worship.

### Promotional Text

Tend a private lifelong garden through prayer, Quran, dhikr, and gentle daily return.

### Description

Hasana is a calm daily companion for young Muslims who want to build consistency with worship through a private lifelong garden.

Build a lifelong garden by tending small daily practices such as prayer, Quran, adhkar, and Witr. Missing a day does not erase your growth; Hasana is designed around gentle continuity rather than pressure, public scores, or comparison.

The current MVP stores core worship logging locally on your device, supports Arabic and English, and includes appearance, theme, and app icon settings. Payment support is disabled in this release.

### Keywords

Islam,Muslim,prayer,Quran,dhikr,worship,habits,spirituality,Arabic,reflection

### Review Notes

Hasana currently stores core worship progress locally on device using UserDefaults. The support screen is a disabled development-support placeholder and does not process payments, collect payment information, or present zakat or sadaqah categories.

## Privacy Answers

- Data collection: none declared for the current MVP, because core worship progress and settings remain local on device.
- Tracking: no.
- Third-party SDKs: none currently present in the Xcode project.
- Sensitive information: worship activity may be sensitive, but it is not transmitted off device in the current MVP.
- Privacy policy URL: still required in App Store Connect before submission.

## Required Before Submission

- Create and publish a privacy policy URL that matches the local-only data model.
- Confirm the public launch version with App Store Connect, likely `1.0.0` instead of the current `0.0.1`.
- Capture one to ten App Store screenshots for required iPhone and iPad sizes. Prioritize onboarding, garden, daily logging, settings, Arabic UI, and disabled support/payment state.
- Complete App Store age rating questionnaire.
- Complete export compliance answers.
- Run manual QA on at least one small iPhone, one large iPhone, and one iPad in Arabic and English.
- Review worship labels and religious copy before release.
- Confirm no App Store metadata or screenshots imply live payments, medical benefit, religious authority, cloud sync, social sharing, or data collection beyond the implemented MVP.

## Manual QA Checklist

- First launch shows splash, then onboarding.
- Onboarding language switch updates copy and layout direction.
- Skip and start both enter the garden and do not show onboarding again.
- Garden orbit, pan, or zoom interactions work and persist after relaunch where implemented.
- Tapping each practice opens the log sheet focused on that practice.
- Tending and untending each practice persists after relaunch.
- Core worship logging works without account creation, cloud sync, or network access.
- Reset view recenters and persists.
- Command palette or primary navigation opens MVP garden logging, settings, and support surfaces.
- Settings language, appearance, theme, and app icon choices persist.
- Support screen clearly states that payments are not live and cannot initiate a real payment.
- Support screen does not collect payment information and does not present zakat or sadaqah categories.
- Dynamic Type does not clip primary actions on common device sizes.
- VoiceOver can identify each garden practice by name, status, growth stage, and tended/untended/dormant state.
- VoiceOver hints explain how to open logging, tend, untend, change logging day, and use onboarding/settings controls.
- Garden and logging surfaces communicate tended, untended, and dormant states with text or symbols in addition to color.
- Calendar day chips, garden practice targets, floating action button, onboarding navigation, and settings choice controls have comfortable tap targets.
- Arabic and English onboarding, logging, and settings text do not clip on iPhone SE, standard iPhone, and large iPhone layouts at default and large Dynamic Type.
- Settings theme and app icon grids collapse or wrap without truncating Arabic labels on narrow iPhone widths.
- Arabic and English product copy remains gentle, accurate, and free from shame-based failure language.
- App Store screenshots and metadata do not imply medical benefit, religious authority, cloud sync, social sharing, live payments, or charitable collection.
