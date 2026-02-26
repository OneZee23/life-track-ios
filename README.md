# LifeTrack — iOS

> Minimalist habit tracker for iOS. Did you do it or not?

**Platform:** iOS (App Store)
**Status:** v0.1.0 | **Started:** Feb 2026
**Android version:** [life-track-android](https://github.com/OneZee23/life-track-android) (React Native)

---

## TL;DR

Every habit tracker asks too much. Sliders, ratings, timers, notes. LifeTrack asks one thing: **did you do it?** Tap = done. Don't tap = skip. Five habits, five taps, done. See your GitHub-style heatmap grow green.

No sign-up. No cloud. No notifications. No stress. No thinking.

---

## The Idea

This project went through three design iterations before landing on the simplest possible version:

- **v1-v5:** Slider 0-10. Users said: *"What's the difference between sleep 7 and sleep 8?"*
- **v6-v7:** Slider 0-5 with text labels. Friend said: *"It looks like something you need to figure out."*
- **v8:** Binary. Tap = did it. That's it.

The insight: **the goal is to build the habit, not measure it.** Success = any progress at all. When the habit is formed, then you can go deeper. But first — just do it. Every day.

**Personal pain:** Health circumstances made it critical to track 5 areas daily. A year of manual journaling proved the concept. No app was simple enough.

First post: [Day 0/30 in Telegram channel](https://t.me/onezee_co)

---

## How It Works

```
Morning routine:

  🛌 Сон          [ — ] → tap → [ ✓ ]
  🚴 Активность   [ — ] → tap → [ ✓ ]
  🥗 Питание      [ — ]
  🧠 Ментальное   [ — ] → tap → [ ✓ ]
  💻 Проекты      [ — ] → tap → [ ✓ ]

  ████████████░░░░ 4/5

  [ Готово ✓ ]

Total time: 5 seconds.
```

Your data becomes a heatmap. Green = did something. Gray = didn't. Today pulses until you check in.

---

## Features

### Check-in Screen
- Tap card to toggle: gray (skip) → green (done)
- Spring scale animation + haptic feedback
- Progress bar: X/N filled
- "Готово" → summary screen
- Check-in available for yesterday (if missed)

### Progress Screen (Drill-down)
- **Year:** 12 month cards with heatmaps (green/gray)
- **Month:** Calendar grid, current & best streaks
- **Week:** Per-habit bars, weekly summary
- **Day:** Detailed view per habit
- **Today:** Pulsing green border
- Filter by individual habit (chips)
- Deleted habits shown only where they have data
- Drill-down navigation: Year → Month → Week → Day

### Habits Management
- Add / edit / delete with confirmation dialog
- Soft-delete preserves check-in history
- Emoji picker (20 presets), max 10 habits
- Drag & drop reorder
- Default: Sleep, Activity, Nutrition, Mental, Projects

### Settings
- Dark/light theme toggle
- About section with project info
- Feedback link (@onezee123 on Telegram)
- Social links (Telegram channel, YouTube)

---

## Tech Stack

```
Framework:   SwiftUI
Language:    Swift
State:       @StateObject + ObservableObject
Storage:     UserDefaults + JSON (Codable)
Animations:  SwiftUI .spring(), withAnimation
Haptics:     UIImpactFeedbackGenerator
Min iOS:     16.0+
Build:       Xcode → App Store Connect
Backend:     None (local-only)
```

---

## Project Structure

```
life-track-ios/
├── lifeTrackIos/
│   ├── LifeTrack/
│   │   ├── LifeTrackApp.swift          # @main entry point
│   │   ├── ContentView.swift           # TabView (3 tabs)
│   │   ├── Models.swift                # Habit, DayStatus
│   │   ├── AppStore.swift              # ObservableObject, UserDefaults persistence
│   │   ├── DateUtils.swift             # Date helpers, Russian locale
│   │   │
│   │   ├── CheckInView.swift           # Daily check-in screen
│   │   ├── HabitToggleCard.swift       # Tap card with spring animation
│   │   │
│   │   ├── ProgressRootView.swift      # Progress container + navigation + filters
│   │   ├── YearProgressView.swift      # Year view (12 mini heatmaps)
│   │   ├── MonthProgressView.swift     # Month calendar grid + streaks
│   │   ├── WeekProgressView.swift      # Week per-habit breakdown
│   │   ├── DayProgressView.swift       # Day detailed view
│   │   │
│   │   ├── HabitsView.swift            # Habit CRUD + drag & drop reorder
│   │   └── SettingsView.swift          # Settings (theme, about, links)
│   └── LifeTrack.xcodeproj
├── mvp/                                # Prototypes and docs (JSX, PRD, tech spec)
├── Makefile                            # Build & submit scripts
└── .gitignore
```

---

## Quick Start

### Prerequisites

- macOS with Xcode 15+
- iOS Simulator or physical iPhone (iOS 16+)
- Apple Developer account (free tier works for simulator)

### Open in Xcode

```bash
git clone https://github.com/OneZee23/life-track-ios.git
cd life-track-ios

make open          # opens lifeTrackIos/LifeTrack.xcodeproj in Xcode
```

Then in Xcode:
1. Select your **Team** in *Signing & Capabilities* (free Apple ID works for simulator)
2. Choose simulator: **iPhone 16 Pro**
3. Press **⌘+R** to build and run

### Build & Submit Scripts

```bash
make run           # build and run on simulator (iPhone 16 Pro)
make open          # open in Xcode

make archive       # create .xcarchive for App Store
make export        # archive + export .ipa
make submit        # upload to App Store Connect (xcrun altool)
make release       # archive + submit in one command

make clean         # remove build artifacts
make help          # list all commands
```

**Env vars for submit:**
```bash
APP_STORE_API_KEY=<your-key-id>
APP_STORE_ISSUER_ID=<your-issuer-id>
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [PRD v3](./mvp/lifetrack-prd.md) | Product requirements, acceptance criteria, design system |
| [Technical Spec](./mvp/lifetrack-tech.md) | Architecture, data model, component design |
| [Prototype](./mvp/lifetrack-mvp.jsx) | Interactive JSX prototype (v8) |

---

## Roadmap

### v0.1.0 MVP (done)

- [x] PRD v1 (0-10) → v2 (0-5) → v3 (binary)
- [x] JSX prototype v1-v8
- [x] User testing at each stage
- [x] Technical specification
- [x] SwiftUI implementation (14 Swift files)
- [x] Binary check-in + tap cards with spring animation
- [x] UserDefaults persistence (JSON/Codable)
- [x] Progress (year/month/week/day) with drill-down navigation
- [x] Habits management (CRUD + drag & drop + soft-delete)
- [x] Settings with about section
- [x] Xcode archive + App Store submission scripts

### v0.2.0 (planned)

- [ ] Push notifications (daily reminder)
- [ ] Onboarding (2-3 screens)
- [ ] iOS widget (today's streak)
- [ ] Export data (CSV/JSON)
- [ ] Streak celebration screen
- [ ] English localization

### v0.3.0 (ideas)

- [ ] Online sync (server + local offline data merge)
- [ ] Apple Watch companion
- [ ] Advanced mode (0-5 scale for power users)
- [ ] Sharing streak cards (Instagram stories)

---

## Design Evolution

| Version | System | Feedback | Decision |
|---------|--------|----------|----------|
| v1-v5 | Slider 0-10 | "What's 7 vs 8?" | Too granular |
| v6-v7 | Slider 0-5 + labels | "Looks complex" | Still too much thinking |
| **v8** | **Binary** | **"Instant. Love it."** | **Ship it** |

---

## Development Format

Open development, "Proof of Work" Season 2:

- All stages documented publicly
- Daily posts in [Telegram channel](https://t.me/onezee_co)
- Season 1: [Telegram Stars Shop](https://github.com/OneZee23/fraggram) (completed)

---

## Links

- **Channel:** [@onezee_co](https://t.me/onezee_co) — daily progress
- **YouTube:** [OneZee](https://www.youtube.com/c/onezee) — video docs
- **Feedback:** [@onezee123](https://t.me/onezee123) — DM for bugs & ideas
- **Android version:** [life-track-android](https://github.com/OneZee23/life-track-android)
- **Season 1:** [Telegram Stars Shop](https://github.com/OneZee23/fraggram)

---

## License

MIT
