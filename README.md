# Checklist (iOS)

SwiftUI iOS app project ready to run in the Simulator.

## Prerequisites
- Xcode 14+ (or newer)

## Run in Simulator
- Open `ChecklistApp.xcodeproj` in Xcode.
- Choose an iPhone Simulator (e.g., iPhone 15).
- Press Run (Cmd+R).

## Project Layout
- `ChecklistApp.xcodeproj`: Xcode project for the iOS app.
- `iOSApp/`: SwiftUI app files (`ChecklistApp.swift`, `ContentView.swift`, `Assets.xcassets`, `Info.plist`).
- `Sources/ChecklistCore/ChecklistCore.swift`: App’s core logic, compiled into the app target.

## Signing

Signing settings live in xcconfig files under `ios/Config/`:

- `Base.xcconfig` — committed, sets defaults (`DEVELOPMENT_TEAM =`, `CODE_SIGN_STYLE = Automatic`) and optionally includes `Local.xcconfig`
- `Local.xcconfig` — gitignored, each developer creates from `Local.xcconfig.example` with their own `DEVELOPMENT_TEAM`

To enable signing locally:
```
cp ios/Config/Local.xcconfig.example ios/Config/Local.xcconfig
# Edit Local.xcconfig with your DEVELOPMENT_TEAM
```

## Notes
- This repo is iOS-only. The previous CLI and Swift Package manifest were removed.
