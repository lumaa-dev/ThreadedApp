//Made by Lumaa

import SwiftUI

struct AccountView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    
    @State private var navigator: Navigator = Navigator.shared
    @State public var account: Account
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            ProfileView(account: account, isCurrent: true)
                .withAppRouter(navigator)
                .onAppear {
                    if let acc = accountManager.getAccount() {
                        account = acc
                    } else {
                        account = .placeholder()
                    }
                }
        }
        .environment(\.openURL, OpenURLAction { url in
            // Open internal URL.
            let handled = navigator.handle(url: url)
            return handled
        })
        .environmentObject(navigator)
    }
}
