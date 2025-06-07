# Quick Test Reference - Game Over Bug

## Immediate Action Items

### 1. Test the Enhanced Debug System

Run the app in Xcode and look for these new debug buttons at the bottom of the screen:

- **"Test Bug Scenario"** (Red) - Tests the exact reported bug
- **"Test Game Over"** (Orange) - General game over testing
- **"Nearly Full Board"** (Yellow) - Manual testing
- **"Reset Hearts"** (Red) - Reset revive hearts

### 2. Primary Test Case - "Test Bug Scenario" Button

**This is the most important test** - it recreates exactly what the user reported:

1. **Tap "Test Bug Scenario"**
2. **Watch Console Output** for debug information
3. **Expected Outcome**: Game over should trigger because pieces can't fit
4. **Bug Symptom**: If game over doesn't trigger, we've reproduced the bug

### 3. Debug Output to Analyze

Look for this pattern in console:

```
DEBUG: Testing specific bug scenario...
DEBUG: Creating nearly full board scenario for testing...
DEBUG: Starting game over check with 3 pieces
DEBUG: Current pieces: [Straight5, LShape, TShape]
DEBUG: Piece placement results:
  - Straight5: CAN/CANNOT place
  - LShape: CAN/CANNOT place
  - TShape: CAN/CANNOT place
```

### 4. Key Questions to Answer

- **Do any pieces report "CAN place"?** If so, the game should continue
- **Do all pieces report "CANNOT place"?** If so, game over should trigger
- **Is the board state accurate?** Does the ASCII output match the visual board?
- **Are the piece shapes correct?** Do they match what you see on screen?

### 5. Common Issues to Look For

- **Piece Shape Mismatch**: Visual piece doesn't match its grid definition
- **Board State Inconsistency**: Hidden blocks or incorrect grid state
- **Placement Logic Error**: `canPlacePiece()` returning wrong results
- **Timing Issues**: Game over check happening at wrong time

## Next Steps Based on Results

### If Bug is Reproduced (Game over doesn't trigger when it should)

1. Capture the complete console debug output
2. Note which pieces report "CAN place" when they shouldn't be able to
3. Check if any piece actually CAN be placed manually
4. We'll fix the specific issue found

### If Bug is NOT Reproduced (Game over triggers correctly)

1. Try different piece combinations
2. Test after revive scenarios
3. Try manual play to naturally reach the problematic state
4. The issue might be timing or state-related

## File Locations of Debug Enhancements

- **Game Logic**: `GameScene+GameLogic.swift` - `checkForGameOver()`
- **Board Logic**: `GameBoard.swift` - `canPlacePieceAnywhere()`, `debugPrintBoardState()`
- **Test Scenarios**: `GameBoard.swift` - `debugTestGameOverScenario()`, `debugCreateProblematicPieces()`
- **UI Controls**: `GameScene+Touch.swift` - Debug button handlers

This debug system should definitively identify the root cause of the game over detection bug.
