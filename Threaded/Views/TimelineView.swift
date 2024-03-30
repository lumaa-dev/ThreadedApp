//Made by Lumaa

import SwiftUI

struct TimelineView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @State var navigator: Navigator = Navigator()
    
    @State private var showPicker: Bool = false
    @State private var timelines: [TimelineFilter] = [.home, .trending, .local, .federated]
    
    @State private var loadingStatuses: Bool = false
    @State private var statuses: [Status]?
    @State private var lastSeen: Int?
    
    @State var filter: TimelineFilter = .home
    @State var showHero: Bool = true
    @State var timelineModel: FetchTimeline // home timeline by default
    
    init(timelineModel: FetchTimeline, filter: TimelineFilter = .home, showHero: Bool = true) {
        self.timelineModel = timelineModel
        self.filter = filter
        self.showHero = showHero
    }
    
    init(filter: TimelineFilter = .home, showHero: Bool = true) {
        self.timelineModel = .init(client: AccountManager.shared.forceClient())
        self.filter = filter
        self.showHero = showHero
    }
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            if statuses != nil {
                if !statuses!.isEmpty {
                    ScrollView(showsIndicators: false) {
                        if showHero {
                            Button {
                                withAnimation(.easeInOut) {
                                    showPicker.toggle()
                                }
                            } label: {
                                Image("HeroIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30)
                                    .padding(.bottom)
                            }
                        }
                        
                        if showPicker {
                            ViewThatFits {
                                HStack {
                                    ForEach(timelines, id: \.self) { t in
                                        Button {
                                            Task {
                                                await reloadTimeline(t)
                                            }
                                        } label: {
                                            Text(t.localizedTitle())
                                                .padding(.horizontal)
                                        }
                                        .buttonStyle(LargeButton(filled: t == filter, height: 7.5))
                                        .disabled(t == filter)
                                    }
                                }
                                
                                ScrollView(.horizontal) {
                                    HStack {
                                        ForEach(timelines, id: \.self) { t in
                                            Button {
                                                Task {
                                                    await reloadTimeline(t)
                                                }
                                            } label: {
                                                Text(t.localizedTitle())
                                                    .padding(.horizontal)
                                            }
                                            .buttonStyle(LargeButton(filled: t == filter, height: 7.5))
                                            .disabled(t == filter)
                                        }
                                    }
                                }
                                .padding(.vertical)
                                .scrollIndicators(.hidden)
                            }
                        }
                        
                        ForEach(statuses!, id: \.id) { status in
                            LazyVStack(alignment: .leading, spacing: 2) {
                                CompactPostView(status: status)
                                    .onDisappear {
                                        guard statuses != nil else { return }
                                        lastSeen = statuses!.firstIndex(where: { $0.id == status.id })
                                    }
                            }
                        }
                    }
                    .refreshable {
                        if let client = accountManager.getClient() {
                            Task {
                                loadingStatuses = true
                                statuses = await timelineModel.fetch(client: client)
                                loadingStatuses = false
                            }
                        }
                    }
                    .onChange(of: lastSeen ?? 0) { _, new in
                        guard !loadingStatuses else { return }
                        Task {
                            loadingStatuses = true
                            statuses = await timelineModel.addStatuses(lastStatusIndex: new)
                            loadingStatuses = false
                        }
                    }
                    .padding(.top)
                    .background(Color.appBackground)
                    .withAppRouter(navigator)
                } else {
                    ZStack {
                        Color.appBackground
                            .ignoresSafeArea()
                        
                        VStack {
                            Image("HeroIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50)
                                .padding(.bottom)
                            
                            ContentUnavailableView {
                                Text("timeline.empty")
                                    .bold()
                            } description: {
                                Text("timeline.empty.description")
                            }
                            .scrollDisabled(true)
                        }
                        .scrollDisabled(true)
                        .background(Color.appBackground)
                        .frame(height: 200)
                    }
                }
            } else {
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                        .onAppear {
                            if let client = accountManager.getClient() {
                                Task {
                                    statuses = await timelineModel.fetch(client: client)
                                }
                            }
                        }
                    
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        }
        .environmentObject(navigator)
        .background(Color.appBackground)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaPadding()
    }
    
    private func reloadTimeline(_ filter: TimelineFilter) async {
        guard let client = accountManager.getClient() else { return }
        statuses = nil
        self.filter = filter
        timelineModel.setTimelineFilter(filter)
        
        Task {
            loadingStatuses = true
            statuses = await timelineModel.fetch(client: client)
            lastSeen = nil
            loadingStatuses = false
        }
    }
}
