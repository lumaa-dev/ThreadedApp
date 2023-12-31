//Made by Lumaa

import Foundation
import RegexBuilder

public protocol Endpoint: Sendable {
    func path() -> String
    func queryItems() -> [URLQueryItem]?
    var jsonValue: Encodable? { get }
}

public extension Endpoint {
    var jsonValue: Encodable? {
        nil
    }
}

extension Endpoint {
    func makePaginationParam(sinceId: String?, maxId: String?, mindId: String?) -> [URLQueryItem]? {
        if let sinceId {
            return [.init(name: "since_id", value: sinceId)]
        } else if let maxId {
            return [.init(name: "max_id", value: maxId)]
        } else if let mindId {
            return [.init(name: "min_id", value: mindId)]
        }
        return nil
    }
}

public struct LinkHandler {
    public let rawLink: String
    
    public var maxId: String? {
        do {
            let regex = try Regex("max_id=[0-9]+")
            if let match = rawLink.firstMatch(of: regex) {
                return match.output.first?.substring?.replacingOccurrences(of: "max_id=", with: "")
            }
        } catch {
            return nil
        }
        return nil
    }
}

extension LinkHandler: Sendable {}

public struct ServerError: Decodable, Error {
    public let error: String?
    public var httpCode: Int?
}

extension ServerError: Sendable {}

public enum Apps: Endpoint {
    case registerApp
    
    public func path() -> String {
        switch self {
            case .registerApp:
                "apps"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        switch self {
            case .registerApp:
                return [
                    .init(name: "client_name", value: AppInfo.clientName),
                    .init(name: "redirect_uris", value: AppInfo.scheme),
                    .init(name: "scopes", value: AppInfo.scopes),
                    .init(name: "website", value: AppInfo.website),
                ]
        }
    }
}

public enum Instances: Endpoint {
    case instance
    case peers
    
    public func path() -> String {
        switch self {
            case .instance:
                "instance"
            case .peers:
                "instance/peers"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        nil
    }
}

public enum Accounts: Endpoint {
    case accounts(id: String)
    case lookup(name: String)
    case favorites(sinceId: String?)
    case bookmarks(sinceId: String?)
    case followedTags
    case featuredTags(id: String)
    case verifyCredentials
    case updateCredentials(json: UpdateCredentialsData)
    case statuses(id: String,
                  sinceId: String?,
                  tag: String?,
                  onlyMedia: Bool?,
                  excludeReplies: Bool?,
                  pinned: Bool?)
    case relationships(ids: [String])
    case follow(id: String, notify: Bool, reblogs: Bool)
    case unfollow(id: String)
    case familiarFollowers(withAccount: String)
    case suggestions
    case followers(id: String, maxId: String?)
    case following(id: String, maxId: String?)
    case lists(id: String)
    case preferences
    case block(id: String)
    case unblock(id: String)
    case mute(id: String, json: MuteData)
    case unmute(id: String)
    case relationshipNote(id: String, json: RelationshipNoteData)
    
    public func path() -> String {
        switch self {
            case let .accounts(id):
                "accounts/\(id)"
            case .lookup:
                "accounts/lookup"
            case .favorites:
                "favourites"
            case .bookmarks:
                "bookmarks"
            case .followedTags:
                "followed_tags"
            case let .featuredTags(id):
                "accounts/\(id)/featured_tags"
            case .verifyCredentials:
                "accounts/verify_credentials"
            case .updateCredentials:
                "accounts/update_credentials"
            case let .statuses(id, _, _, _, _, _):
                "accounts/\(id)/statuses"
            case .relationships:
                "accounts/relationships"
            case let .follow(id, _, _):
                "accounts/\(id)/follow"
            case let .unfollow(id):
                "accounts/\(id)/unfollow"
            case .familiarFollowers:
                "accounts/familiar_followers"
            case .suggestions:
                "suggestions"
            case let .following(id, _):
                "accounts/\(id)/following"
            case let .followers(id, _):
                "accounts/\(id)/followers"
            case let .lists(id):
                "accounts/\(id)/lists"
            case .preferences:
                "preferences"
            case let .block(id):
                "accounts/\(id)/block"
            case let .unblock(id):
                "accounts/\(id)/unblock"
            case let .mute(id, _):
                "accounts/\(id)/mute"
            case let .unmute(id):
                "accounts/\(id)/unmute"
            case let .relationshipNote(id, _):
                "accounts/\(id)/note"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        switch self {
            case let .lookup(name):
                return [
                    .init(name: "acct", value: name),
                ]
            case let .statuses(_, sinceId, tag, onlyMedia, excludeReplies, pinned):
                var params: [URLQueryItem] = []
                if let tag {
                    params.append(.init(name: "tagged", value: tag))
                }
                if let sinceId {
                    params.append(.init(name: "max_id", value: sinceId))
                }
                if let onlyMedia {
                    params.append(.init(name: "only_media", value: onlyMedia ? "true" : "false"))
                }
                if let excludeReplies {
                    params.append(.init(name: "exclude_replies", value: excludeReplies ? "true" : "false"))
                }
                if let pinned {
                    params.append(.init(name: "pinned", value: pinned ? "true" : "false"))
                }
                return params
            case let .relationships(ids):
                return ids.map {
                    URLQueryItem(name: "id[]", value: $0)
                }
            case let .follow(_, notify, reblogs):
                return [
                    .init(name: "notify", value: notify ? "true" : "false"),
                    .init(name: "reblogs", value: reblogs ? "true" : "false"),
                ]
            case let .familiarFollowers(withAccount):
                return [.init(name: "id[]", value: withAccount)]
            case let .followers(_, maxId):
                return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
            case let .following(_, maxId):
                return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
            case let .favorites(sinceId):
                guard let sinceId else { return nil }
                return [.init(name: "max_id", value: sinceId)]
            case let .bookmarks(sinceId):
                guard let sinceId else { return nil }
                return [.init(name: "max_id", value: sinceId)]
            default:
                return nil
        }
    }
    
    public var jsonValue: Encodable? {
        switch self {
            case let .mute(_, json):
                json
            case let .relationshipNote(_, json):
                json
            case let .updateCredentials(json):
                json
            default:
                nil
        }
    }
}

public struct MuteData: Encodable, Sendable {
    public let duration: Int
    
    public init(duration: Int) {
        self.duration = duration
    }
}

public struct RelationshipNoteData: Encodable, Sendable {
    public let comment: String
    
    public init(note comment: String) {
        self.comment = comment
    }
}

public struct UpdateCredentialsData: Encodable, Sendable {
    public struct SourceData: Encodable, Sendable {
        public let privacy: Visibility
        public let sensitive: Bool
        
        public init(privacy: Visibility, sensitive: Bool) {
            self.privacy = privacy
            self.sensitive = sensitive
        }
    }
    
    public struct FieldData: Encodable, Sendable {
        public let name: String
        public let value: String
        
        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }
    
    public let displayName: String
    public let note: String
    public let source: SourceData
    public let bot: Bool
    public let locked: Bool
    public let discoverable: Bool
    public let fieldsAttributes: [String: FieldData]
    
    public init(displayName: String,
                note: String,
                source: UpdateCredentialsData.SourceData,
                bot: Bool,
                locked: Bool,
                discoverable: Bool,
                fieldsAttributes: [FieldData])
    {
        self.displayName = displayName
        self.note = note
        self.source = source
        self.bot = bot
        self.locked = locked
        self.discoverable = discoverable
        
        var fieldAttributes: [String: FieldData] = [:]
        for (index, field) in fieldsAttributes.enumerated() {
            fieldAttributes[String(index)] = field
        }
        self.fieldsAttributes = fieldAttributes
    }
}

public enum Timelines: Endpoint {
    case pub(sinceId: String?, maxId: String?, minId: String?, local: Bool)
    case home(sinceId: String?, maxId: String?, minId: String?)
    case list(listId: String, sinceId: String?, maxId: String?, minId: String?)
    case hashtag(tag: String, additional: [String]?, maxId: String?)
    
    public func path() -> String {
        switch self {
            case .pub:
                "timelines/public"
            case .home:
                "timelines/home"
            case let .list(listId, _, _, _):
                "timelines/list/\(listId)"
            case let .hashtag(tag, _, _):
                "timelines/tag/\(tag)"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        switch self {
            case let .pub(sinceId, maxId, minId, local):
                var params = makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: minId) ?? []
                params.append(.init(name: "local", value: local ? "true" : "false"))
                return params
            case let .home(sinceId, maxId, mindId):
                return makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: mindId)
            case let .list(_, sinceId, maxId, mindId):
                return makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: mindId)
            case let .hashtag(_, additional, maxId):
                var params = makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil) ?? []
                params.append(contentsOf: (additional ?? [])
                    .map { URLQueryItem(name: "any[]", value: $0) })
                return params
        }
    }
}

public enum Statuses: Endpoint {
    case postStatus(json: StatusData)
    case editStatus(id: String, json: StatusData)
    case status(id: String)
    case context(id: String)
    case favorite(id: String)
    case unfavorite(id: String)
    case reblog(id: String)
    case unreblog(id: String)
    case rebloggedBy(id: String, maxId: String?)
    case favoritedBy(id: String, maxId: String?)
    case pin(id: String)
    case unpin(id: String)
    case bookmark(id: String)
    case unbookmark(id: String)
    case history(id: String)
    case translate(id: String, lang: String?)
    case report(accountId: String, statusId: String, comment: String)
    
    public func path() -> String {
        switch self {
            case .postStatus:
                "statuses"
            case let .status(id):
                "statuses/\(id)"
            case let .editStatus(id, _):
                "statuses/\(id)"
            case let .context(id):
                "statuses/\(id)/context"
            case let .favorite(id):
                "statuses/\(id)/favourite"
            case let .unfavorite(id):
                "statuses/\(id)/unfavourite"
            case let .reblog(id):
                "statuses/\(id)/reblog"
            case let .unreblog(id):
                "statuses/\(id)/unreblog"
            case let .rebloggedBy(id, _):
                "statuses/\(id)/reblogged_by"
            case let .favoritedBy(id, _):
                "statuses/\(id)/favourited_by"
            case let .pin(id):
                "statuses/\(id)/pin"
            case let .unpin(id):
                "statuses/\(id)/unpin"
            case let .bookmark(id):
                "statuses/\(id)/bookmark"
            case let .unbookmark(id):
                "statuses/\(id)/unbookmark"
            case let .history(id):
                "statuses/\(id)/history"
            case let .translate(id, _):
                "statuses/\(id)/translate"
            case .report:
                "reports"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        switch self {
            case let .rebloggedBy(_, maxId):
                return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
            case let .favoritedBy(_, maxId):
                return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
            case let .translate(_, lang):
                if let lang {
                    return [.init(name: "lang", value: lang)]
                }
                return nil
            case let .report(accountId, statusId, comment):
                return [.init(name: "account_id", value: accountId),
                        .init(name: "status_ids[]", value: statusId),
                        .init(name: "comment", value: comment)]
            default:
                return nil
        }
    }
    
    public var jsonValue: Encodable? {
        switch self {
            case let .postStatus(json):
                json
            case let .editStatus(_, json):
                json
            default:
                nil
        }
    }
}

public struct StatusData: Encodable, Sendable {
    public let status: String
    public let visibility: Visibility
    public let inReplyToId: String?
    public let spoilerText: String?
    public let mediaIds: [String]?
    public let poll: PollData?
    public let language: String?
    public let mediaAttributes: [MediaAttribute]?
    
    public struct PollData: Encodable, Sendable {
        public let options: [String]
        public let multiple: Bool
        public let expires_in: Int
        
        public init(options: [String], multiple: Bool, expires_in: Int) {
            self.options = options
            self.multiple = multiple
            self.expires_in = expires_in
        }
    }
    
    public struct MediaAttribute: Encodable, Sendable {
        public let id: String
        public let description: String?
        public let thumbnail: String?
        public let focus: String?
        
        public init(id: String, description: String?, thumbnail: String?, focus: String?) {
            self.id = id
            self.description = description
            self.thumbnail = thumbnail
            self.focus = focus
        }
    }
    
    public init(status: String,
                visibility: Visibility,
                inReplyToId: String? = nil,
                spoilerText: String? = nil,
                mediaIds: [String]? = nil,
                poll: PollData? = nil,
                language: String? = nil,
                mediaAttributes: [MediaAttribute]? = nil)
    {
        self.status = status
        self.visibility = visibility
        self.inReplyToId = inReplyToId
        self.spoilerText = spoilerText
        self.mediaIds = mediaIds
        self.poll = poll
        self.language = language
        self.mediaAttributes = mediaAttributes
    }
}

public enum Trends: Endpoint {
    case tags
    case statuses(offset: Int?)
    case links
    
    public func path() -> String {
        switch self {
            case .tags:
                "trends/tags"
            case .statuses:
                "trends/statuses"
            case .links:
                "trends/links"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        switch self {
            case let .statuses(offset):
                if let offset {
                    return [.init(name: "offset", value: String(offset))]
                }
                return nil
            default:
                return nil
        }
    }
}
