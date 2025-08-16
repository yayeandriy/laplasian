# iOS Share Email Setup Instructions

## Required Xcode Configuration

After implementing the shared components, you need to configure the Xcode project manually to enable App Groups and prepare for the Share Extension.

### 1. Configure App Groups for Main App

1. Open `Laplasian.xcodeproj` in Xcode
2. Select the `Laplasian` target
3. Go to "Signing & Capabilities" tab
4. Click the "+" button to add a capability
5. Add "App Groups" capability
6. Click the "+" button in the App Groups section
7. Add the group: `group.operators.yayeandriy.Laplasian`
8. Ensure the entitlements file `Laplasian.entitlements` is linked to the target

### 2. Verify Entitlements File

1. In the project navigator, ensure `Laplasian.entitlements` is added to the project
2. In target settings, verify "Code Signing Entitlements" points to `Laplasian/Laplasian.entitlements`

### 3. Update Bundle Identifier (if needed)

The current bundle identifier is `operators.yayeandriy.Laplasian`. The App Group identifier is based on this:
- App Group: `group.operators.yayeandriy.Laplasian`

If you change the bundle identifier, update the App Group identifier in:
- `SharedStorage.swift` (appGroupIdentifier property)
- `Laplasian.entitlements` file

### 4. Prepare for Share Extension (Next Task)

When adding the Share Extension target later, you'll need to:
1. Use bundle identifier: `operators.yayeandriy.Laplasian.ShareExtension`
2. Add the same App Groups capability to the extension target
3. Create separate entitlements file for the extension

## Project Structure Created

```
Laplasian/
├── Models/
│   ├── EmailConfiguration.swift     # Shared configuration model
│   ├── SharedContent.swift          # Content type definitions
│   └── ShareEmailError.swift        # Error handling
├── Storage/
│   └── SharedStorage.swift          # App Group storage management
├── Managers/
│   └── SettingsManager.swift        # Configuration coordination
└── Laplasian.entitlements          # App Groups entitlements
```

## Testing App Groups

You can test if App Groups are working correctly by:

1. Build and run the app
2. Create a SettingsManager instance
3. Try saving a configuration
4. Check if the shared container is accessible

The SharedStorage class includes error handling for App Group access failures.

## Next Steps

After completing the Xcode configuration:
1. Build the project to ensure no compilation errors
2. Test the SharedStorage functionality
3. Proceed to implement the next tasks in the implementation plan