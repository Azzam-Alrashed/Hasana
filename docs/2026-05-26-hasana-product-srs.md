# Hasana Product SRS

Date: 2026-05-26
Status: Approved (Comprehensive Features Implemented)
Owner: Product
Related docs:

- 2026-05-25-hasana-gamified-garden-requirements-en.md
- 2026-05-25-hasana-gamified-garden-requirements-ar.md
- app-store-readiness.md

## 1. Product Summary

Hasana is a spiritually grounded daily operating system for Muslim professionals. The current product direction centers on a lifelong garden that grows through worship and reflection, with a lightweight donation surface for users who want to support development. The app should help users return to meaningful practices with calmness, beauty, and privacy rather than pressure, public comparison, or noisy scoring.

The product is a gentle companion for consistency. In addition to the visual garden canvas, the app provides a suite of integrated utility trackers: calculated prayer times with local athan notifications, an electronic Tasbih counter, a Quran Khatm planner and reflection journal, a Sunnah and Sadaqah logger, spiritual analytics, and an Islamic hub containing a Qibla compass, Hijri calendar, Dua library, and customizable spiritual habits.

## 2. Goals

### Product Goals

- Help Muslim users build consistency in obligatory worship and selected Sunnah practices.
- Represent spiritual consistency visually through a personal garden.
- Make returning after missed days emotionally safe.
- Support Arabic and English from the start.
- Keep worship data private by default.
- Build a foundation for future Islamic seasons, forgotten Sunnahs, social encouragement, and app-support donation workflows.

### Non-Goals For MVP

- Public leaderboards or competitive worship ranking.
- Detailed religious instruction without review.
- Automatic prayer detection or external verification.
- Zakat or sadaqah tracking.
- Full payment processing without explicit provider scope and review.
- Friend feeds that expose exact worship activity.
- A broad productivity task manager unrelated to the spiritual garden.

## 3. Audience And Personas

### Primary Persona: Young Muslim Professional

The user wants structure around prayer, Quran, and dhikr, but does not want an app that feels judgmental or childish. They may be busy, inconsistent, and sensitive to shame-based reminders.

Needs:

- Quick daily check-in.
- A calm reason to come back.
- Privacy and emotional safety.
- Arabic/English flexibility.
- Beautiful progress that does not feel like worship is being reduced to points.

### Secondary Persona: Spiritually Curious Returner

The user wants to restart after a difficult season. They need low-friction logging, forgiving progress, and reminders that encourage continuation rather than perfection.

Needs:

- Easy restart.
- Clear next action.
- Gentle copy.
- No destructive failure states.

### Future Persona: Social Encourager

The user wants to support friends or family with duas, encouragement, or symbolic gifts while respecting privacy.

Needs:

- Explicit consent before sharing.
- No visibility into exact worship details by default.
- Lightweight supportive interactions.

## 4. Product Principles

- Worship first, game second: visual rewards should honor worship, not trivialize it.
- Gentle continuity: missing a day should not erase meaning.
- Privacy by default: worship details belong to the user.
- Beauty over numbers: the garden should communicate progress before dashboards do.
- Bilingual from the foundation: Arabic and English should be first-class product surfaces.
- Religious humility: disputed or guidance-heavy content requires review before launch.

## 5. Current Product Surface

The current app implementation suggests the following surfaces:

- Garden canvas: a pan/zoom visual garden with plants for practices.
- Worship logging sheet: users can tend today's practices.
- Command palette: users can navigate to settings, payments, and all trackers (Tasbih, Quran, Sunnah, Analytics, Prayer Times, Islamic Hub).
- Floating command button: quick access to common actions and command palette.
- Payments view: donation surface for supporting Hasana development (placeholder mode).
- Settings view: language, appearance, theme, and app icon choices.
- Onboarding view: intro pages with language switching and garden-centered framing.
- Prayer Times Dashboard: prayer calculation details, timer countdown, and Notification settings.
- Tasbih Counter: electronic counter with haptic taps, limits, and preset/custom adhkar.
- Quran Tracker: Khatm goal setting, daily logged pages, and a reflection journal.
- Sunnah & Sadaqah Tracker: checklist for daily Sunnah Rawatib prayers, Witr, and voluntary charity (Sadaqah).
- Spiritual Analytics: visual charts, activity breakdown, and historical logs.
- Islamic Hub: hub containing Qibla Compass, categorized Duas (Hisn al-Muslim), Hijri calendar, and customizable habits.

## 6. MVP Scope

### Included

- First-run onboarding.
- Bilingual Arabic/English app copy.
- Lifelong garden canvas with practice representations.
- Practice catalog containing five daily prayers, Quran, adhkar, and Witr.
- Daily tend/untend logging for each practice.
- Growth stages based on accumulated tended days.
- Persistent garden progress and viewport state.
- Settings for language, appearance, theme, and app icon.
- Donation surface for supporting Hasana development.
- Command palette and floating action entry points.
- Offline Prayer Times Engine & Dashboard (athan calculation methods, settings, and local scheduled alarms).
- Tasbih electronic counter with customizable items.
- Quran Tracker with Khatm progression and tadabbur journal.
- Sunnah tracker (Rawatib, Witr) and Sadaqah tracker.
- Spiritual Analytics showing consistency charts.
- Islamic Hub (Qibla Compass with CoreLocation, categorized Duas, Hijri Calendar, and spiritual habits).

### Excluded Until Later

- Server sync and account creation (stored locally).
- Full payment processing (SDK payments).
- Friend interactions (social sharing and comparisons).
- Forgotten Sunnah discovery system.
- Islamic seasonal campaigns.

## 7. Functional Requirements

### FR-1 Onboarding

Priority: P0

Requirements:

- The app shall show onboarding to first-time users.
- The onboarding shall explain the garden metaphor and core value in a calm, concise way.
- The user shall be able to switch language during onboarding.
- The user shall be able to skip onboarding.
- The user shall be able to complete onboarding and enter the main garden.

Acceptance criteria:

- Given a new user, when they open the app, they see onboarding before the main garden.
- Given onboarding is visible, when the user changes language, page copy and layout direction update.
- Given the user taps skip or start, onboarding does not block access to the garden.

#### Implementation Status & Mapping

- **Status**: Fully Implemented.
- **Controller/Gate**: [SplashGateView](file:///Users/azzam-dev/Hasana/Hasana/Hasana/App/SplashView.swift) - Gatekeeper checks `@AppStorage(HasanaSettingsKeys.hasCompletedOnboarding)` to decide between showing onboarding or the main view.
- **View**: [HasanaOnboardingView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Onboarding/HasanaOnboardingView.swift) - Provides a three-page bilingual swipeable interface with language segment switching and a skip option.

---

### FR-2 Garden Canvas

Priority: P0

Requirements:

- The app shall render a lifelong garden as the main screen.
- The garden shall show each configured practice as a plant, flower, or foundational tree.
- The garden shall support pan and zoom.
- The app shall persist viewport offset and zoom.
- Selecting a practice shall open logging for that practice.

Acceptance criteria:

- Given saved viewport state, when the app opens, the garden restores the saved offset and scale.
- Given a visible practice, when the user taps it, the logging sheet opens with that practice selected.
- Given the user pans or zooms, when they return later, the adjusted view is preserved.

#### Implementation Status & Mapping

- **Status**: Fully Implemented.
- **Main View**: [HasanaGardenView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Garden/Views/HasanaGardenView.swift) - Integrates the background grid, ground shape, sun, and interactive plants.
- **Grid Background**: [DottedBackground.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Canvas/Views/Components/DottedBackground.swift) - Renders a coordinate dotted pattern.
- **State & Gesture Control**: [ViewportState.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Canvas/State/ViewportState.swift) - Manages scale clamping (`0.1` to `2.0`), panning drag translation, and double-pan gestures.
- **Persistence**: Saved inside [HasanaGardenStore.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Garden/State/HasanaGardenStore.swift) via `UserDefaults` with key `hasana.garden.snapshot.v1`.

---

### FR-3 Practice Catalog

Priority: P0

Requirements:

- The app shall include the five daily prayers: Fajr, Dhuhr, Asr, Maghrib, and Isha.
- The app shall include Quran, morning/evening adhkar, and Witr.
- Each practice shall have a worship type, religious status, icon, visual role, title, subtitle, and default garden position.
- Practice names and subtitles shall support Arabic and English.

Acceptance criteria:

- Given the app is in English, all practice names and subtitles render in English.
- Given the app is in Arabic, all practice names and subtitles render in Arabic with RTL layout where applicable.
- Given the catalog changes in code, the garden and logging sheet both reflect the same practice list.

#### Implementation Status & Mapping

- **Status**: Fully Implemented.
- **Model**: `HasanaGardenPractice` in [HasanaGardenModels.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Garden/Models/HasanaGardenModels.swift) - Defines fields for IDs, type, religious status, SF Symbol icons, visual roles, default positions, and bilingual text mapping.
- **Catalog Source of Truth**: `HasanaGardenPractice.defaults` in [HasanaGardenModels.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Garden/Models/HasanaGardenModels.swift#L250) - Populates the 8 default practices (Fajr, Dhuhr, Asr, Maghrib, Isha, Quran, Adhkar, Witr) with distinct canvas offsets.

---

### FR-4 Daily Worship Logging

Priority: P0

Requirements:

- The user shall be able to mark a practice as tended for today.
- The user shall be able to untend a practice for today if tapped by mistake.
- The logging state shall be saved locally.
- The garden shall visually indicate which practices were tended today.
- The logging sheet shall show each practice, its status, growth stage, and today's logging state.

Acceptance criteria:

- Given a practice is not tended today, when the user taps "Tend today", it becomes tended.
- Given a practice is tended today, when the user taps it again, today's tended state is removed.
- Given a practice is tended today, the garden displays a visual confirmation on that plant.
- Given the app is restarted, logged progress remains available.

#### Implementation Status & Mapping

- **Status**: Fully Implemented.
- **Sheet View**: [HasanaGardenLogSheet.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Garden/Views/HasanaGardenLogSheet.swift) - Implements a unified sheet with a 7-day retrospective horizontal picker and detail cards for each practice.
- **Store & Core Logic**: [HasanaGardenStore.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Garden/State/HasanaGardenStore.swift) - Controls toggling today (`toggleToday(for:)`), fetching day keys in `YYYY-MM-DD` format, and caching progress snapshots.
- **Visual Feedback**: [HasanaGardenView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Garden/Views/HasanaGardenView.swift) - Displays checkmark badges on the plant and shows a blue water droplet animation overlay when the plant is watered/tended.

---

### FR-5 Growth Stages

Priority: P0

Requirements:

- The app shall calculate growth stage from total tended days.
- Growth stages shall include seed, sprout, young, mature, and flowering.
- Growth stages shall affect visual representation.
- Missing a day shall not reset total growth.

Acceptance criteria:

- Given a practice has zero tended days, it appears as seed.
- Given a practice has repeated tended days, it advances through the configured growth stages.
- Given the user misses a day, prior accumulated growth remains intact.

#### Implementation Status & Mapping

- **Status**: Fully Implemented.
- **Calculation**: `HasanaGardenGrowthStage` in [HasanaGardenModels.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Garden/Models/HasanaGardenModels.swift#L63) - Maps cumulative counts to stages: `0` days = Seed, `1-2` = Sprout, `3-6` = Young, `7-13` = Mature, `14+` = Flowering.
- **Visual Rendering**: `HasanaGardenPlantIllustration` in [HasanaGardenView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Garden/Views/HasanaGardenView.swift#L291) - Draws custom vectors (stem thickness, leaf counts, petal formations) depending on the stage and visual roles (tree vs leafy plant vs flower).

---

### FR-6 Command Palette

Priority: P1

Requirements:

- The app shall provide a command palette for fast navigation and actions.
- The command palette shall include reset view, log worship, support donations, and settings.
- Commands shall be searchable by English and Arabic keywords.
- Executing a command shall perform the intended app action.

Acceptance criteria:

- Given the command palette is open, when the user selects reset view, the garden returns to center at default zoom.
- Given the user selects log worship, the worship logging sheet opens.
- Given the user selects support donations or settings, the correct sheet opens.

#### Implementation Status & Mapping

- **Status**: Fully Implemented.
- **Overlay View**: [CommandPaletteView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/CommandPalette/CommandPaletteView.swift) - A glassmorphic overlay triggered as a sheet layer. Supporting keyboard arrows, Esc keys, and search filters.
- **ViewModel**: [CommandPaletteViewModel.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/CommandPalette/CommandPaletteViewModel.swift) - Handles tokenized, diacritic-insensitive command search scoring in both Arabic and English.
- **Commands**: Defined in [HasanaCommand.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Core/Models/HasanaCommand.swift) with IDs (`.resetView`, `.logWorship`, `.openPayments`, `.openSettings`) and localized keywords.

---

### FR-7 Floating Action Entry

Priority: P1

Requirements:

- The app shall provide an always-available floating entry point for common actions.
- The primary action shall open the command palette.
- Quick actions shall support logging a good deed, setting intention, and reflection paths.
- MVP may route intention and reflection to the command palette until dedicated flows exist.

Acceptance criteria:

- Given the user is on the garden, when they tap the floating command button, command actions become reachable.
- Given the user selects log good deed, the worship logging flow opens.

#### Implementation Status & Mapping

- **Status**: Fully Implemented.
- **View**: [FloatingCommandButton.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/FloatingCommand/FloatingCommandButton.swift) - A floating icon that sprouts three secondary bubbles via long press or drag:
  - **Log Good Deed**: Opens the logging sheet with no pre-selected practice.
  - **Set Intention**: Pre-fills the command palette query with "Settings" / "الإعدادات".
  - **Reflect**: Pre-fills the command palette query with "Log" / "تسجيل".
- **Container integration**: Attached to the main canvas in [RootView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/App/RootView.swift#L31).

---

### FR-8 Development Support Donations

Priority: P2

Requirements:

- The app shall include a development-support donations area.
- The area shall present donations as a way to support continued Hasana development.
- The area shall not present zakat or sadaqah as tracked payment categories.
- The area shall communicate that donations support app development.
- MVP shall not process real payments unless payment provider integration is explicitly scoped and reviewed.

Acceptance criteria:

- Given the user opens payments, they see a donation option for supporting Hasana development.
- Given the user opens payments, they do not see zakat or sadaqah categories.
- Given payments are placeholder-only, no user should be able to accidentally initiate a real transaction.

#### Implementation Status & Mapping

- **Status**: Placeholder Implemented (Disabled by design).
- **View**: [HasanaPaymentsView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Payments/Views/HasanaPaymentsView.swift) - Shows development donation packages (SAR 10, 25, 50) and what development areas they support.
- **Safety**: The main CTA button is explicitly disabled (`.disabled(true)`, `.opacity(0.72)`) and shows notice copy stating that payments are not live and no transaction will occur.

---

### FR-9 Settings

Priority: P0

Requirements:

- The app shall allow users to change language between Arabic and English.
- The app shall allow users to choose appearance mode.
- The app shall allow users to choose theme.
- The app shall allow users to choose alternate app icons where platform support allows.
- Settings choices shall persist.

Acceptance criteria:

- Given the user changes language, app copy updates.
- Given the user changes appearance or theme, visible UI updates.
- Given the user changes app icon, the system icon changes or an actionable error is shown.

#### Implementation Status & Mapping

- **Status**: Fully Implemented.
- **View**: [HasanaSettingsView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Settings/HasanaSettingsView.swift) - Includes segmented controls for Language and Mode, a grid picker for themes (Garden, Sunrise, Ocean, Lavender), and a grid picker for 8 alternative app icons.
- **Model & Persistence**: [HasanaAppSettings.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Core/Settings/HasanaAppSettings.swift) - Uses `@Observable` to bind settings, caching selection in `UserDefaults` and handling alternate icon application via `UIApplication.shared.setAlternateIconName`.

---

### FR-10 Localization And Layout

Priority: P0

Requirements:

- Arabic and English shall be supported across MVP screens.
- Arabic surfaces shall use RTL layout where natural.
- The garden canvas may preserve left-to-right world coordinates for spatial consistency.
- User-facing strings shall avoid guilt, shame, or public comparison.

Acceptance criteria:

- Given Arabic is selected, navigation titles, buttons, command copy, practice copy, donation/support copy, and settings copy are Arabic.
- Given English is selected, the same surfaces are English.
- Given the app is in Arabic, text should not clip in core controls.

#### Implementation Status & Mapping

- **Status**: Fully Implemented.
- **Language Configurations**: Binds localization using `.environment(\.layoutDirection)` and `.environment(\.locale)` in [RootView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/App/RootView.swift#L67-L68).
- **Coordinate Space Lock**: Preserves panning coordinates by explicitly locking layout direction to `.leftToRight` on the scrolling canvas inside [HasanaGardenView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Garden/Views/HasanaGardenView.swift#L108) and on the gestures container of [FloatingCommandButton.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/FloatingCommand/FloatingCommandButton.swift#L48).

---

### FR-11 Prayer Times & Athan Alerts

Priority: P0

Requirements:
- The app shall calculate Islamic prayer times offline using latitude, longitude, timezone offset, calculation method, and school settings.
- The app shall support multiple standard calculation methods (Umm Al-Qura, Muslim World League, ISNA, Egypt, Gulf, Karachi, etc.).
- The app shall support Hanafi and Shafi'i/default schools for Asr prayer calculation.
- The app shall display today's prayer times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) and show a countdown timer to the next prayer.
- The app shall allow scheduling local notification alarms (silent or athan sound) for each of the five prayers.

Acceptance criteria:
- Given location and calculation method, when the app loads, the calculated times match standard astronomical formulas.
- Given the next prayer time, the app renders a ticking countdown timer.
- Given active notification settings, the system schedules local notifications with sound or silent reminders.

#### Implementation Status & Mapping
- **Status**: Fully Implemented.
- **Engine**: [PrayerTimesEngine.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/PrayerTimes/Engine/PrayerTimesEngine.swift) - Astronomical calculations for offline prayer times using spherical trigonometry.
- **View**: [PrayerTimesDashboardView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/PrayerTimes/Views/PrayerTimesDashboardView.swift) - Localized Arabic/English dashboard with location inputs, method picker, toggle switches for notification sounds, and current time indicators.
- **Notification Services**: [NotificationManager.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/PrayerTimes/Services/NotificationManager.swift) - Standard SwiftUI wrapper requesting user authorization and scheduling local notifications via `UNUserNotificationCenter`.

---

### FR-12 Tasbih Counter

Priority: P1

Requirements:
- The app shall provide an electronic Tasbih counter interface.
- The Tasbih counter shall register taps, play haptic feedback, and trigger success effects upon reaching counts of 33, 99, 100, or custom limits.
- The app shall include preset adhkar (Subhan Allah, Al-Hamdulillah, Allahu Akbar, etc.) and allow users to add custom adhkar with title and target limit.
- Completing a tasbih session shall allow the user to water the garden's Adhkar plant directly.

Acceptance criteria:
- Given a target limit, when the user reaches it, a completion animation, sounds, and distinct haptic trigger.
- Given the user logs the session, the Adhkar plant in the garden updates to today's watered state.

#### Implementation Status & Mapping
- **Status**: Fully Implemented.
- **View**: [HasanaTasbihView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Tasbih/Views/HasanaTasbihView.swift) - Provides a circular touch surface, haptic counter logging, sound settings, and custom dhikr creators.

---

### FR-13 Quran Tracker & Journal

Priority: P1

Requirements:
- The app shall provide a Quran reading and Khatm tracker.
- The user shall be able to set a Khatm goal (e.g. number of days, starting page).
- The user shall be able to log daily reading pages or juz, showing progress toward their target.
- The user shall be able to write reflection or tadabbur notes associated with logged sessions.
- Saving daily Quran reading progress shall water the garden's Quran plant.

Acceptance criteria:
- Given a Khatm target, the app calculates and shows the remaining pages needed per day.
- Given a logged reading session, the Quran plant is updated to today's tended state on the canvas.

#### Implementation Status & Mapping
- **Status**: Fully Implemented.
- **View**: [QuranJournalView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/QuranJournal/Views/QuranJournalView.swift) - Circular progress chart, target calculator, reading log inputs, and a list of historical reflection notes.

---

### FR-14 Sunnah & Sadaqah Tracker

Priority: P1

Requirements:
- The app shall support logging Sunnah Rawatib prayers (12 daily Sunnah rak'ahs: 2 before Fajr, 4 before Dhuhr, 2 after Dhuhr, 2 after Maghrib, 2 after Isha).
- The app shall track whether the user prayed Witr.
- The app shall provide a checkbox to log daily voluntary charity (Sadaqah).
- Logging Witr prayer shall water the garden's Witr plant.

Acceptance criteria:
- Given the Sunnah logger, when the user logs 12 rak'ahs, they see a visual achievement.
- Given Witr is toggled, the Witr plant in the garden canvas updates to watered/tended.

#### Implementation Status & Mapping
- **Status**: Fully Implemented.
- **View**: [SunnahTrackerView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/SunnahTracker/Views/SunnahTrackerView.swift) - Segmented checklist for Rawatib, a toggle for Witr, a checkbox for Sadaqah, and a 7-day calendar check-in list.

---

### FR-15 Spiritual Analytics

Priority: P1

Requirements:
- The app shall aggregate local logs and show weekly and monthly compliance views.
- The app shall calculate a worship consistency score per practice.
- The analytics shall present data in privacy-preserving bar charts and consistency grids.
- The user shall be able to edit historical logs directly from the calendar list.

Acceptance criteria:
- Given a history of checked practices, the dashboard correctly computes the consistency rate.
- Given the user changes a past day's checked status, the consistency metrics update.

#### Implementation Status & Mapping
- **Status**: Fully Implemented.
- **View**: [SpiritualAnalyticsView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Analytics/Views/SpiritualAnalyticsView.swift) - Interactive grids, vertical bar graphs, and localized Arabic/English activity cards.

---

### FR-16 Islamic Hub (Qibla, Dua, Hijri Calendar, Habits)

Priority: P1

Requirements:
- The app shall provide a central Islamic Hub dashboard containing spiritual utilities.
- The hub shall include a Qibla compass using device CoreLocation coordinates and CoreMotion heading sensors.
- The hub shall include a Dua Library containing categorized duas from Hisn al-Muslim.
- The hub shall display a Hijri calendar.
- The hub shall let users track customizable spiritual habits.

Acceptance criteria:
- Given location permission and hardware heading support, the Qibla compass displays the angle to Kaaba and rotates dynamically.
- Given the Dua library, the user can search and filter prayers.

#### Implementation Status & Mapping
- **Status**: Fully Implemented.
- **Main View**: [IslamicHubView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/IslamicHub/Views/IslamicHubView.swift) - A dashboard organizing and launching the sub-features.
- **Qibla Service & Compass**: [QiblaManager.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Qibla/Services/QiblaManager.swift) and [QiblaCompassView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Qibla/Views/QiblaCompassView.swift) - GPS calculation of bearing to Mecca and CoreLocation compass heading tracking.
- **Dua View**: [DuaLibraryView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/DuaLibrary/Views/DuaLibraryView.swift) - Complete categorized list of supplications with search.
- **Hijri View**: [HijriCalendarView.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/HijriCalendar/Views/HijriCalendarView.swift) - A month grid rendering Islamic calendar dates.
- **Habits View**: Uses dynamic habit settings stored in SwiftUI model state.

---

## 8. Non-Functional Requirements

### Privacy

- Worship progress shall be stored locally for MVP using `UserDefaults`.
- Exact worship activity shall not be shared.
- Future sync or social features shall require explicit user consent.

### Reliability

- Local progress survives app restart via UserDefaults synchronization.
- Logging is idempotent per practice per day key.
- Corrupt or missing stored data fails gracefully by falling back to the default practice catalog.

### Accessibility

- Interactive elements have clear programmatic titles.
- Text sizes use system fonts that support dynamic scaling.
- Tended status is indicated by checkmarks, water drops, and size scales rather than color alone.
- Buttons meet standard iOS tap target dimensions.

### Performance

- The garden viewport uses a hardware-accelerated pan-zoom implementation and lightweight canvas grid.
- Opening sheets and navigation views occurs with minimal UI transition lag.
- Persistence is handled off the main thread where necessary to prevent scroll stutter.

### Religious Review

- Classification tags (Obligatory, Sunnah, Sunnah/Wajib, Quran, Dhikr) use neutral terminologies.
- Descriptive copy focuses on gentle spiritual reminders without establishing arbitrary rules or rulings.

## 9. User Flows

### Flow 1: First Run

1. User opens Hasana.
2. App shows onboarding.
3. User selects Arabic or English if desired.
4. User swipes through the pages or skips.
5. User taps start.
6. App opens the garden.

Success outcome: the user understands that daily practices grow a lifelong garden and can begin without setup friction.

### Flow 2: Tend A Practice From Garden

1. User opens the garden.
2. User taps a visible plant, flower, or tree.
3. App opens the logging sheet scrolled to that practice.
4. User taps the card to tend today's practice.
5. App marks it as tended, updates growth state if needed, and shows completion feedback.
6. User taps done and returns to the garden.

Success outcome: the garden reflects today's action immediately.

### Flow 3: Tend Multiple Practices

1. User opens the floating command button or taps "Log Worship" in the command palette.
2. App opens the logging sheet.
3. User marks multiple practices as tended.
4. App saves each change locally.
5. User closes the sheet.

Success outcome: all selected practices show today's tended state in the garden.

### Flow 4: Reset Garden View

1. User opens the command palette.
2. User searches for or selects reset view.
3. App returns the garden to default center and scale.
4. App persists the reset viewport.

Success outcome: the user can recover from getting lost while panning or zooming.

### Flow 5: Change Language

1. User opens settings.
2. User selects Arabic or English.
3. App updates copy, locale, and layout direction.
4. User closes settings.

Success outcome: the app remains usable and coherent in the selected language.

### Flow 6: Support Development

1. User opens command palette.
2. User selects support/donations.
3. App displays a donation surface for supporting Hasana development.
4. User can review the support message and donation call to action.

Success outcome: the user understands donations support continued app development without accidentally making a payment.

## 10. Prioritization

### P0: MVP Must-Haves

- First-run onboarding.
- Garden as main screen.
- Practice catalog for prayers, Quran, adhkar, and Witr.
- Daily tend/untend logging.
- Growth stages and visual completion feedback.
- Local persistence for progress and viewport.
- Arabic/English support.
- Settings for language and appearance.
- Gentle, privacy-first copy.

### P1: Near-Term Differentiators

- Command palette polish and search quality.
- Floating quick actions with clearer destinations.
- Richer garden states and motion.
- Practice detail/reflection sheet.
- Better empty, missed-day, and return states.
- Accessibility pass.

### P2: Product Expansion

- Islamic seasons such as Ramadan, Fridays, and Dhul Hijjah.
- Forgotten Sunnah discovery.
- Giving planning beyond placeholder rows.
- Prayer time awareness.
- Optional reminders.
- Local backup or private sync.

### P3: Later Bets

- Friends and encouragement layer.
- Symbolic seeds or dua gifts.
- Community campaigns without exposing private worship.
- Advanced personalization.
- Payment provider integration.

## 11. Release Readiness Checklist

- All P0 flows pass manual QA in Arabic and English.
- Logging persists across app restart.
- No P0 screen has clipped primary text on common iPhone sizes.
- The app does not expose private worship data.
- Payment surfaces cannot initiate real transactions unless intentionally integrated.
- Religious content has been reviewed or is clearly limited to neutral product labels.
- App icon switching handles unsupported states gracefully.
- Onboarding can be completed and does not reappear unexpectedly after completion.

## 12. Metrics

MVP metrics should be private and product-health oriented rather than spiritually judgmental.

Recommended:

- Onboarding completion rate.
- Day 1, day 7, and day 30 return rate.
- Number of days with at least one tended practice.
- Percentage of users who change language or theme.
- Frequency of command palette use.
- Crash-free sessions.

Avoid:

- Public worship score.
- Friend comparisons of completed worship.
- Shame-oriented streak loss metrics.

## 13. Open Questions & Resolutions

### Logging Shareability

*Q: Should obligatory prayers and Sunnah practices share the same logging interaction?*

- **Resolution**: Yes. To minimize friction, all practices are logged using cards inside the unified [HasanaGardenLogSheet.swift](file:///Users/azzam-dev/Hasana/Hasana/Hasana/Features/Garden/Views/HasanaGardenLogSheet.swift). They are distinguished visually by color coding and status tags (Obligatory, Sunnah, Sunnah/Wajib, Quran, Dhikr).

---

### Practice Visibility

*Q: Should a user be able to hide practices that do not fit their current focus?*

- **Resolution**: In MVP, all 8 core practices are shown on the canvas by default to keep coordinate offset mapping simple. Hiding/filtering configurations are deferred to post-MVP development.

---

### Worship Nuances

*Q: How should the app handle qada, late prayer, or partial completion without overcomplicating MVP?*

- **Resolution**: Logging is kept strictly binary ("tended" or "untended" for a given calendar day). This guarantees emotional safety and minimizes pressure, avoiding granular tracking of delays or missed timings.

---

### Religious Context

*Q: Which religious authority or review process will approve worship classifications and guidance copy?*

- **Resolution**: The MVP bypasses complex rulings by adopting neutral, standard descriptors (Obligatory, Sunnah, Sunnah/Wajib, Quran, Dhikr) and focusing on descriptive descriptions (e.g. "A calm pause at midday" for Dhuhr) rather than doctrinal instructions.

---

### Prayer Times Integration

*Q: Should prayer times be integrated before reminders are introduced?*

- **Resolution**: Yes. Offline calculations via `PrayerTimesEngine` and daily local scheduled alerts via `NotificationManager` are implemented, enabling a localized dashboard, countdown to the next prayer, and custom notifications.

---

### Donations Architecture

*Q: What payment provider, confirmation flow, and disclosure copy are appropriate if development-support donations become real transactions?*

- **Resolution**: Payment provider SDKs are excluded. The donation screen is a disabled, descriptive placeholder.

---

### Social Architecture

*Q: How much social functionality can exist without creating comparison pressure?*

- **Resolution**: Social elements are excluded from the MVP. Progress is stored local-only, guaranteeing absolute privacy by default.

---

### Growth Mechanics

*Q: Should growth stages be purely cumulative or also reflect recent consistency?*

- **Resolution**: Growth is purely cumulative (calculated from total tended dates) to reinforce the principle of gentle continuity. Missing a day does not reduce a plant's size or reset its growth stage.

---

### Forgotten Sunnah Discovery

*Q: Should forgotten Sunnahs be unlocked by time, learning, seasonal prompts, or user readiness?*

- **Resolution**: The catalog includes Sunnah practices (Witr, Quran, Adhkar) visible to all users from day one, while dynamic unlocking systems are deferred.

## 14. Risks And Mitigations

### Risk: Worship Feels Transactional

Mitigation:

- Avoid points-first UI.
- Keep copy centered on intention, return, and care.
- Use beauty and reflection as rewards rather than competitive scoring.

### Risk: Religious Content Is Incorrect Or Too Broad

Mitigation:

- Mark religious guidance as needing review.
- Keep MVP labels simple.
- Build content systems that can support reviewed sources later.

### Risk: Users Feel Shame After Missing Days

Mitigation:

- Preserve growth after missed days.
- Add return states that welcome the user back.
- Avoid destructive streak reset language.

### Risk: Privacy Expectations Are Violated

Mitigation:

- Store locally in MVP.
- Make sharing opt-in only.
- Do not introduce friend visibility until privacy controls are designed.

## 15. Future Product Docs To Add

- Religious review policy and content governance.
- Worship catalog taxonomy.
- Garden growth balancing spec.
- Islamic seasons spec.
- Forgotten Sunnahs discovery spec.
- Development-support donations product spec.
- Privacy and social sharing spec.
- QA test plan for bilingual SwiftUI screens.
