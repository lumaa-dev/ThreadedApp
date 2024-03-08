//Made by Lumaa

import SwiftUI
import Nuke

struct PrivacyView: View {
    @ObservedObject private var userPreferences: UserPreferences = .defaultPreferences
    @EnvironmentObject private var navigator: Navigator
    @Environment(\.dismiss) private var dismiss
    
    @State private var clearedCache: Bool = false
    
    var body: some View {
        List {
            //TODO: Blocklist & Mutelist
            
            Picker(LocalizedStringKey("setting.privacy.default-visibility"), selection: $userPreferences.defaultVisibility) {
                ForEach(Visibility.allCases, id: \.self) { visibility in
                    switch (visibility) {
                        case .pub:
                            Text("status.posting.visibility.public")
                        case .priv:
                            Text("status.posting.visibility.private")
                        case .unlisted:
                            Text("status.posting.visibility.unlisted")
                        case .direct:
                            Text("status.posting.visibility.direct")
                    }
                }
            }
            .pickerStyle(.inline)
            .listRowThreaded()
            
            Spacer()
                .frame(height: 30)
                .listRowThreaded()
            
            Section {
                HStack {
                    Text("settings.privacy.clear-cache")
                    
                    Spacer()
                    
                    Button {
                        let cache = ImagePipeline.shared.cache
                        cache.removeAll()
                        withAnimation(.spring) {
                            clearedCache = true
                        }
                    } label: {
                        Text(clearedCache ? "settings.privacy.cleared" : "settings.privacy.clear")
                            .foregroundStyle(clearedCache ? Color(uiColor: UIColor.label) : Color(uiColor: UIColor.systemBackground))
                    }
                    .buttonStyle(LargeButton(filled: true, filledColor: clearedCache ? Color.green : Color(uiColor: UIColor.label), height: 7.5))
                    .disabled(clearedCache)
                }
            }
            .listRowThreaded()
        }
        .listThreaded()
        .navigationTitle(Text("privacy"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onAppear {
            loadOld()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    loadOld()
                    dismiss()
                } label: {
                    Text("settings.cancel")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    do {
                        try userPreferences.saveAsCurrent()
                        dismiss()
                    } catch {
                        print(error)
                    }
                } label: {
                    Text("settings.done")
                }
            }
        }
    }
    
    private func loadOld() {
        do {
            let oldPreferences = try UserPreferences.loadAsCurrent() ?? UserPreferences.defaultPreferences
            
            userPreferences.defaultVisibility = oldPreferences.defaultVisibility
        } catch {
            print(error)
            dismiss()
        }
    }
}

#Preview {
    PrivacyView()
}
