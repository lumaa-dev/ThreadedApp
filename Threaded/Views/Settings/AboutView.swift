//Made by Lumaa

import SwiftUI

struct AboutView: View {
    @ObservedObject private var userPreferences: UserPreferences = .defaultPreferences
    
    var body: some View {
        List {
            NavigationLink {
                aboutApp
            } label: {
                Text("about.app")
                    .tint(Color.blue)
            }
            .listRowThreaded()
            
            Toggle("setting.experimental.activate", isOn: $userPreferences.showExperimental)
                .listRowThreaded()
                .tint(Color(uiColor: UIColor.label))
                .onAppear {
                    do {
                        let oldPreferences = try UserPreferences.loadAsCurrent() ?? UserPreferences.defaultPreferences
                        
                        userPreferences.showExperimental = oldPreferences.showExperimental
                    } catch {
                        print(error)
                    }
                }
        }
        .listThreaded(tint: Color.blue)
        .navigationTitle("about")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            do {
                if !userPreferences.showExperimental {
                    userPreferences.experimental = .init()
                }
                try userPreferences.saveAsCurrent()
            } catch {
                print(error)
            }
        }
    }
    
    var aboutApp: some View {
        ScrollView {
            VStack (spacing: 15) {
                Text("about.app.details")
                    .multilineTextAlignment(.leading)
                Text("about.app.third-party")
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal)
        }
        .listThreaded()
        .navigationTitle("about.app")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    AboutView()
}
