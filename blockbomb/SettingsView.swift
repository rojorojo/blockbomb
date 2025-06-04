import SwiftUI

struct SettingsView: View {
    @ObservedObject private var audioManager = AudioManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
          ZStack {
              
                  Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                      .edgesIgnoringSafeArea(.all)
              
            VStack(spacing: 24) {
               
                    
                    
                    Text("Settings")
                    .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(BlockColors.amber)
                                        .padding(.top, 40)
               
                
                // Audio Settings Section
              
                    // Mute Toggle
                SettingBox {
                        HStack {
                            
                            Text("Mute all audio")
                                .foregroundColor(.white)
                                
                            
                            Spacer()
                            
                            Toggle("", isOn: $audioManager.isMuted)
                                .toggleStyle(SwitchToggleStyle(tint: BlockColors.amber))
                        }
                        
                    }
                    
                SettingBox {
                    // Master Volume
                    VStack(alignment: .leading) {
                        
                            Text("Master Volume")
                                .foregroundColor(.white)
                                .font(.body.weight(.semibold))
                                .padding(.bottom, 24)
                            
                        
                        
                        HStack {
                            Image(systemName: "speaker.fill")
                                                            .foregroundColor(BlockColors.amber)
                                                            .opacity(audioManager.isMuted ? 0.4 : 1)
                            Slider(value: $audioManager.masterVolume, in: 0...1)
                                .accentColor(BlockColors.amber)
                                .disabled(audioManager.isMuted)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                                            .foregroundColor(BlockColors.amber)
                                                            .opacity(audioManager.isMuted ? 0.4 : 1)
                        }
                        
                    }
                }
                
                SettingBox {
                    // Sound Effects Volume
                    VStack(alignment: .leading, spacing: 8) {
                        
                            Text("Sound Effects")
                                .foregroundColor(.white)
                                .font(.body.weight(.semibold))
                                .padding(.bottom, 24)
                            
                        
                        
                        HStack {
                            Image(systemName: "speaker.fill")
                                                            .foregroundColor(BlockColors.amber)
                                                            .opacity(audioManager.isMuted ? 0.4 : 1)
                            Slider(value: $audioManager.sfxVolume, in: 0...1)
                                .accentColor(BlockColors.amber)
                                .disabled(audioManager.isMuted)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                                            .foregroundColor(BlockColors.amber)
                                                            .opacity(audioManager.isMuted ? 0.4 : 1)
                        }
                        
                    }
                    
                }
                Spacer()
                
                // Close Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .font(.title2.bold())
                        .foregroundColor(Color(red: 0.13, green: 0.12, blue: 0.28))
                        .frame(width: 200, height: 50)
                        .background(BlockColors.amber)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.bottom, 40)
            }
            
            .navigationBarHidden(true)
            .padding(.horizontal, 24)
        }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Test Functions
    private func testMasterVolume() {
        AudioManager.shared.playBlockPlaceSound()
        AudioManager.shared.triggerHapticFeedback(for: .blockPlace)
    }
    
    private func testSoundEffects() {
        AudioManager.shared.playLineClearSound(lineCount: 2)
        AudioManager.shared.triggerHapticFeedback(for: .lineClear)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}


struct SettingBox<Content: View>: View {
    let content: () -> Content
    
    var body: some View {
            VStack {
                content()
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(red: 0.13, green: 0.12, blue: 0.28))
            .cornerRadius(16)
            .frame(maxWidth: .infinity)
        }
}

