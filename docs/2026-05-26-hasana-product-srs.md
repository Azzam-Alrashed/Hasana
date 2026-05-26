# Hasana Product SRS

Date: 2026-05-26
Status: Draft
Owner: Product
Related docs:

- 2026-05-25-hasana-gamified-garden-requirements-en.md
- 2026-05-25-hasana-gamified-garden-requirements-ar.md

## 1. Product Summary

Hasana is a spiritually grounded daily operating system for Muslim professionals. The current product direction centers on a lifelong garden that grows through worship and reflection, with a lightweight donation surface for users who want to support development. The app should help users return to meaningful practices with calmness, beauty, and privacy rather than pressure, public comparison, or noisy scoring.

The initial product should feel like a gentle companion for consistency. Users can open the app, see the state of their garden, tend today's practices, support continued development, and adjust language and appearance preferences.

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
- Command palette: users can reset view, log worship, open development-support donations, and open settings.
- Floating command button: quick access to common actions.
- Payments view: donation surface for supporting Hasana development.
- Settings view: language, appearance, theme, and app icon choices.
- Onboarding view: intro pages with language switching and garden-centered framing.

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

### Excluded Until Later

- Server sync and account creation.
- Prayer time calculation.
- Push notifications.
- Full payment processing.
- Friend interactions.
- Forgotten Sunnah discovery system.
- Islamic seasonal campaigns.
- Advanced analytics.

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

## 8. Non-Functional Requirements

### Privacy

- Worship progress shall be stored locally for MVP.
- Exact worship activity shall not be shared by default.
- Future sync or social features shall require explicit user consent.

### Reliability

- Local progress should survive app restart.
- Logging should be idempotent per practice per day.
- Corrupt or missing stored data should fail gracefully to a default garden.

### Accessibility

- Interactive elements should have clear labels.
- Text should support reasonable Dynamic Type behavior.
- Color should not be the only indicator of completion.
- Touch targets should meet platform expectations.

### Performance

- The garden should remain smooth during pan and zoom.
- Opening logging, settings, and donation/support sheets should feel immediate.
- Local persistence should not block UI interaction noticeably.

### Religious Review

- Religious statuses, worship definitions, seasonal prompts, and forgotten Sunnahs require review before release.
- Product copy should avoid issuing unsupported rulings.

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

## 13. Open Questions

- Should obligatory prayers and Sunnah practices share the same logging interaction?
- Should a user be able to hide practices that do not fit their current focus?
- How should the app handle qada, late prayer, or partial completion without overcomplicating MVP?
- Which religious authority or review process will approve worship classifications and guidance copy?
- Should prayer times be integrated before reminders are introduced?
- What payment provider, confirmation flow, and disclosure copy are appropriate if development-support donations become real transactions?
- How much social functionality can exist without creating comparison pressure?
- Should growth stages be purely cumulative or also reflect recent consistency?
- Should forgotten Sunnahs be unlocked by time, learning, seasonal prompts, or user readiness?

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
