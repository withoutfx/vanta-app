# Vanta App - AI Agent Instructions

## Project Overview

**Vanta** is an exclusive video feed Flutter application with admin-controlled user approval. Built with Firebase (Auth, Firestore, Storage) and supports Android, iOS, Windows, Linux, and macOS.

## Architecture

### Core Flow
1. **AuthGate** ([lib/screens/auth_gate.dart](lib/screens/auth_gate.dart)) - Entry point that routes based on auth state:
   - No user → "Belum login" message
   - Unapproved user → [WaitingScreen](lib/screens/waiting_screen.dart) (approval pending)
   - Approved user → [VideoFeedScreen](lib/screens/video_feed_screen.dart)

2. **Service Layer** - Centralized Firebase operations:
   - [AuthService](lib/services/auth_service.dart) handles registration, creates `users/{uid}` doc with `isApproved: false` by default
   - Models: [AppUser](lib/models/user_model.dart) provides `toMap()`/`fromMap()` for serialization

3. **Data Model**
   - Users: `users/{uid}` docs with `email`, `isApproved` (boolean), `createdAt` (server timestamp)
   - Videos: `videos` collection with `url`, `createdAt` (sort descending)

### Key Design Patterns
- **Firebase-First State**: No local state management (Provider/Riverpod). UI reacts to Firebase queries directly via `FutureBuilder`/`StreamBuilder`
- **Approval Gate**: All new users start with `isApproved: false`. Admin manually updates this in Firestore to unlock VideoFeedScreen
- **Vertical PageView**: VideoFeedScreen uses `PageView.builder(scrollDirection: Axis.vertical)` for TikTok-style vertical video feed

## Critical Development Workflows

### Build & Run
```bash
# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run with specific flavor (if configured)
flutter run --debug
```

### Debugging
- **Firebase Connection Issues**: Check `google-services.json` (Android) and iOS configuration. Run `flutter pub get` if dependencies are stale.
- **Video Stream Empty**: Ensure `videos` collection exists in Firestore and has documents with valid `url` and `createdAt` fields
- **Approval Not Updating**: Manually edit Firestore user document: `db → users/{uid} → set isApproved to true`

## Project-Specific Conventions

1. **Async/await everywhere** - No async utils, use native Dart Future/Stream patterns
2. **Firestore collection naming**: lowercase, plural (`users`, `videos`)
3. **Timestamps**: Use `FieldValue.serverTimestamp()` for consistency across devices
4. **Localized strings**: Code includes Indonesian comments (e.g., "Belum login", "🔥 INI KUNCINYA") - preserve tone if updating UI text
5. **Dark theme only** - `ThemeData.dark()` hardcoded, no light mode support

## Key Dependencies

| Package | Version | Usage |
|---------|---------|-------|
| `firebase_core` | ^2.24.0 | Firebase initialization |
| `firebase_auth` | ^4.15.0 | Email/password auth |
| `cloud_firestore` | ^4.13.0 | Real-time database |
| `firebase_storage` | ^11.5.0 | Video/media storage |
| `video_player` | ^2.8.2 | Video playback |
| `image_picker` | ^1.0.4 | Photo/video selection |

## Integration Points

- **Firebase Config**: Android (`android/app/google-services.json`), iOS (pod/config), Windows/Linux/macOS (see `firebase_core` platform setup)
- **Video URLs**: Expected to be publicly accessible URLs stored in Firestore `videos.url` (usually Firebase Storage URLs)
- **Approval Workflow**: Admin triggers approval by changing `users/{uid}.isApproved` to `true` in Firestore console

## Files to Know

- **Entry Point**: [lib/main.dart](lib/main.dart) - initializes Firebase before `runApp()`
- **Auth Logic**: [lib/services/auth_service.dart](lib/services/auth_service.dart) - registration creates unapproved users
- **Navigation**: [lib/screens/auth_gate.dart](lib/screens/auth_gate.dart) - single source of routing truth
- **Video Feed**: [lib/screens/video_feed_screen.dart](lib/screens/video_feed_screen.dart) - streams and displays videos vertically
- **Models**: [lib/models/user_model.dart](lib/models/user_model.dart) - AppUser serialization

## Testing Notes

- No unit/widget tests currently configured (empty `test/` directory)
- Test Firebase rules locally before deploying if access control changes
- Approval gate flows require Firestore setup: create test user doc, toggle `isApproved`, verify navigation

## Common Tasks

- **Add new screen**: Create in `lib/screens/`, update AuthGate routing
- **Add Firestore collection**: Define in `AuthService` or relevant service, query via `StreamBuilder`
- **Extend approval logic**: Modify `checkApproval()` in AuthGate; consider adding roles or permissions in user doc
- **Video playback customization**: Extend `VideoPlayerWidget` in video_feed_screen.dart
