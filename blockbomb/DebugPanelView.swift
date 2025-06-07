import SwiftUI

#if DEBUG
/// Debug panel for testing game mechanics and scenarios
/// Only available in debug builds
struct DebugPanelView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Debug actions to be passed from the parent view
    let onTestBugScenario: () -> Void
    let onTestGameOver: () -> Void
    let onNearlyFullBoard: () -> Void
    let onResetHearts: () -> Void
    let onForceCheck: () -> Void
    let onViewShapes: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    Text("Debug Panel")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(BlockColors.violet)
                        .padding(.top, 40)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            
                            // Game Over Testing Section
                            DebugSection(title: "Game Over Testing") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "Test Bug Scenario",
                                        subtitle: "Test the specific game over bug with Elbow + T-Shape pieces",
                                        color: .red,
                                        action: onTestBugScenario
                                    )
                                    
                                    DebugButton(
                                        title: "Test Game Over",
                                        subtitle: "Create a general game over testing scenario",
                                        color: .orange,
                                        action: onTestGameOver
                                    )
                                    
                                    DebugButton(
                                        title: "Nearly Full Board",
                                        subtitle: "Create a nearly full board for manual testing",
                                        color: .yellow,
                                        action: onNearlyFullBoard
                                    )
                                    
                                    DebugButton(
                                        title: "Force Check",
                                        subtitle: "Manually trigger game over detection",
                                        color: .cyan,
                                        action: onForceCheck
                                    )
                                }
                            }
                            
                            // Revive System Testing Section
                            DebugSection(title: "Revive System") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "Reset Hearts",
                                        subtitle: "Reset revive heart count to 3 for testing",
                                        color: .red,
                                        action: onResetHearts
                                    )
                                }
                            }
                            
                            // Game Content Section
                            DebugSection(title: "Game Content") {
                                VStack(spacing: 12) {
                                    DebugButton(
                                        title: "View All Shapes",
                                        subtitle: "Browse all available tetromino shapes",
                                        color: .blue,
                                        action: onViewShapes
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // Close Button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Close")
                            .font(.title2.bold())
                            .foregroundColor(Color(red: 0.13, green: 0.12, blue: 0.28))
                            .frame(width: 200, height: 50)
                            .background(BlockColors.violet)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.bottom, 40)
                }
                .navigationBarHidden(true)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

/// A section container for grouping debug options
struct DebugSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.leading, 4)
            
            VStack(spacing: 8) {
                content()
            }
            .padding(20)
            .background(Color(red: 0.13, green: 0.12, blue: 0.28))
            .cornerRadius(16)
        }
    }
}

/// A styled debug button with title and subtitle
struct DebugButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Color indicator circle
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DebugPanelView_Previews: PreviewProvider {
    static var previews: some View {
        DebugPanelView(
            onTestBugScenario: {},
            onTestGameOver: {},
            onNearlyFullBoard: {},
            onResetHearts: {},
            onForceCheck: {},
            onViewShapes: {}
        )
    }
}

#endif
