# Hasana Software Requirements Specification

Date: 2026-05-26
Status: Approved MVP Build Specification
Owner: Product
Document style: Practical ISO/IEC/IEEE 29148-style SRS

Related documents:

- `2026-05-25-hasana-gamified-garden-requirements-en.md`
- `2026-05-25-hasana-gamified-garden-requirements-ar.md`
- `app-store-readiness.md`

References:

- IEEE 830-1998, superseded SRS guidance: https://standards.ieee.org/ieee/830/1222/
- ISO/IEC/IEEE 29148-2018, current requirements engineering guidance: https://standards.ieee.org/standard/29148-2018.html

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification defines the focused MVP for Hasana, a garden-first worship consistency app for young Muslims. It is the source of truth for product scope, functional requirements, non-functional requirements, external interfaces, acceptance criteria, and traceability.

This document replaces the previous broad product SRS. It intentionally excludes utility-suite scope from the MVP unless the utility directly supports the garden-first experience.

### 1.2 Product Scope

Hasana helps young Muslims build consistency with obligatory worship and selected Sunnah practices through a lifelong personal garden. Daily worship practices are represented as plants, flowers, or foundational trees. As users tend practices, the garden becomes richer and more meaningful.

The MVP shall focus on:

- A lifelong worship garden.
- Eight core practices: Fajr, Dhuhr, Asr, Maghrib, Isha, Quran, Adhkar, and Witr.
- Simple daily done/undone logging.
- Gentle growth, dormant, and return states.
- Arabic and English support.
- Local privacy-first persistence.
- A disabled development-support donation placeholder.

### 1.3 Intended Audience

This SRS is intended for:

- Product owners defining MVP scope.
- Designers creating Hasana's user experience and visual language.
- Engineers implementing the iOS app.
- QA reviewers validating acceptance criteria.
- Religious/content reviewers checking labels and copy for humility and accuracy.

### 1.4 Definitions And Abbreviations

| Term | Definition |
| --- | --- |
| SRS | Software Requirements Specification. |
| MVP | Minimum Viable Product. |
| RTL | Right-to-left layout direction, primarily for Arabic. |
| Practice | A worship habit represented in the garden. |
| Tended | A practice marked complete for a given calendar day. |
| Untended | A practice not marked complete for a given calendar day. |
| Dormant state | A gentle visual state that may indicate recent inactivity without erasing accumulated growth. |
| Growth stage | A visual maturity level derived from accumulated tended days. |
| Development-support donation | A disabled MVP placeholder explaining how users may support continued app development in the future. |

### 1.5 Requirement ID Conventions

| Prefix | Meaning |
| --- | --- |
| `GOAL` | Product goal. |
| `FR` | Functional requirement. |
| `UI` | User interface or external interaction requirement. |
| `DATA` | Data and persistence requirement. |
| `NFR` | Non-functional requirement. |
| `AC` | Acceptance criterion. |
| `FUT` | Future-scope item. |

## 2. Overall Description

### 2.1 Product Perspective

Hasana is a native iOS app centered on a personal spiritual garden. It is not a broad Islamic utility suite, productivity manager, public worship tracker, or social comparison product.

The garden is the primary interface. Supporting surfaces exist only to help the user understand, tend, personalize, or safely support the garden experience.

### 2.2 Product Goals

| ID | Goal |
| --- | --- |
| `GOAL-001` | Help young Muslims build consistency with obligatory worship and selected Sunnah practices. |
| `GOAL-002` | Represent spiritual consistency through a personal lifelong garden. |
| `GOAL-003` | Make returning after missed days emotionally safe. |
| `GOAL-004` | Support Arabic and English from the MVP. |
| `GOAL-005` | Keep worship data private by default. |
| `GOAL-006` | Use gentle gamification that motivates without turning worship into public scoring or pressure. |

### 2.3 User Classes

#### Primary User: Young Muslim Building Consistency

The primary user wants motivation, structure, and emotional encouragement around worship. They may be inconsistent, may feel sensitive to shame-based reminders, and may respond well to beauty, growth, and gentle progression.

Needs:

- A quick daily check-in.
- A reason to return without guilt.
- A beautiful and emotionally meaningful sense of progress.
- Arabic/English flexibility.
- Privacy and control over worship data.

#### Secondary User: Spiritually Curious Returner

The secondary user wants to restart after a difficult season. They need low-friction logging, gentle language, and non-destructive progress behavior.

Needs:

- Simple restart paths.
- No harsh failure states.
- Reassuring return copy.
- Progress that is preserved after missed days.

### 2.4 Operating Environment

| ID | Requirement |
| --- | --- |
| `ENV-001` | The MVP shall run as a native iOS app. |
| `ENV-002` | The MVP shall store worship progress locally on device. |
| `ENV-003` | The MVP shall not require account creation, cloud sync, or network access for core worship logging. |
| `ENV-004` | The MVP shall use platform-supported iOS capabilities for settings, appearance, localization, and optional alternate app icons where available. |

### 2.5 Design And Implementation Constraints

| ID | Constraint |
| --- | --- |
| `CON-001` | Worship details shall remain private by default. |
| `CON-002` | Public leaderboards, competitive worship ranking, and friend feeds exposing exact worship activity are excluded from MVP. |
| `CON-003` | Missing a day shall not erase or reduce accumulated growth. |
| `CON-004` | MVP logging shall remain simple done/undone per practice per day. |
| `CON-005` | The donation surface shall not process real transactions in MVP. |
| `CON-006` | Religious guidance-heavy content shall require review before release. |

### 2.6 Assumptions And Dependencies

| ID | Assumption |
| --- | --- |
| `ASM-001` | The initial app is built for iOS. |
| `ASM-002` | Local persistence is sufficient for MVP. |
| `ASM-003` | The eight core practices are fixed for MVP. |
| `ASM-004` | Existing utility modules may remain in the codebase, but they are not MVP requirements unless included in this SRS. |
| `ASM-005` | Arabic and English copy will be reviewed for tone, clarity, and fit before release. |

## 3. External Interface Requirements

### 3.1 User Interface Requirements

| ID | Requirement |
| --- | --- |
| `UI-001` | The garden shall be the main screen after onboarding. |
| `UI-002` | The garden shall visually represent each MVP practice as a plant, flower, or foundational tree. |
| `UI-003` | The app shall provide an onboarding flow explaining the garden metaphor and core value. |
| `UI-004` | The app shall provide a logging surface for tending and untending today's practices. |
| `UI-005` | The app shall provide settings for language, appearance, theme, and app icon where supported. |
| `UI-006` | The app shall provide a disabled development-support donation placeholder. |
| `UI-007` | The app shall use warm, youth-friendly, spiritually gentle copy. |
| `UI-008` | The app shall avoid shame-based language, public comparison language, and harsh failure-state copy. |
| `UI-009` | The app shall allow users to recover from garden navigation changes through a reset view action. |
| `UI-010` | The app shall make tended status visible without relying on color alone. |

### 3.2 Localization And Layout Interfaces

| ID | Requirement |
| --- | --- |
| `UI-011` | The MVP shall support Arabic and English user-facing copy. |
| `UI-012` | Arabic screens shall use RTL layout where natural for text and controls. |
| `UI-013` | The garden canvas may preserve a stable left-to-right coordinate space to avoid changing plant positions when language changes. |
| `UI-014` | Core controls shall not clip primary Arabic or English text on common supported iPhone sizes. |

### 3.3 Software Interfaces

| ID | Requirement |
| --- | --- |
| `DATA-001` | The app shall persist MVP progress locally using on-device storage. |
| `DATA-002` | The app shall persist app settings locally. |
| `DATA-003` | The app shall not depend on a backend service for MVP garden logging. |
| `DATA-004` | The app shall not transmit exact worship activity to third parties in MVP. |

### 3.4 Hardware And Platform Interfaces

| ID | Requirement |
| --- | --- |
| `UI-015` | The app may use standard iOS haptics for completion feedback if available. |
| `UI-016` | The app may use iOS alternate icon APIs where supported. |
| `UI-017` | If a platform capability is unavailable, the app shall fail gracefully with non-blocking feedback. |

### 3.5 Payment Placeholder Interface

| ID | Requirement |
| --- | --- |
| `UI-018` | The development-support donation surface shall clearly state that payments are not live. |
| `UI-019` | The development-support donation surface shall prevent accidental real payment initiation. |
| `UI-020` | The development-support donation surface shall not present zakat or sadaqah as payment categories. |

## 4. System Features And Functional Requirements

### 4.1 First-Run Onboarding

| ID | Requirement |
| --- | --- |
| `FR-001` | The app shall show onboarding to first-time users before opening the garden. |
| `FR-002` | Onboarding shall explain that daily worship practices grow a lifelong garden. |
| `FR-003` | The user shall be able to switch between Arabic and English during onboarding. |
| `FR-004` | The user shall be able to skip or complete onboarding and enter the garden. |
| `FR-005` | The app shall remember that onboarding has been completed or skipped. |

Acceptance criteria:

| ID | Criteria |
| --- | --- |
| `AC-001` | Given a first-time user, when the app launches, then onboarding appears before the garden. |
| `AC-002` | Given onboarding is visible, when the user changes language, then onboarding copy updates to the selected language. |
| `AC-003` | Given the user skips or completes onboarding, when they relaunch the app, then onboarding does not block access to the garden. |

### 4.2 Lifelong Garden Canvas

| ID | Requirement |
| --- | --- |
| `FR-006` | The app shall render the lifelong garden as the primary post-onboarding screen. |
| `FR-007` | The garden shall show each MVP practice as a distinct visual element. |
| `FR-008` | The garden shall support panning and zooming. |
| `FR-009` | The garden shall persist viewport offset and zoom. |
| `FR-010` | Selecting a practice in the garden shall open logging for that practice. |
| `FR-011` | The app shall provide a reset view action that returns the garden to its default viewport. |

Acceptance criteria:

| ID | Criteria |
| --- | --- |
| `AC-004` | Given the garden is open, when the user pans or zooms, then the viewport changes smoothly. |
| `AC-005` | Given a saved viewport, when the user returns to the garden, then the saved offset and zoom are restored. |
| `AC-006` | Given a visible practice, when the user taps it, then the logging surface opens for that practice. |
| `AC-007` | Given the user triggers reset view, then the garden returns to the default viewport. |

### 4.3 MVP Practice Catalog

| ID | Requirement |
| --- | --- |
| `FR-012` | The MVP catalog shall include Fajr, Dhuhr, Asr, Maghrib, Isha, Quran, Adhkar, and Witr. |
| `FR-013` | Each practice shall have a stable identifier. |
| `FR-014` | Each practice shall have a worship type. |
| `FR-015` | Each practice shall have a religious status label using neutral terminology. |
| `FR-016` | Each practice shall have Arabic and English names. |
| `FR-017` | Each practice shall have Arabic and English short descriptive copy. |
| `FR-018` | Each practice shall have a default garden position and visual role. |

Acceptance criteria:

| ID | Criteria |
| --- | --- |
| `AC-008` | Given the app is in English, when the practice catalog is shown, then all MVP practice names and short descriptions appear in English. |
| `AC-009` | Given the app is in Arabic, when the practice catalog is shown, then all MVP practice names and short descriptions appear in Arabic. |
| `AC-010` | Given the catalog is loaded, then the garden and logging surface expose the same eight MVP practices. |

### 4.4 Daily Worship Logging

| ID | Requirement |
| --- | --- |
| `FR-019` | The user shall be able to mark each MVP practice as tended for the current calendar day. |
| `FR-020` | The user shall be able to untend a practice for the current calendar day if marked by mistake. |
| `FR-021` | Logging shall be binary: tended or untended. |
| `FR-022` | MVP logging shall not require late, qada, partial, skipped, or explanatory states. |
| `FR-023` | The app shall save daily logging state locally. |
| `FR-024` | The garden shall visually indicate practices tended today. |
| `FR-025` | The logging surface shall show the practice, current daily state, and growth stage. |

Acceptance criteria:

| ID | Criteria |
| --- | --- |
| `AC-011` | Given a practice is untended today, when the user marks it tended, then today's state becomes tended. |
| `AC-012` | Given a practice is tended today, when the user untends it, then today's tended state is removed. |
| `AC-013` | Given a practice is tended today, when the user returns to the garden, then the plant shows today's tended state. |
| `AC-014` | Given the app restarts, when the user returns to logging, then previously saved daily state remains available. |

### 4.5 Growth, Dormancy, And Gentle Return

| ID | Requirement |
| --- | --- |
| `FR-026` | The app shall calculate growth stage from accumulated tended days. |
| `FR-027` | Growth stages shall include seed, sprout, young, mature, and flowering. |
| `FR-028` | Growth stage shall affect the practice's visual representation in the garden. |
| `FR-029` | Missing a day shall not reset accumulated tended days. |
| `FR-030` | Missing a day shall not reduce or erase a plant's earned growth stage. |
| `FR-031` | The app may show a gentle dormant state after missed days. |
| `FR-032` | Dormant state copy and visuals shall encourage return without shame or punishment. |

Acceptance criteria:

| ID | Criteria |
| --- | --- |
| `AC-015` | Given a practice has zero tended days, then it appears in the seed stage. |
| `AC-016` | Given a practice accumulates tended days, then it advances through growth stages. |
| `AC-017` | Given the user misses a day, then the plant's accumulated growth remains intact. |
| `AC-018` | Given a plant is dormant, when the user tends the practice again, then the app presents return as care and continuation. |

### 4.6 Gentle Gamification

| ID | Requirement |
| --- | --- |
| `FR-033` | The primary reward shall be visual garden beauty and emotional attachment. |
| `FR-034` | Private counts or streak-like signals may be used only as secondary motivation. |
| `FR-035` | Collection and discovery mechanics may be introduced only when they preserve spiritual gentleness. |
| `FR-036` | The MVP shall not include public worship scores, leaderboards, or competitive ranking. |
| `FR-037` | The app shall avoid destructive streak loss language. |

Acceptance criteria:

| ID | Criteria |
| --- | --- |
| `AC-019` | Given the user completes practices, then garden visuals provide the primary progress feedback. |
| `AC-020` | Given gamified feedback is shown, then it remains private and secondary to the garden. |
| `AC-021` | Given a missed day occurs, then the app avoids shame-based streak loss messaging. |

### 4.7 Settings And Personalization

| ID | Requirement |
| --- | --- |
| `FR-038` | The user shall be able to change language between Arabic and English. |
| `FR-039` | The user shall be able to choose appearance mode where supported. |
| `FR-040` | The user shall be able to choose an app theme. |
| `FR-041` | The user shall be able to choose an alternate app icon where supported. |
| `FR-042` | Settings choices shall persist locally. |

Acceptance criteria:

| ID | Criteria |
| --- | --- |
| `AC-022` | Given the user changes language, then visible MVP app copy updates to the selected language. |
| `AC-023` | Given the user changes theme or appearance, then visible MVP surfaces update consistently. |
| `AC-024` | Given the user changes app icon on a supported device, then the system icon updates or a graceful non-blocking error appears. |
| `AC-025` | Given the app restarts, then saved settings remain applied. |

### 4.8 Development-Support Donation Placeholder

| ID | Requirement |
| --- | --- |
| `FR-043` | The app shall include a development-support donation surface in MVP. |
| `FR-044` | The donation surface shall explain that support is for continued Hasana development. |
| `FR-045` | The donation surface shall clearly state that payments are not live in MVP. |
| `FR-046` | The donation surface shall prevent initiating real transactions. |
| `FR-047` | The donation surface shall not describe donations as zakat or sadaqah tracking. |

Acceptance criteria:

| ID | Criteria |
| --- | --- |
| `AC-026` | Given the user opens the support surface, then they see development-support messaging. |
| `AC-027` | Given payments are not live, then no action can initiate a real transaction. |
| `AC-028` | Given the support surface is visible, then it does not present zakat or sadaqah as payment categories. |

## 5. Data Requirements

| ID | Requirement |
| --- | --- |
| `DATA-005` | The app shall store a local practice catalog for the eight MVP practices. |
| `DATA-006` | The app shall store daily logging state by practice identifier and calendar day. |
| `DATA-007` | The app shall store accumulated tended-day history sufficient to calculate growth stages. |
| `DATA-008` | The app shall store whether onboarding has been completed or skipped. |
| `DATA-009` | The app shall store language, appearance, theme, and app icon settings locally. |
| `DATA-010` | The app shall store garden viewport offset and zoom locally. |
| `DATA-011` | The app shall handle missing or corrupt local data by falling back to safe defaults. |
| `DATA-012` | The MVP shall not store account credentials because accounts are out of scope. |
| `DATA-013` | The MVP shall not store payment credentials because live payments are out of scope. |

## 6. Non-Functional Requirements

### 6.1 Privacy And Security

| ID | Requirement |
| --- | --- |
| `NFR-001` | Worship progress shall be private by default. |
| `NFR-002` | Exact worship activity shall not be shared externally in MVP. |
| `NFR-003` | Any future sync or social feature shall require explicit user consent before sharing worship-related data. |
| `NFR-004` | The MVP shall not require account creation. |

### 6.2 Reliability

| ID | Requirement |
| --- | --- |
| `NFR-005` | Local progress shall survive app restart. |
| `NFR-006` | Daily logging shall be idempotent for each practice and calendar day. |
| `NFR-007` | The app shall recover gracefully from missing stored data. |
| `NFR-008` | The app shall preserve accumulated growth after missed days. |

### 6.3 Usability And Accessibility

| ID | Requirement |
| --- | --- |
| `NFR-009` | MVP workflows shall be usable without account setup. |
| `NFR-010` | Core interactive elements shall have clear accessible labels. |
| `NFR-011` | Core buttons and tappable surfaces shall follow standard iOS tap target expectations. |
| `NFR-012` | Text shall support dynamic type where practical. |
| `NFR-013` | Tended state shall use more than color alone. |

### 6.4 Performance

| ID | Requirement |
| --- | --- |
| `NFR-014` | Garden panning and zooming shall feel responsive on supported devices. |
| `NFR-015` | Opening MVP sheets and settings shall occur without noticeable blocking caused by persistence operations. |
| `NFR-016` | Local data reads and writes shall not cause visible garden scroll or gesture stutter. |

### 6.5 Religious Content And Tone

| ID | Requirement |
| --- | --- |
| `NFR-017` | Religious labels shall use neutral terminology for MVP. |
| `NFR-018` | The app shall avoid giving detailed religious rulings without review. |
| `NFR-019` | User-facing copy shall encourage return, care, and consistency without guilt. |
| `NFR-020` | Copy shall be warm, youth-friendly, respectful, and not childish. |

## 7. MVP User Flows

### 7.1 First Run

1. User opens Hasana.
2. App shows onboarding.
3. User optionally switches language.
4. User skips or completes onboarding.
5. App opens the garden.

Success outcome: the user understands that worship practices grow a lifelong garden and can begin without setup friction.

### 7.2 Tend A Practice From The Garden

1. User opens the garden.
2. User taps a visible plant, flower, or tree.
3. App opens logging for that practice.
4. User marks the practice tended for today.
5. App saves the state locally.
6. Garden immediately reflects today's tended state.

Success outcome: the user can tend a practice quickly and see meaningful visual feedback.

### 7.3 Tend Multiple Practices

1. User opens the logging surface.
2. User marks one or more practices as tended.
3. App saves each change locally.
4. User closes logging.
5. Garden reflects all practices tended today.

Success outcome: the user can complete daily worship logging with minimal friction.

### 7.4 Return After Missed Days

1. User opens Hasana after one or more missed days.
2. Garden preserves accumulated growth.
3. Plants may appear gently dormant.
4. User tends a practice.
5. App frames the action as return and care.

Success outcome: the user feels invited back, not punished.

### 7.5 Change Language

1. User opens settings.
2. User selects Arabic or English.
3. App updates copy, locale, and natural layout direction.
4. Garden plant positions remain spatially stable.

Success outcome: the selected language is applied without breaking the garden experience.

### 7.6 Support Development Placeholder

1. User opens the support/donation surface.
2. App displays development-support messaging.
3. App states payments are not live.
4. User cannot initiate a real transaction.

Success outcome: the user understands the support concept without payment risk.

## 8. Future Scope

The following items are intentionally outside the focused MVP and shall not be treated as MVP requirements.

| ID | Future Item |
| --- | --- |
| `FUT-001` | Prayer times dashboard and athan alerts. |
| `FUT-002` | Tasbih counter as a dedicated module. |
| `FUT-003` | Quran Khatm planner and reflection journal as a dedicated module. |
| `FUT-004` | Sunnah Rawatib and Sadaqah tracker beyond the MVP Witr practice. |
| `FUT-005` | Spiritual analytics dashboards and consistency scoring. |
| `FUT-006` | Islamic Hub with Qibla, Dua Library, Hijri Calendar, and custom habits. |
| `FUT-007` | Islamic seasons such as Ramadan, Fridays, and Dhul Hijjah. |
| `FUT-008` | Forgotten Sunnah discovery and rare hidden plants. |
| `FUT-009` | Friend interactions, duas, symbolic gifts, and social encouragement. |
| `FUT-010` | Account creation, private sync, backup, or multi-device support. |
| `FUT-011` | Live payment provider integration. |
| `FUT-012` | Detailed religious instruction, rulings, or expanded content libraries requiring formal review. |

## 9. Verification And Acceptance Summary

MVP acceptance requires:

- Every `FR` in sections 4.1 through 4.8 passes its linked acceptance criteria.
- Arabic and English MVP flows pass manual QA.
- Worship progress persists locally across restart.
- Missed days do not erase accumulated growth.
- Dormant states, if present, remain gentle and non-punitive.
- No MVP screen exposes private worship activity externally.
- The donation surface cannot initiate real payment.
- Utility-suite features listed in future scope are not required for MVP release.

## 10. Traceability Matrix

| Goal | Requirement IDs | Acceptance Criteria |
| --- | --- | --- |
| `GOAL-001` Build worship consistency | `FR-012` to `FR-025`, `DATA-005` to `DATA-007` | `AC-008` to `AC-014` |
| `GOAL-002` Represent consistency through a lifelong garden | `FR-006` to `FR-011`, `FR-026` to `FR-028`, `UI-001`, `UI-002` | `AC-004` to `AC-007`, `AC-015`, `AC-016` |
| `GOAL-003` Make returning emotionally safe | `FR-029` to `FR-032`, `FR-037`, `NFR-008`, `NFR-019` | `AC-017`, `AC-018`, `AC-021` |
| `GOAL-004` Support Arabic and English | `FR-003`, `FR-016`, `FR-017`, `FR-038`, `UI-011` to `UI-014` | `AC-002`, `AC-008`, `AC-009`, `AC-022` |
| `GOAL-005` Keep worship data private | `DATA-001` to `DATA-004`, `DATA-012`, `NFR-001` to `NFR-004` | `AC-014`, verification summary privacy checks |
| `GOAL-006` Use gentle gamification | `FR-033` to `FR-037`, `NFR-017` to `NFR-020` | `AC-019` to `AC-021` |
| Development support placeholder | `FR-043` to `FR-047`, `UI-018` to `UI-020`, `DATA-013` | `AC-026` to `AC-028` |
| MVP personalization | `FR-038` to `FR-042`, `DATA-008` to `DATA-010`, `UI-005`, `UI-016`, `UI-017` | `AC-022` to `AC-025` |

## 11. Release Readiness Checklist

- Onboarding appears only for first-time users or users who have not completed/skipped it.
- Garden is the primary post-onboarding screen.
- All eight MVP practices appear consistently in garden and logging.
- Daily tended/untended state works for each MVP practice.
- Growth stages advance from accumulated tended days.
- Missed days never erase earned growth.
- Dormant state, if implemented, is gentle and reversible.
- Arabic and English MVP copy are complete.
- Arabic layout does not clip primary controls on supported iPhone sizes.
- Worship data remains local and private.
- Settings persist across app restart.
- Donation placeholder is visibly disabled and cannot process payment.
- Non-MVP utility modules are not required for MVP acceptance.

