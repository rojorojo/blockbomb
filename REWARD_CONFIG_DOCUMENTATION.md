# RewardConfig System Documentation

## Overview

The RewardConfig system provides a comprehensive configuration management solution for the Block Puzzle Game's reward economy. It enables real-time tuning of game balance parameters, persistent storage, and easy deployment of configuration changes.

## Architecture

### Core Components

1. **RewardConfig.swift** - Main configuration manager (singleton)
2. **RewardConfigDebugView.swift** - Debug interface for live editing
3. **Configuration Integration** - Seamless integration with existing game systems
4. **JSON Support** - Import/export for server-side configuration management

### Key Features

- ✅ **12 Configurable Parameters** covering currency, powerups, and advertising
- ✅ **Real-time Updates** with notification system for dependent managers
- ✅ **Persistent Storage** using UserDefaults with JSON backup
- ✅ **Validation System** with range checking and fallback values
- ✅ **Debug Interface** integrated into existing debug panel
- ✅ **Preset Management** for quick switching between configurations

## Configuration Parameters

### Currency Configuration

| Parameter                | Default | Description                              | Range  |
| ------------------------ | ------- | ---------------------------------------- | ------ |
| `pointsPerAd`            | 10      | Points awarded for watching rewarded ads | 1-100  |
| `defaultPointBalance`    | 0       | Starting point balance for new players   | 0-1000 |
| `adWatchBonusMultiplier` | 1       | Multiplier for bonus rewards from ads    | 1-10   |
| `firstTimePlayerBonus`   | 50      | Bonus points for first-time players      | 0-200  |
| `dailyBonusPoints`       | 10      | Daily login bonus points                 | 0-100  |

### Powerup Configuration

| Parameter           | Default | Description                               | Range |
| ------------------- | ------- | ----------------------------------------- | ----- |
| `reviveHeartPrice`  | 20      | Cost in points to purchase a revive heart | 1-500 |
| `futureBonus1Price` | 50      | Cost for future bonus powerup 1           | 1-500 |
| `futureBonus2Price` | 100     | Cost for future bonus powerup 2           | 1-500 |
| `futureBonus3Price` | 200     | Cost for future bonus powerup 3           | 1-500 |

### Advertising Configuration

| Parameter                   | Default | Description                                     | Range   |
| --------------------------- | ------- | ----------------------------------------------- | ------- |
| `gamesBetweenInterstitials` | 2       | Number of games before showing interstitial ads | 1-20    |
| `bonusAdCooldownSeconds`    | 120     | Cooldown time between bonus ad opportunities    | 30-3600 |
| `minGameDurationForAd`      | 30      | Minimum game duration before showing ads        | 10-300  |

## Usage

### Basic Configuration Access

```swift
// Get current configuration values
let config = RewardConfig.shared
let pointsPerAd = config.pointsPerAd
let heartPrice = config.reviveHeartPrice

// Set configuration values
config.setValue(15, for: .pointsPerAd)
config.setValue(25, for: .reviveHeartPrice)

// Reset to defaults
config.resetToDefault(key: .pointsPerAd)
config.resetAllToDefaults()
```

### System Integration

The configuration system automatically notifies dependent managers when values change:

```swift
// PowerupCurrencyManager automatically updates when currency config changes
// PowerupShopManager automatically refreshes prices when powerup config changes
// AdTimingManager automatically adjusts timing when advertising config changes
```

### Debug Interface

Access the debug configuration panel:

1. Open Debug Panel in app
2. Navigate to "Reward Configuration" section
3. Tap "Open Config Panel" for live editing interface

### JSON Configuration

```swift
// Export current configuration
if let jsonData = config.exportConfiguration() {
    // Save or send to server
}

// Import configuration from server
let success = config.importConfiguration(from: jsonData)
```

## Integration with Existing Systems

### PowerupCurrencyManager

- Automatically uses `pointsPerAd` for reward calculations
- Respects `defaultPointBalance` for new players
- Listens for currency configuration changes

### PowerupShopManager

- Dynamically uses powerup prices from configuration
- Updates shop display when prices change
- Maintains compatibility with existing purchase flow

### AdTimingManager

- Uses `gamesBetweenInterstitials` for ad frequency
- Respects `bonusAdCooldownSeconds` for ad timing
- Adapts to configuration changes in real-time

## Configuration Presets

### Production Preset

- Conservative values for live environment
- `pointsPerAd`: 10, `reviveHeartPrice`: 20
- `gamesBetweenInterstitials`: 3, `bonusAdCooldownSeconds`: 180

### Testing Preset

- Generous values for development and testing
- `pointsPerAd`: 20, `reviveHeartPrice`: 15
- `gamesBetweenInterstitials`: 1, `bonusAdCooldownSeconds`: 30

## Server-Side Configuration

### JSON Format

```json
{
  "version": "1.0",
  "timestamp": "2025-06-11T10:00:00Z",
  "configurations": {
    "RewardConfig.pointsPerAd": 15,
    "RewardConfig.reviveHeartPrice": 25,
    "RewardConfig.gamesBetweenInterstitials": 3
  },
  "metadata": {
    "description": "Updated configuration for holiday event",
    "author": "Game Balance Team",
    "environment": "production"
  }
}
```

### Implementation Steps

1. **Server Endpoint**: Create endpoint to serve configuration JSON
2. **Version Control**: Implement configuration versioning for compatibility
3. **Gradual Rollout**: Deploy configuration changes to percentage of users
4. **Monitoring**: Track impact of configuration changes on key metrics

## Best Practices

### Configuration Management

- Test configuration changes in development environment first
- Use gradual rollout for production configuration changes
- Monitor key metrics (retention, monetization) after changes
- Keep configuration changes documented and reversible

### Performance Considerations

- Configuration loading happens once on app launch
- Changes are applied immediately without app restart
- UserDefaults persistence is lightweight and efficient
- JSON operations are performed off main thread

### Privacy and Security

- All configuration data is stored locally on device
- No personal information is included in configuration
- Server configuration is optional and privacy-compliant
- Users can reset to defaults at any time

## Testing

The system includes comprehensive test coverage:

- **Unit Tests**: All configuration operations and validation
- **Integration Tests**: System interaction and notification handling
- **Debug Tests**: Preset application and JSON serialization
- **Edge Case Tests**: Invalid values and error conditions

Run tests with:

```bash
xcodebuild test -scheme blockbomb -destination 'platform=iOS Simulator,name=iPhone 14'
```

## Troubleshooting

### Common Issues

1. **Configuration not persisting**

   - Check UserDefaults permissions
   - Verify configuration keys are correct
   - Ensure values are within valid ranges

2. **Debug panel not showing**

   - Confirm DEBUG build configuration
   - Check that RewardConfigDebugView is properly imported
   - Verify debug panel integration

3. **Systems not updating**
   - Check notification observer setup
   - Verify manager initialization order
   - Confirm configuration change notifications are being sent

### Debug Commands

```swift
// Check current configuration state
RewardConfig.shared.debugValidateAllValues()

// Test JSON serialization
RewardConfig.shared.debugTestJSONSerialization()

// Apply test configuration
RewardConfig.shared.debugApplyTestPreset()

// Reset everything
RewardConfig.shared.resetAllToDefaults()
```

## Future Enhancements

### Planned Features

- **A/B Testing**: Support for configuration experiments
- **Analytics Integration**: Track configuration impact on player behavior
- **Remote Configuration**: Server-side configuration management
- **Configuration History**: Track and rollback configuration changes

### Extension Points

- **Custom Validators**: Add specific validation rules per parameter
- **Configuration Groups**: Organize related parameters into groups
- **User Preferences**: Allow players to customize certain parameters
- **Dynamic Ranges**: Adjust valid ranges based on player progression

## Conclusion

The RewardConfig system provides a robust foundation for game balance management while maintaining the flexibility needed for ongoing optimization. Its integration with existing systems ensures seamless operation while providing powerful tools for real-time configuration management.

The system is designed to scale with the game's growth, supporting both manual configuration changes and future automated optimization systems.
