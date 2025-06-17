# Google AdMob Integration Instructions

## Adding Google Mobile Ads SDK

### Step 1: Add Swift Package Dependency

1. Open `blockbomb.xcodeproj` in Xcode
2. Go to **File** → **Add Package Dependencies...**
3. Enter the URL: `https://github.com/googleads/swift-package-manager-google-mobile-ads.git`
4. Select **Up to Next Major** version rule
5. Click **Add Package**
6. Select **GoogleMobileAds** target and click **Add Package**

### Step 2: Update Info.plist

Add the following to your `Info.plist` file:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
<key>NSUserTrackingUsageDescription</key>
<string>This app would like to track you across other apps to provide personalized ads that support free gameplay.</string>
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    <!-- Add more SKAdNetwork IDs as needed -->
</array>
```

### Step 3: Test Ad Unit IDs

The AdManager is currently configured with Google's test ad unit IDs:

- **Interstitial**: `ca-app-pub-3940256099942544/4411468910`
- **Rewarded**: `ca-app-pub-3940256099942544/1712485313`

### Step 4: Production Ad Unit IDs

When ready for production:

1. Create a Google AdMob account
2. Set up your app in AdMob console
3. Generate real ad unit IDs
4. Replace test IDs in `AdManager.swift`

### Step 5: Privacy Compliance

The AdManager includes:

- App Tracking Transparency (ATT) support
- GDPR compliance ready
- Graceful fallbacks for ad failures

## Usage Example

```swift
// Show rewarded ad for coins
AdManager.shared.showRewardedAd(from: viewController) { success, points in
    if success {
        PowerupCurrencyManager.shared.addPoints(points)
    }
}
```

## Testing

- Use test ads during development
- Test with airplane mode for fallback scenarios
- Verify privacy permissions work correctly
