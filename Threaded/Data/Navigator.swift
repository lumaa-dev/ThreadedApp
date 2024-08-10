//Made by Lumaa

import Foundation
import SwiftUI

@Observable
public class Navigator: ObservableObject {
    public static var shared: Navigator = Navigator()

    public var path: [RouterDestination] = []
    public var presentedSheet: SheetDestination?
    public var presentedCover: SheetDestination?
    public var selectedTab: TabDestination {
        set {
            change(to: newValue)
        }
        get {
            return self.currentTab
        }
    }
    private var currentTab: TabDestination = .timeline

    public private(set) var memorizedNav: [TabDestination : [RouterDestination]] = [:]
    public var showTabbar: Bool {
        get {
            self.visiTabbar
        }
        set {
            withAnimation(.spring) {
                self.visiTabbar = newValue
            }
        }
    }
    private var visiTabbar: Bool = true

    public var client: Client?
    
    public func navigate(to: RouterDestination) {
        path.append(to)
    }

    /// Changes the current tab from the current ``Navigator`` class
    func change(to tab: TabDestination) {
        savePath()

        withAnimation(.spring) {
            loadPath(from: tab)
        }
    }

    private func savePath() {
        let lastTab: TabDestination = self.currentTab
        let lastPath: [RouterDestination] = self.path

        memorizedNav.updateValue(lastPath, forKey: lastTab)
    }

    private func loadPath(from tab: TabDestination) {
        if let (newTab, newPath) = memorizedNav.first(where: { $0.key == tab }).map({ [$0.key : $0.value] })?.first {
            self.currentTab = newTab
            self.path = newPath
        } else {
            print("Couldn't find Navigator data from \(tab.id), created new ones")
            self.currentTab = tab
            self.path = []
        }
    }

    public func handle(url: URL) -> OpenURLAction.Result {
        guard let client = self.client else { return .systemAction }
        let path: String = url.absoluteString.replacingOccurrences(of: AppInfo.scheme, with: "") // remove all path
        let urlPath: URL = URL(string: path)!
        
        let server: String = urlPath.host() ?? client.server
        let lastIndex = urlPath.pathComponents.count - 1
        
        let actionType = urlPath.pathComponents[lastIndex - 1]
        
        if client.isAuth && client.hasConnection(with: url) {
            if urlPath.lastPathComponent.starts(with: "@") {
                Task {
                    do {
                        print("\(urlPath.lastPathComponent)@\(server.replacingOccurrences(of: "www.", with: ""))")
                        let search: SearchResults = try await client.get(endpoint: Search.search(query: "\(urlPath.lastPathComponent)@\(server.replacingOccurrences(of: "www.", with: ""))", type: "accounts", offset: nil, following: nil), forceVersion: .v2)
                        print(search)
                        let acc: Account = search.accounts.first ?? .placeholder()
                        self.navigate(to: .account(acc: acc))
                    } catch {
                        print(error)
                    }
                }
                return OpenURLAction.Result.handled
            } else {
                self.presentedSheet = .safari(url: url)
            }
        } else {
            Task {
                do {
                    let connections: [String] = try await client.get(endpoint: Instances.peers)
                    client.addConnections(connections)
                    
                    
                    if client.hasConnection(with: url) {
                        _ = self.handle(url: url)
                    } else {
                        self.presentedSheet = .safari(url: url)
                    }
                } catch {
                    self.presentedSheet = .safari(url: url)
                }
            }
            
            return OpenURLAction.Result.handled
        }
        return OpenURLAction.Result.handled
    }

    /// This only applies on the current path, not the saved ones in ``memorizedNav``
    public func removeSettingsOfPath() {
        self.path = self.path.filter({ !RouterDestination.allSettings.contains($0) })
    }
}

/// This can be used for universal ``SheetDestination``s
public class UniversalNavigator: Navigator {
    public static var `static`: UniversalNavigator = UniversalNavigator()
}

public enum TabDestination: Identifiable {
    case timeline
    case search
    case activity
    case profile
    
    public var id: String {
        switch self {
            case .timeline:
                return "timeline"
            case .search:
                return "search"
            case .activity:
                return "activity"
            case .profile:
                return "profile"
        }
    }
}

public enum SheetDestination: Identifiable {
    case welcome
    case shop
    case media(attachments: [MediaAttachment], selected: MediaAttachment)
    
    case mastodonLogin(logged: Binding<Bool>)
    case post(content: String = "", replyId: String? = nil, editId: String? = nil)
    case profEdit
    case safari(url: URL)
    case shareImage(image: UIImage, status: Status)
    case update
    case filter

    case reportStatus(status: Status)
//    case reportUser

    public var id: String {
        switch self {
            case .welcome:
                return "welcome"
            case .shop:
                return "shop"
            case .media:
                return "media"
                
            case .mastodonLogin:
                return "login"
            case .post:
                return "post"
            case .profEdit:
                return "profileEdit"
            case .safari:
                return "safari"
            case .shareImage:
                return "shareImage"
            case .update:
                return "update"
            case .filter:
                return "contentfilter"

            case .reportStatus:
                return "reportStatus"
        }
    }
    
    public var isCover: Bool {
        switch self {
            case .welcome:
                return true
            case .shop:
                return true
            case .media:
                return true
                
            case .mastodonLogin:
                return false
            case .post:
                return false
            case .profEdit:
                return false
            case .safari:
                return false
            case .shareImage:
                return false
            case .update:
                return false
            case .filter:
                return false

            case .reportStatus:
                return false
        }
    }
}

public enum RouterDestination: Hashable {
    case settings
    case support
    case appearence
    case appicon
    case about
    case privacy
    case restricted
    case filter
    
    case account(acc: Account)
    case post(status: Status)
    case contacts
    case timeline(timeline: TimelineFilter)
}

extension RouterDestination {
    static let allSettings: [RouterDestination] = [.settings, .support, .about, .appearence, .privacy, .restricted, .filter, .appicon]
}

extension View {
    func withAppRouter(_ navigator: Navigator) -> some View {
        navigationDestination(for: RouterDestination.self) { destination in
            switch destination {
                case .settings:
                    SettingsView()
                case .support:
                    SupportView()
                case .appearence:
                    AppearenceView()
                case .appicon:
                    IconView()
                case .account(let acc):
                    ProfileView(account: acc)
                case .post(let status):
                    PostDetailsView(status: status)
                case .about:
                    AboutView()
                case .contacts:
                    ContactsView()
                case .privacy:
                    PrivacyView()
                case .restricted:
                    RestrictedView()
                case .timeline(let timeline):
                    PostsView(filter: timeline)
                case .filter:
                    FilterView()
            }
        }
    }
    
    func withSheets(sheetDestination: Binding<SheetDestination?>) -> some View {
        sheet(item: sheetDestination) { destination in
            viewSheet(destination: destination)
        }
    }
    
    func withCovers(sheetDestination: Binding<SheetDestination?>) -> some View {
        fullScreenCover(item: sheetDestination) { destination in
            viewCover(destination: destination)
        }
    }
    
    private func viewCover(destination: SheetDestination) -> some View {
        Group {
            switch destination {
                case .welcome:
                    ConnectView()
                case .shop:
                    ShopView()
                case .media(let attachments, let selected):
                    AttachmentView(attachments: attachments, selectedId: selected.id)
                default:
                    EmptySheetView(destId: destination.id)
            }
        }
    }
    
    private func viewSheet(destination: SheetDestination) -> some View {
        Group {
            switch destination {
                case .post(let content, let replyId, let editId):
                    NavigationStack {
                        PostingView(initialString: content, replyId: replyId, editId: editId)
                            .tint(Color(uiColor: UIColor.label))
                    }
                case .profEdit:
                    EditProfileView()
                case let .mastodonLogin(logged):
                    AddInstanceView(logged: logged)
                        .tint(Color.accentColor)
                case let .safari(url):
                    SfSafariView(url: url)
                        .ignoresSafeArea()
                case let .shareImage(image, status):
                    ShareSheet(image: image, status: status)
                case .update:
                    UpdateView()
                case let .reportStatus(status):
                    ReportStatusView(status: status)
                default:
                    EmptySheetView(destId: destination.id)
            }
        }
    }
}

/// This view is visible when the `viewRepresentation(destination: SheetDestination)` doesn't support the given `SheetDestination`
private struct EmptySheetView: View {
    @Environment(\.dismiss) private var dismiss
    var destId: String = ""
    let str: String = .init(localized: "about.version-\(AppInfo.appVersion)")
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.red.gradient)
                .ignoresSafeArea()
            
            VStack {
                ContentUnavailableView(String("Missing view for \"\(destId.isEmpty ? "[EMPTY_DEST_ID]" : destId)\""), systemImage: "exclamationmark.triangle.fill", description: Text(String("Please notify Lumaa as soon as possible!\n\n\(str)")))
                    .foregroundStyle(.white)
                
                Button {
                    dismiss()
                } label: {
                    Text(String("Dismiss"))
                }
                .buttonStyle(LargeButton(filled: true))
            }
        }
    }
}
