//Made by Lumaa

import SwiftUI

struct UpdateView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(alignment: .center) {
                Text("update.title")
                    .font(.title.bold())
                    .padding(.top, 50)
                Text("about.version-\(AppInfo.appVersion)")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                
                Spacer()
                
                features
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("update.hide")
                        .frame(minWidth: 250)
                }
                .buttonStyle(LargeButton(filled: true))
            }
        }
    }
    
    var features: some View {
        VStack(spacing: 40) {
            newFeature(systemImage: "network", title: "Timeline Selector", text: "By tapping on the Threaded logo, you'll be able to select a timeine.")
            
            newFeature(systemImage: "info.circle", title: "\"About Threaded\" redesign", text: "This informational view has been majorly changed!")
            
            newFeature(systemImage: "number", title: "Read hashtags", text: "You can now view posts using a specific hashtag in the Discovery page.")
        }
        .frame(height: 500)
    }
    
    
    @ViewBuilder
    private func newFeature(systemImage: String, title: String, text: String) -> some View {
        ViewThatFits {
            HStack(alignment: .center) {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(Color(uiColor: UIColor.label))
                
                Spacer()
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .bold()
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    Text(text)
                        .foregroundStyle(Color(uiColor: UIColor.label).opacity(0.7))
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                }
                
                Spacer()
            }
            .frame(width: 330)
            
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                
                Text(text)
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func newFeature(imageName: String, title: String, text: String) -> some View {
        ViewThatFits {
            HStack(alignment: .center) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(Color(uiColor: UIColor.label))
                
                Spacer()
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .bold()
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    Text(text)
                        .foregroundStyle(Color(uiColor: UIColor.label).opacity(0.7))
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                }
                
                Spacer()
            }
            .frame(width: 330)
            
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                
                Text(text)
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    Text(String("UpdateView"))
        .sheet(isPresented: .constant(true)) {
            UpdateView()
        }
}
