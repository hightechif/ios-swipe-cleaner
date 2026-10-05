# SwipeCleaner for iOS

Swipe right to keep a photo, swipe left to queue it for deletion. Queued photos are deleted in one batch behind the system confirmation alert and land in *Recently Deleted*.

iOS port of the Android app in `../SwipeCleaner`. Behaviour is specified in `../openspec/specs/` (see the `add-ios-swipecleaner` change).

## Requirements

- Xcode 27 (project format `objectVersion 90`, folder-synchronized groups)
- iPhone only, deployment target **iOS 15.0**
- Swift Package dependency: [lottie-ios](https://github.com/airbnb/lottie-ios) (resolved automatically)

## Build, run, test

```bash
# Build for a simulator
xcodebuild -project iOSSwipeCleaner.xcodeproj -scheme iOSSwipeCleaner \
  -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO
```

```bash
# Run all unit tests
xcodebuild -project iOSSwipeCleaner.xcodeproj -scheme iOSSwipeCleaner \
  -destination 'platform=iOS Simulator,name=iPhone 17' test CODE_SIGNING_ALLOWED=NO
```

```bash
# Run one test class
xcodebuild -project iOSSwipeCleaner.xcodeproj -scheme iOSSwipeCleaner \
  -destination 'platform=iOS Simulator,name=iPhone 17' test CODE_SIGNING_ALLOWED=NO \
  -only-testing:iOSSwipeCleanerTests/SwipeViewModelTests
```

To try the app on a simulator you need photos in its library. Add some from the command line:

```bash
xcrun simctl addmedia booted path/to/*.jpg
```

Simulators have no user albums; favourite a photo in the Photos app to get a *Favorites* album in the folder selector.

## Layout

```
iOSSwipeCleaner/
  App/          SwipeCleanerApp, AppContainer (composition root), RootView, LibrarySyncCoordinator
  Domain/       Models, repository protocols, use cases (no PhotoKit / Core Data)
  Data/         PhotoKit repository + auth service + image loader, Core Data store and repositories
  UI/           Theme, Features/{Permission,Main,Swipe,Kept,Trash}, Components
  Resources/    completion_animation.json (Lottie confetti)
iOSSwipeCleanerTests/   mirrors the source tree; fakes in Fakes/
Config/Info.plist       extra Info.plist keys merged into the generated plist
```

## Notes

- **Persistence** is Core Data (`Data/Persistence/SwipeCleaner.xcdatamodeld`), not SwiftData, because SwiftData needs iOS 17. Add new model versions instead of editing the current one so user progress survives upgrades.
- **iOS 15 APIs only.** No `@Observable`, `NavigationStack` or sheet detents. The compiler enforces availability against the deployment target.
- **PhotosUI is linked explicitly** (`OTHER_LDFLAGS`). `presentLimitedLibraryPicker` is an Objective-C category method; without the explicit link the selector is missing at runtime and the app crashes.
- **Limited access:** records for photos outside the user's selection are never pruned or dropped; deletion only removes photos the library reports as deleted.
- The app does not start PhotoKit or Core Data when hosted by unit tests (`XCTestConfigurationFilePath` is set).
