# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI跑步教练 (AIRunningCoach) - A GPS-based AI running coach iOS app built with SwiftUI. Users track runs, earn achievements, and receive real-time voice coaching from an AI assistant.

## Technology Stack

- **Framework**: SwiftUI (iOS 16.0+)
- **Language**: Swift 5.9+ (using async/await, @MainActor)
- **Maps**: Apple MapKit
- **Backend**: Supabase (PostgreSQL + PostGIS + Realtime)
- **Auth**: Supabase Auth + Apple Sign In
- **Speech**: AVSpeechSynthesizer
- **Architecture**: MVVM with Manager pattern
- **Project Management**: XcodeGen (project.yml)
- **Bundle ID**: com.zhouxiaohong.AIRunningCoach

## Build & Development

### Critical: XcodeGen Workflow

**IMPORTANT**: This project uses XcodeGen. After adding or renaming ANY file, you MUST regenerate the Xcode project:

```bash
# 1. Regenerate project (required after any file changes)
xcodegen generate

# 2. Build for simulator
xcodebuild -scheme AIRunningCoach -sdk iphonesimulator -quiet

# 3. Run tests
xcodebuild test -scheme AIRunningCoach -sdk iphonesimulator -quiet
```

**Note**: In Xcode, you can directly `Cmd+R` to run. Forgetting `xcodegen generate` after adding files will cause build failures.

### Project Structure

```
AIRunningCoach/
├── Views/               - SwiftUI views (15 files)
├── Managers/            - Business logic managers (5 files)
│   ├── AuthManager.swift       - Supabase auth & Apple Sign In
│   ├── LocationManager.swift   - GPS tracking & route recording
│   ├── RunDataManager.swift    - Run records CRUD & cloud sync
│   ├── SpeechManager.swift     - Voice feedback with AVSpeechSynthesizer
│   └── AIManager.swift         - AI coach feedback
├── Models/              - Data models (2 files)
│   ├── RunRecord.swift         - Run record data model
│   └── TrainingPlan.swift      - Training plan model
├── Utils/               - Utilities
│   └── CoordinateConverter.swift
├── Assets.xcassets      - Image assets
├── project.yml          - XcodeGen configuration
└── AIRunningCoachApp.swift - App entry point
```

**File Statistics** (as of 2026-01-27):
- Total Swift files: 43
- Total lines of code: ~9,338
- Views: 15 files
- Managers: 5 files
- Models: 2 files

## App Architecture

```
AI跑步教练App (@main)
└── Root conditional view based on auth state
    ├── LoginView (unauthenticated)
    └── HomeView (authenticated)
        └── Custom TabBar (4 tabs, selectedTab state)
            ├── Tab 0: homeContent     - Start run + weekly goals
            ├── Tab 1: TrainingPlanView - Training plans
            ├── Tab 2: HistoryView      - Run history
            └── Tab 3: SettingsView     - User settings
```

### Key Navigation Flow

- **App Entry** (`AIRunningCoachApp.swift`): Checks `AuthManager.shared.isAuthenticated`
  - If authenticated → `HomeView`
  - If not → `LoginView`
- **HomeView**: Custom bottom TabBar with manual state management (`selectedTab`)
  - **NOT using TabView** - uses ZStack + switch statement for tab content
  - "开始跑步" button → `NavigationLink` to `ActiveRunView`
- **ActiveRunView**: Core running experience
  - Uses 4 managers: `LocationManager`, `RunDataManager`, `SpeechManager`, `AIManager`
  - Map background (`RunMapView`) with real-time GPS tracking
  - Voice coaching triggered by distance/time milestones
  - On finish → `RunSummaryView`

### Manager Pattern

All managers are **singletons** accessed via `.shared`:

- `AuthManager.shared` - Auth state, login, signup, Apple Sign In
- `LocationManager()` - GPS tracking (instantiated per view, **NOT** singleton)
- `RunDataManager.shared` - Local + cloud persistence
- `SpeechManager.shared` - Voice feedback queue with priority system
- `AIManager.shared` - AI coaching feedback

**Important**: `LocationManager` is instantiated as `@StateObject` in views, not a singleton.

## Code Standards

### File Naming

- Views: `XxxView.swift` (e.g., `ActiveRunView.swift`)
- Managers: `XxxManager.swift` (e.g., `LocationManager.swift`)
- Models: In `Models/` directory (e.g., `RunRecord.swift`)
- Utils: In `Utils/` directory (e.g., `CoordinateConverter.swift`)

### Colors & Design System

**CRITICAL**: No `RunningTheme` exists yet. Colors are currently **hardcoded inline**.

Current color pattern (found throughout views):
```swift
Color(red: 0.5, green: 0.8, blue: 0.1)  // Primary green (used everywhere)
```

**Design Guidelines**:
- Primary color: Green tone `Color(red: 0.5, green: 0.8, blue: 0.1)`
- Avoid shadow and blur effects (GPU intensive)
- Use SF Symbols for icons
- File size limit: **300 lines per view** (split into subviews at 200+ lines)

### Localization

- All user-facing text should use localization (currently **not implemented**)
- Planned: `L("key")` or `LocalizedStringKey`
- Locale: `zh-Hans.lproj/Localizable.strings`

### SwiftUI Conventions

- Every view file **must** include `#Preview` macro
- Use `@MainActor` for managers with `@Published` properties
- Prefer `async/await` over completion handlers
- Use `@StateObject` for manager instantiation in views
- Use `@ObservedObject` for passed-in managers

## Supabase Integration

### Configuration

- MCP config: `.mcp.json` (gitignored)
- Supabase client setup: Defined in managers (AuthManager, RunDataManager)
- Database tables: `users`, `run_records` (with PostGIS spatial indexing)
- RLS (Row Level Security) enabled

### Data Sync Strategy

`RunDataManager` implements **local-first with cloud sync**:
1. All operations write to `UserDefaults` first (immediate feedback)
2. If authenticated, sync to Supabase asynchronously
3. `syncedToCloud` flag tracks sync status on each `RunRecord`

## GPS & Location Tracking

### LocationManager Implementation

Located in `Managers/LocationManager.swift`. Key features:

- **Activity Type**: `.fitness` for optimized battery + accuracy
- **Distance Filter**: 5 meters (updates every 5m of movement)
- **Desired Accuracy**: `kCLLocationAccuracyBest`
- **GPS Filtering** (critical for accurate distance):
  - Min horizontal accuracy: 50m (rejects low-quality GPS)
  - Min movement distance: 8m (filters GPS drift)
  - Min speed: 0.8 m/s (filters stationary noise)
  - Max jump distance: 100m (filters GPS teleports)

**Important**: `LocationManager` is **not** a singleton - instantiated per view with `@StateObject`.

### Coordinate Handling

- `routeCoordinates: [CLLocationCoordinate2D]` - stores GPS path
- `pathUpdateVersion: Int` - triggers map redraw (increments on new points)
- `Utils/CoordinateConverter.swift` - handles coordinate transformations if needed

## Voice Coaching System

### SpeechManager (`Managers/SpeechManager.swift`)

**Singleton** with priority-based queue system:

```swift
enum SpeechPriority {
    case low      // General tips
    case normal   // Regular feedback
    case high     // Important reminders
    case urgent   // Immediate playback (interrupts current)
}
```

**Key Methods**:
- `speak(_:priority:)` - Queue text for TTS
- `announceDistance(_:)` - Auto-format km/m announcement
- `announcePace(_:)` - Current pace announcement
- `announceStart()`, `announcePause()`, `announceResume()`, `announceFinish()` - Pre-defined messages

**Usage in ActiveRunView**:
- Distance milestones (every 0.5km): triggered by comparing `lastAnnouncedKm`
- AI feedback: every 30 seconds via `AIManager.shared.provideFeedback()`

**Audio Session**: Uses `.playback` category with `.mixWithOthers` and `.duckOthers` options.

## Training Plans

Managed in `Models/TrainingPlan.swift` and displayed in `Views/TrainingPlanView.swift`.

**Current Plan**: 3km beginner goal
- View switching: All plans / My plan
- Week-by-week progression display
- Integration with `HomeView` weekly goal card

## Common Tasks

### Adding a New View

1. Create `Views/NewView.swift`
2. **Run `xcodegen generate`** (critical!)
3. Add `#Preview` macro
4. Follow 300-line file size limit
5. Use existing color patterns: `Color(red: 0.5, green: 0.8, blue: 0.1)`

### Adding a New Manager

1. Create `Managers/NewManager.swift`
2. **Run `xcodegen generate`** (critical!)
3. Use `@MainActor` if it has `@Published` properties
4. Consider singleton pattern (`static let shared`)
5. Add to relevant views via `@StateObject` or `@ObservedObject`

### Working with GPS Data

1. Access via `LocationManager` instance (not `.shared`)
2. Read `routeCoordinates` for path data
3. Subscribe to `distance`, `currentPace`, `duration` via `@Published`
4. Remember: filtering parameters are tuned for running (see GPS section above)

### Triggering Voice Feedback

```swift
// Simple announcement
SpeechManager.shared.speak("Your message", priority: .normal)

// Pre-defined announcements
SpeechManager.shared.announceDistance(distanceKm)
SpeechManager.shared.announcePace(paceMinPerKm)

// AI coaching (automatic via AIManager)
let feedback = await AIManager.shared.provideFeedback(distance: ..., pace: ...)
```

## Testing & Debugging

### Supabase Testing

- `Views/SupabaseTestView.swift` - Debug view for testing Supabase connectivity
- Access via debug navigation (not in production flow)

### Location Simulation

- Use Xcode's location simulation: Debug → Simulate Location
- Recommended: "City Run" or "Freeway Drive" for realistic GPS paths

### Voice Testing

- Toggle voice with microphone button in `ActiveRunView` (top-right)
- Check `SpeechManager.isEnabled` state
- Console logs: Look for `🎤` and `🔊` emojis

## Important Notes

### File Organization

**Current State** (approaching thresholds):
- Views: 15 files ✅ (threshold: 20 → add `Views/CLAUDE.md`)
- Managers: 5 files ✅ (threshold: 10 → add `Managers/CLAUDE.md`)
- Models: 2 files ✅ (threshold: 10 → add `Models/CLAUDE.md`)
- Total LOC: ~9,338 ✅ (threshold: 10,000 → comprehensive spec refinement)

**Action Items When Thresholds Hit**:
- Add subdirectory-specific CLAUDE.md files for detailed architectural docs
- Consider splitting large managers (e.g., `LocationManager` at 187 lines is healthy)

### Known Limitations

- **No theme system**: Colors hardcoded (should create `Theme/RunningTheme.swift`)
- **No localization**: Chinese text hardcoded in views
- **No test coverage**: No unit tests or UI tests yet
- **UserDefaults for persistence**: Consider CoreData/SwiftData for larger datasets

### Migration Notes

This project reuses 95% of code from the "地球新主" (EarthLord) project. See `功能复用规划.md` for details.

## Development Team

- **Team ID**: PW83W8JG6H
- **Created**: 2026-01-21
- **Primary Language**: Chinese (zh-CN)
- **Project Owner**: 周晓红 (zhouxiaohong)
