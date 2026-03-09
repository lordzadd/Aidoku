import Foundation

public struct MangaIdentifier: Hashable, Codable, Sendable {
    public let sourceKey: String
    public let mangaKey: String

    public init(sourceKey: String, mangaKey: String) {
        self.sourceKey = sourceKey
        self.mangaKey = mangaKey
    }
}

public struct ChapterIdentifier: Hashable, Codable, Sendable {
    public let sourceKey: String
    public let mangaKey: String
    public let chapterKey: String

    public init(sourceKey: String, mangaKey: String, chapterKey: String) {
        self.sourceKey = sourceKey
        self.mangaKey = mangaKey
        self.chapterKey = chapterKey
    }
}

public enum MangaStatus: String, Codable, Sendable {
    case unknown
    case ongoing
    case completed
    case hiatus
    case cancelled
}

public struct Manga: Hashable, Codable, Sendable {
    public let identifier: MangaIdentifier
    public var title: String
    public var author: String?
    public var artist: String?
    public var description: String?
    public var tags: [String]
    public var coverURL: URL?
    public var status: MangaStatus

    public init(
        identifier: MangaIdentifier,
        title: String,
        author: String? = nil,
        artist: String? = nil,
        description: String? = nil,
        tags: [String] = [],
        coverURL: URL? = nil,
        status: MangaStatus = .unknown
    ) {
        self.identifier = identifier
        self.title = title
        self.author = author
        self.artist = artist
        self.description = description
        self.tags = tags
        self.coverURL = coverURL
        self.status = status
    }
}

public struct Chapter: Hashable, Codable, Sendable {
    public let identifier: ChapterIdentifier
    public var title: String
    public var chapterNumber: Double?
    public var dateUploaded: Date?
    public var isRead: Bool

    public init(
        identifier: ChapterIdentifier,
        title: String,
        chapterNumber: Double? = nil,
        dateUploaded: Date? = nil,
        isRead: Bool = false
    ) {
        self.identifier = identifier
        self.title = title
        self.chapterNumber = chapterNumber
        self.dateUploaded = dateUploaded
        self.isRead = isRead
    }
}

public struct HistoryEntry: Hashable, Codable, Sendable {
    public let chapterIdentifier: ChapterIdentifier
    public var openedAt: Date
    public var progress: Double

    public init(chapterIdentifier: ChapterIdentifier, openedAt: Date, progress: Double) {
        self.chapterIdentifier = chapterIdentifier
        self.openedAt = openedAt
        self.progress = progress
    }
}

public enum DownloadStatus: String, Codable, Sendable {
    case queued
    case running
    case completed
    case failed
}

public struct DownloadItem: Hashable, Codable, Sendable {
    public let chapterIdentifier: ChapterIdentifier
    public var status: DownloadStatus
    public var localPath: String?

    public init(chapterIdentifier: ChapterIdentifier, status: DownloadStatus, localPath: String? = nil) {
        self.chapterIdentifier = chapterIdentifier
        self.status = status
        self.localPath = localPath
    }
}

public enum TrackerKind: String, Codable, Sendable {
    case anilist
    case myanimelist
}

public struct TrackerProgress: Hashable, Codable, Sendable {
    public var status: String?
    public var score: Double?
    public var lastReadChapter: Int?
    public var lastReadVolume: Int?

    public init(status: String? = nil, score: Double? = nil, lastReadChapter: Int? = nil, lastReadVolume: Int? = nil) {
        self.status = status
        self.score = score
        self.lastReadChapter = lastReadChapter
        self.lastReadVolume = lastReadVolume
    }
}

public struct TrackedManga: Hashable, Codable, Sendable {
    public var tracker: TrackerKind
    public var remoteID: String
    public var title: String
    public var progress: TrackerProgress

    public init(tracker: TrackerKind, remoteID: String, title: String, progress: TrackerProgress) {
        self.tracker = tracker
        self.remoteID = remoteID
        self.title = title
        self.progress = progress
    }
}
