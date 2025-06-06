# Revive Heart System - Manual Testing Guide

## Overview

This guide provides step-by-step instructions for manually testing the revive heart system functionality in the BlockBomb iOS game.

## Pre-Testing Setup

### 1. Initial State Verification

- Launch the app for the first time
- Verify that 3 hearts are displayed in the HUD (top area of the game screen)
- Confirm the heart count indicator shows "♥ 3"

### 2. Debug Commands (Development Builds Only)

Use these methods in the debugger console if needed:

```swift
// Set specific heart count
ReviveHeartManager.shared.debugSetHearts(5)

// Clear UserDefaults and reset to default
ReviveHeartManager.shared.debugClearUserDefaults()

// Check current heart count
print(ReviveHeartManager.shared.getHeartCount())
```

## Core Functionality Tests

### Test 1: Basic Heart Management

**Objective**: Verify heart counting and persistence

1. **Initial Hearts Check**

   - Launch app
   - Verify HUD shows 3 hearts
   - Expected: Heart count display shows "♥ 3"

2. **Heart Usage Simulation**

   - Use debug commands to test heart decrement
   - Expected: Heart count decreases correctly

3. **Persistence Test**
   - Use some hearts
   - Close and relaunch app
   - Expected: Heart count persists between sessions

### Test 2: Game Over Flow

**Objective**: Test revive button appearance and functionality

1. **Setup Game Over State**

   - Start a new game
   - Play until game over occurs (intentionally lose)
   - Expected: Game over screen appears

2. **Revive Button Visibility**

   - With hearts available (> 0): Revive button should appear
   - With no hearts (= 0): Revive button should NOT appear
   - Expected: Button visibility matches heart availability

3. **Revive Button Styling**
   - Button should display heart icon and "REVIVE" text
   - Should show current heart count
   - Expected: Professional, themed appearance

### Test 3: Revive Functionality

**Objective**: Test actual game state restoration

1. **Pre-Revive Setup**

   - Play game to build score (e.g., 500+ points)
   - Place some pieces on the board
   - Note current score and board state
   - Trigger game over

2. **Execute Revive**

   - Tap "REVIVE" button on game over screen
   - Expected:
     - Heart count decreases by 1
     - Game resumes with previous score
     - Board state restored exactly
     - Pieces in selection area restored
     - Revive animation plays
     - Revive sound effect plays

3. **Post-Revive Verification**
   - Score matches pre-game-over score
   - Board layout identical to before game over
   - Game continues normally
   - Expected: Seamless continuation of gameplay

### Test 4: Audio and Visual Feedback

**Objective**: Verify multimedia feedback

1. **Audio Test**

   - Ensure device volume is up
   - Trigger revive
   - Expected: "revive-heart" sound plays at 80% volume

2. **Animation Test**

   - Trigger revive
   - Expected: Heart animation sequence plays (20 frames)
   - Screen flash effect occurs
   - Animation completes smoothly

3. **Haptic Feedback Test** (iOS devices only)
   - Trigger revive
   - Expected: Success haptic notification

### Test 5: Edge Cases

**Objective**: Test boundary conditions and error states

1. **No Hearts Available**

   - Use all hearts (set to 0 with debug commands)
   - Trigger game over
   - Expected: No revive button appears

2. **Expired Game State**

   - Save game state
   - Wait 6+ minutes (or modify timestamp in debugger)
   - Attempt revive
   - Expected: Revive fails gracefully, heart refunded

3. **Multiple Revives in Session**

   - Revive game successfully
   - Trigger game over again
   - Attempt second revive
   - Expected: Works correctly until hearts exhausted

4. **Heart Refund on Failure**
   - Force a restoration failure (disconnect game scene)
   - Attempt revive
   - Expected: Heart count restored, user notified of failure

## Integration Tests

### Test 6: Full Game Flow

**Objective**: Test complete user journey

1. **New User Experience**

   - Fresh install/first launch
   - Play through several games
   - Use revive feature
   - Expected: Smooth onboarding experience

2. **Extended Session**

   - Play multiple games in one session
   - Use revives strategically
   - Expected: System remains stable

3. **App Lifecycle**
   - Use hearts, background app, foreground app
   - Force quit and relaunch
   - Expected: State persists correctly

## Performance Tests

### Test 7: Memory and Performance

**Objective**: Verify system efficiency

1. **Memory Usage**

   - Monitor memory during revive
   - Check for leaks in Instruments
   - Expected: No memory leaks

2. **Save/Restore Performance**
   - Time state capture and restoration
   - Test with complex board states
   - Expected: < 100ms for state operations

## Success Criteria

### ✅ Core Functionality

- [ ] Hearts initialize to 3 on first launch
- [ ] Heart count persists across app sessions
- [ ] Revive button appears only when hearts available
- [ ] Game state restores accurately after revive
- [ ] Heart count decrements correctly when used

### ✅ User Experience

- [ ] Revive animation plays smoothly
- [ ] Audio feedback provides appropriate sound
- [ ] Haptic feedback enhances experience
- [ ] UI is intuitive and well-styled

### ✅ Edge Cases

- [ ] No crashes when hearts exhausted
- [ ] Expired states handled gracefully
- [ ] Failed restorations refund hearts
- [ ] Multiple revives work correctly

### ✅ Integration

- [ ] No conflicts with existing game systems
- [ ] Maintains performance standards
- [ ] Works across different device types

## Troubleshooting

### Common Issues

1. **Heart count not persisting**: Check UserDefaults implementation
2. **Revive button not appearing**: Verify `canRevive()` logic
3. **State not restoring**: Check GameStateManager validity
4. **Audio not playing**: Verify asset loading and volume settings

### Debug Information

Monitor console output for detailed logging from:

- `ReviveHeartManager`: Heart operations
- `GameStateManager`: State capture/restoration
- `GameController`: Revive attempts
- `AudioManager`: Sound playback

## Test Report Template

```
Date: ___________
Tester: ___________
Build: ___________

Test Results:
- Basic Heart Management: PASS/FAIL
- Game Over Flow: PASS/FAIL
- Revive Functionality: PASS/FAIL
- Audio/Visual Feedback: PASS/FAIL
- Edge Cases: PASS/FAIL
- Integration: PASS/FAIL
- Performance: PASS/FAIL

Issues Found:
1. _________________
2. _________________

Overall Assessment: PASS/FAIL

Notes:
_________________________________
```

## Next Steps

After successful manual testing, the revive heart system is ready for:

1. Beta testing with real users
2. Performance optimization if needed
3. Analytics integration for usage tracking
4. Future enhancements (daily rewards, IAP integration)
