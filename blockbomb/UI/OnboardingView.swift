import SwiftUI

/// First-time user onboarding explaining the ad-supported free game model
struct OnboardingView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPage = 0
    @State private var animateContent = false
    
    private let pages = [
        OnboardingPage(
            icon: .asset( name: "BlockEmUpLogo"),
            title: "Welcome!",
            subtitle: "Your next obsession is here",
            description: "Think you’ve got what it takes to outsmart a pile of colorful blocks? No passwords, no paywalls—just you, your wits, and a seriously entertaining time. Go on, give ‘em what-for!",
            color: BlockColors.violet
        ),
        OnboardingPage(
            icon: .system( name: "dollarsign.circle.fill"),
            title: "Earn Coins, Power Up",
            subtitle: "Watch. Earn. Conquer.",
            description: "Sit back, watch a quick ad, and ka-ching—coins in your pocket! Spend them on power-ups so you can obliterate tricky levels like the puzzle pro you are.",
            color: BlockColors.amber
        ),
        OnboardingPage(
            icon: .system(name:"heart.fill"),
            title: "Revive Hearts",
            subtitle: "Keep the game going",
            description: "Oops—ran out of moves? No biggie! Trade in some coins for a revive heart and swoop back into the action. It’s like real-life respawns, but way more satisfying.",
            color: BlockColors.red
        ),
        OnboardingPage(
            icon: .system(name:"bolt.fill"),
            title: "Ads That Fuel Fun",
            subtitle: "Help keep it free",
            description: "By watching ads, you’re basically the hero behind new levels, epic power-ups, and future shenanigans. Plus, you score bonus coins—so really, it’s a win-win.",
            color: BlockColors.orange
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: dismissOnboarding) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(BlockColors.violet)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.top, 20)
                .padding(.trailing, 20)
                
                // Content area
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? BlockColors.violet : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button(action: previousPage) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 1, green: 0.92, blue: 0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(25)
                        }
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Button(action: isLastPage ? dismissOnboarding : nextPage) {
                        HStack {
                            Text(isLastPage ? "Get Started" : "Next")
                            if !isLastPage {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 1, green: 0.92, blue: 0.8))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(BlockColors.violet)
                        .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateContent = true
            }
        }
    }
    
    private var isLastPage: Bool {
        currentPage == pages.count - 1
    }
    
    private func nextPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = min(currentPage + 1, pages.count - 1)
        }
    }
    
    private func previousPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = max(currentPage - 1, 0)
        }
    }
    
    private func dismissOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        presentationMode.wrappedValue.dismiss()
    }
}

struct OnboardingPage {
    enum Icon {
        case system(name: String)
        case asset(name: String)
    }
    
    let icon: Icon
    let title: String
    let subtitle: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Group {
                switch page.icon {
                case .system(let name):
                    Image(systemName: name)
                        .font(.system(size: 80, weight: .light))
                case .asset(let name):
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200) // adjust to taste
                }
            }
            
            .foregroundColor(page.color)
            .scaleEffect(animate ? 1.0 : 0.5)
            .opacity(animate ? 1.0 : 0.0)
            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animate)
            // Icon
            
            
            VStack(spacing: 16) {
                // Title
                Text(page.title)
                    .font(.title.bold())
                    .foregroundColor(Color(red: 1, green: 0.92, blue: 0.8))
                    .multilineTextAlignment(.center)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animate)
                
                // Subtitle
                Text(page.subtitle)
                    .font(.title3.weight(.medium))
                    .foregroundColor(page.color)
                    .multilineTextAlignment(.center)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: animate)
                
                // Description
                Text(page.description)
                    .font(.body)
                    .foregroundColor(Color(red: 1, green: 0.92, blue: 0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: animate)
            }
            
            Spacer()
            Spacer()
        }
        .onAppear {
            animate = true
        }
        .onDisappear {
            animate = false
        }
    }
}

// MARK: - Onboarding Manager
class OnboardingManager: ObservableObject {
    @Published var shouldShowOnboarding: Bool
    
    init() {
        shouldShowOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        shouldShowOnboarding = false
    }
    
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        shouldShowOnboarding = true
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
