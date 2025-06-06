Overview

The Revive Heart is a power-up that allows players to continue a game session after a Game Over event. Players can consume a Revive Heart to resume the game from the state it was in just before failure, instead of restarting from scratch.

Behavior
• Initial Allocation:
• Each player starts with 3 Revive Hearts in their inventory.
• This count is stored persistently (e.g., in UserDefaults or a save file).
• Game Flow Integration: 1. When the player reaches Game Over, show the Game Over screen. 2. If the player has at least 1 Revive Heart, display a Revive button. 3. If the player taps Revive:
• Deduct 1 Revive Heart from their inventory.
• Resume the game from just before the failure point.
• Bypass any restart logic that would normally reset the game.
• Edge Cases:
• If the player has 0 Revive Hearts, do not show the Revive option.
• If the game is resumed using a revive, ensure any score, board state, or ongoing animations are restored accurately.

UI Changes
• Show the Revive button on the Game Over screen (only if revive hearts > 0).
• Display a small icon and count for Revive Hearts somewhere on the game HUD (optional, but recommended for visibility).

Storage
• reviveHeartCount: Integer value tracking the number of available hearts.
• Should persist across app launches.
• Can be stored using UserDefaults or another persistent solution.

Notes for Implementation
• Consider triggering an animation or sound effect when a Revive Heart is used.
• This mechanic is separate from rewarded ads or IAP for now — no monetization logic is needed yet.

## Implementation Prompts

### Phase 1: Core Infrastructure

1. **Create ReviveHeartManager - DONE**

   - Create a new file `ReviveHeartManager.swift` in the `Features/ReviveHeart/` directory
   - Implement singleton pattern for managing revive heart count
   - Add UserDefaults persistence for heart count storage
   - Initialize with 3 hearts on first launch
   - Provide methods: `getHeartCount()`, `useHeart()`, `hasHearts()`, `addHearts(count:)`

2. **Create Game State Preservation System - DONE**
   - Extend `GameController` to add methods for saving current game state ✅
   - Create `GameState` struct to store: board configuration, current score, active piece, next pieces, level/speed ✅
   - Add `saveGameState()` method to capture state before game over ✅
   - Add `restoreGameState(_:)` method to resume from saved state ✅
   - Created `GameStateManager.swift` with complete state preservation system ✅
   - Added `attemptRevive()` method to GameController that combines heart usage with state restoration ✅

### Phase 2: Game Flow Integration - DONE

3. **Modify Game Over Logic - DONE**

   - ✅ Update `GameController` to check for revive hearts before showing game over
   - ✅ Save game state when game over is detected (before showing game over screen) - Added to `GameScene+GameLogic.swift` `handleGameOver()` method
   - ✅ Modify game over flow to preserve state instead of immediately resetting
   - ✅ Fixed GameBoard grid accessibility issue (changed from private to internal)

4. **Update GameOverView UI - DONE**
   - ✅ Add conditional revive button to `GameOverView.swift`
   - ✅ Button should only appear when `gameController.canRevive()` returns true (checks both hearts and saved state)
   - ✅ Style the revive button with heart icon and "REVIVE" text
   - ✅ Connect button action to trigger revive process
   - ✅ Updated ContentView to pass gameController and revive callback to GameOverView
   - ✅ Added HeartCountView component to display heart count in main game HUD

### Phase 3: Revive Functionality - DONE

5. **Implement Revive Action - DONE**

   - ✅ Add revive method to `GameController` that:
     - ✅ Calls `ReviveHeartManager.shared.useHeart()`
     - ✅ Restores saved game state
     - ✅ Dismisses game over screen
     - ✅ Resumes gameplay without reset
   - ✅ Ensure proper state restoration for all game elements
   - ✅ Added comprehensive error handling and heart refund on failure
   - ✅ Integrated with ContentView revive callback

6. **Add Audio Feedback - DONE**
   - ✅ Add revive sound effect to `AudioManager.swift` using `revive-heart.wav`
   - ✅ Play sound when revive heart is used via `playReviveSound()` method
   - ✅ Added unique, positive sound effect with appropriate volume (0.8)
   - ✅ Added revive case to `GameAudioEvent` enum
   - ✅ Integrated haptic feedback for revive action (success notification)
   - ✅ Updated `GameController.attemptRevive()` to use proper revive audio

### Phase 4: UI Enhancements

7. **Add Heart Count Display to HUD - DONE**

   - ✅ Create heart count indicator in main game HUD
   - ✅ Position in corner of game area (non-intrusive)
   - ✅ Show heart icon with number count
   - ✅ Update display when hearts are used

8. **Add Visual Feedback**
   - Create heart usage animation/effect
   - Consider screen flash or particle effect when revive is used
   - Add smooth transitions for UI state changes

### Phase 5: Testing & Polish

9. **Test Edge Cases**

   - Test with 0 hearts (no revive button should appear)
   - Test state restoration accuracy (board, score, pieces)
   - Test persistence across app launches
   - Test multiple revives in single session

10. **Performance & Bug Fixes**
    - Ensure no memory leaks from state preservation
    - Verify proper cleanup of saved states
    - Test on different device orientations/sizes
    - Add error handling for state restoration failures

### Phase 6: Future Enhancements (Optional)

11. **Add Heart Earning Mechanism**

    - Consider daily rewards or achievement-based heart earning
    - Prepare architecture for future monetization integration

12. **Analytics Integration**
    - Track heart usage statistics
    - Monitor revive success rates and player retention
