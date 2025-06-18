# 🛠 Build Instructions for Block Puzzle Game (iOS)

This project is a **SwiftUI + SpriteKit** block puzzle game targeting **iOS 15+**. It is optimized for **iPhone-only** devices and built using an **Xcode project** structure.

---

## Game Modes

### Single Player

- Core loop: drag & place → clear blocks → repeat
- Objective: get the highest score by clearing rows/columns/squares
- Lose condition: no valid moves left for current pieces

### Multiplayer (Game Center Turn-Based)

- **Competitive**: Two players compete for highest score on separate 8x8 grids
- **Turn Structure**: Players alternate turns, each getting the same set of 3 pieces
- **Fair Play**: Identical piece sets ensure skill-based competition
- **Win Condition**: Highest score when game ends (either player can't place pieces or uses "End Game" button)
- **Asynchronous**: No time limits, players can take turns when convenient
- **Emergency Exit**: Either player can end the game at any time

---

## Game components

- Grid System: 8x8 matrix (individual grids in multiplayer)
- Block Pieces: Tetris-like tetrominoes (predefined, random sets of 3)
- Piece Placement: Snap to grid, validate placement
- Line Clearing Logic: Clear full rows/columns and award points
- Score System: Add combo bonuses, streaks, and high score tracking
- Game Over Detection: Check if none of the 3 pieces can fit
- Multiplayer State: Synchronized piece generation and turn management

---

## 📦 Project Setup

### Requirements

- Xcode 15+
- iOS 15+ SDK
- macOS with Swift toolchain installed

### Initial Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/block-puzzle-game.git
   cd block-puzzle-game
   ```

2. Open the project in Xcode:
   ```bash
   open BlockPuzzleGame.xcodeproj
   ```

---

## 🧱 Development Notes

### Placeholder Assets

This project currently uses colored `SKSpriteNode` shapes for block tiles and UI elements. You can replace these later with real images in `Assets.xcassets`.

> 💡 Use `.color` initializers like `.orange`, `.blue`, etc. to customize pieces.

---

## 🧪 Running and Testing

### Simulator Deployment

- Choose any iPhone simulator (e.g. iPhone 14) and press ⌘R to build and run.

### Device Deployment

1. Connect your device via USB.
2. Select it in the Xcode target dropdown.
3. Press ⌘R to run on device.
   > ⚠️ You may need to sign the project with your Apple ID under **Signing & Capabilities**.

### Unit Testing

1. Add tests under `BlockPuzzleGameTests/`
2. Run tests with ⌘U or via the **Test Navigator**.

---

## 🔍 Debugging

### Recommended Practices

- Set breakpoints in `GameScene.swift` and `Grid.swift`.
- Use `print()` statements for grid state, score updates, or game over checks.
- Use Xcode's **Memory Graph Debugger** for SpriteKit leak checks.

---

## 🕹 Game Center Integration

To prepare for Game Center:

1. Enable it in **Signing & Capabilities**.
2. Use `GKLocalPlayer.local.authenticateHandler` in your game entry point.

---

## 💰 Ads and Analytics (Planned)

This project will support:

- **Interstitial ads** between games (e.g. AdMob)
- **Analytics** for tracking gameplay (e.g. Firebase)

These will be added later; leave comments where these hooks will go.

---

## 🚀 App Store / TestFlight Deployment

1. In Xcode, select **Any iOS Device (arm64)** as target.
2. Archive the build via **Product > Archive**.
3. Upload using **Xcode Organizer** or **Transporter**.
4. Manage TestFlight testers in **App Store Connect**.

---

## ✅ TODOs

- [ ] Add touch interaction for drag-and-drop
- [ ] Validate piece placement on grid
- [ ] Implement scoring and row/column clearing
- [ ] Integrate Game Center leaderboard
- [ ] Add interstitial ads between games
- [ ] Add Firebase analytics hooks

---

For any major additions or refactors, consider updating this file.

Happy building! 🎮
