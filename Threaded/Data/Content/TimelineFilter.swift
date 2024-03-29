//Made by Lumaa

import Foundation
import SwiftUI

public enum RemoteTimelineFilter: String, CaseIterable, Hashable, Equatable {
    case local, federated, trending
    
    public func localizedTitle() -> LocalizedStringKey {
        switch self {
            case .federated:
                "timeline.federated"
            case .local:
                "timeline.local"
            case .trending:
                "timeline.trending"
        }
    }
}

public enum TimelineFilter: Hashable, Equatable {
    case home, local, federated, trending
    case hashtag(tag: String, accountId: String?)
    case tagGroup(title: String, tags: [String])
    case list(list: AccountsList)
    case remoteLocal(server: String, filter: RemoteTimelineFilter)
    case latest
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
    
    public static func availableTimeline(client: Client) -> [TimelineFilter] {
        if !client.isAuth {
            return [.local, .federated, .trending]
        }
        return [.home, .local, .federated, .trending]
    }
    
    public var supportNewestPagination: Bool {
        switch self {
            case .trending:
                false
            case let .remoteLocal(_, filter):
                filter != .trending
            default:
                true
        }
    }
    
    public var title: String {
        switch self {
            case .latest:
                "Latest"
            case .federated:
                "Federated"
            case .local:
                "Local"
            case .trending:
                "Trending"
            case .home:
                "Home"
            case let .hashtag(tag, _):
                "#\(tag)"
            case let .tagGroup(title, _):
                title
            case let .list(list):
                list.title
            case let .remoteLocal(server, _):
                server
        }
    }
    
    public func localizedTitle() -> LocalizedStringKey {
        switch self {
            case .latest:
                "timeline.latest"
            case .federated:
                "timeline.federated"
            case .local:
                "timeline.local"
            case .trending:
                "timeline.trending"
            case .home:
                "timeline.home"
            case let .hashtag(tag, _):
                "#\(tag)"
            case let .tagGroup(title, _):
                LocalizedStringKey(title) // ?? not sure since this can't be localized.
            case let .list(list):
                LocalizedStringKey(list.title)
            case let .remoteLocal(server, _):
                LocalizedStringKey(server)
        }
    }
    
    public func endpoint(sinceId: String?, maxId: String?, minId: String?, offset: Int?) -> Endpoint {
        switch self {
            case .federated: return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: false)
            case .local: return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: true)
            case let .remoteLocal(_, filter):
                switch filter {
                    case .local:
                        return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: true)
                    case .federated:
                        return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: false)
                    case .trending:
                        return Trends.statuses(offset: offset)
                }
            case .latest: return Timelines.home(sinceId: nil, maxId: nil, minId: nil)
            case .home: return Timelines.home(sinceId: sinceId, maxId: maxId, minId: minId)
            case .trending: return Trends.statuses(offset: offset)
            case let .list(list): return Timelines.list(listId: list.id, sinceId: sinceId, maxId: maxId, minId: minId)
            case let .hashtag(tag, accountId):
                if let accountId {
                    return Accounts.statuses(id: accountId, sinceId: nil, tag: tag, onlyMedia: nil, excludeReplies: nil, pinned: nil)
                } else {
                    return Timelines.hashtag(tag: tag, additional: nil, maxId: maxId)
                }
            case let .tagGroup(_, tags):
                var tags = tags
                if !tags.isEmpty {
                    let tag = tags.removeFirst()
                    return Timelines.hashtag(tag: tag, additional: tags, maxId: maxId)
                } else {
                    return Timelines.hashtag(tag: "", additional: tags, maxId: maxId)
                }
        }
    }
}

extension TimelineFilter: Codable {
    enum CodingKeys: String, CodingKey {
        case home
        case local
        case federated
        case trending
        case hashtag
        case tagGroup
        case list
        case remoteLocal
        case latest
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first
        switch key {
            case .home:
                self = .home
            case .local:
                self = .local
            case .federated:
                self = .federated
            case .trending:
                self = .trending
            case .hashtag:
                var nestedContainer = try container.nestedUnkeyedContainer(forKey: .hashtag)
                let tag = try nestedContainer.decode(String.self)
                let accountId = try nestedContainer.decode(String?.self)
                self = .hashtag(
                    tag: tag,
                    accountId: accountId
                )
            case .tagGroup:
                var nestedContainer = try container.nestedUnkeyedContainer(forKey: .hashtag)
                let title = try nestedContainer.decode(String.self)
                let tags = try nestedContainer.decode([String].self)
                self = .tagGroup(
                    title: title,
                    tags: tags
                )
            case .list:
                let list = try container.decode(
                    AccountsList.self,
                    forKey: .list
                )
                self = .list(list: list)
            case .remoteLocal:
                var nestedContainer = try container.nestedUnkeyedContainer(forKey: .remoteLocal)
                let server = try nestedContainer.decode(String.self)
                let filter = try nestedContainer.decode(RemoteTimelineFilter.self)
                self = .remoteLocal(
                    server: server,
                    filter: filter
                )
            case .latest:
                self = .latest
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Unabled to decode enum."
                    )
                )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case .home:
                try container.encode(CodingKeys.home.rawValue, forKey: .home)
            case .local:
                try container.encode(CodingKeys.local.rawValue, forKey: .local)
            case .federated:
                try container.encode(CodingKeys.federated.rawValue, forKey: .federated)
            case .trending:
                try container.encode(CodingKeys.trending.rawValue, forKey: .trending)
            case let .hashtag(tag, accountId):
                var nestedContainer = container.nestedUnkeyedContainer(forKey: .hashtag)
                try nestedContainer.encode(tag)
                try nestedContainer.encode(accountId)
            case let .tagGroup(title, tags):
                var nestedContainer = container.nestedUnkeyedContainer(forKey: .tagGroup)
                try nestedContainer.encode(title)
                try nestedContainer.encode(tags)
            case let .list(list):
                try container.encode(list, forKey: .list)
            case let .remoteLocal(server, filter):
                var nestedContainer = container.nestedUnkeyedContainer(forKey: .hashtag)
                try nestedContainer.encode(server)
                try nestedContainer.encode(filter)
            case .latest:
                try container.encode(CodingKeys.latest.rawValue, forKey: .latest)
        }
    }
}

extension TimelineFilter: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(TimelineFilter.self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

extension RemoteTimelineFilter: Codable {
    enum CodingKeys: String, CodingKey {
        case local
        case federated
        case trending
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first
        switch key {
            case .local:
                self = .local
            case .federated:
                self = .federated
            case .trending:
                self = .trending
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Unabled to decode enum."
                    )
                )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case .local:
                try container.encode(CodingKeys.local.rawValue, forKey: .local)
            case .federated:
                try container.encode(CodingKeys.federated.rawValue, forKey: .federated)
            case .trending:
                try container.encode(CodingKeys.trending.rawValue, forKey: .trending)
        }
    }
}

extension RemoteTimelineFilter: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(RemoteTimelineFilter.self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
