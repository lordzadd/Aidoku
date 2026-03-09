import Foundation

public protocol MangaRepository: Sendable {
    func library() async throws -> [Manga]
    func upsert(_ manga: Manga) async throws
    func manga(identifier: MangaIdentifier) async throws -> Manga?
}

public protocol ChapterRepository: Sendable {
    func chapters(for manga: MangaIdentifier) async throws -> [Chapter]
    func upsertChapters(_ chapters: [Chapter], for manga: MangaIdentifier) async throws
    func setRead(_ isRead: Bool, chapter: ChapterIdentifier) async throws
}

public protocol HistoryRepository: Sendable {
    func recent(limit: Int) async throws -> [HistoryEntry]
    func add(_ entry: HistoryEntry) async throws
}

public protocol DownloadRepository: Sendable {
    func enqueuedDownloads() async throws -> [DownloadItem]
    func enqueue(_ item: DownloadItem) async throws
    func update(_ item: DownloadItem) async throws
}

public protocol AuthTokenStore: Sendable {
    func token(for tracker: TrackerKind) async throws -> String?
    func setToken(_ token: String, for tracker: TrackerKind) async throws
    func clearToken(for tracker: TrackerKind) async throws
}

public protocol TrackerClient: Sendable {
    var kind: TrackerKind { get }
    func isAuthenticated() async throws -> Bool
    func search(title: String) async throws -> [TrackedManga]
    func update(remoteID: String, progress: TrackerProgress) async throws
}

public protocol ScriptExecutor: Sendable {
    func execute(script: String, context: [String: String]) async throws -> String
}

public protocol SourceRuntime: Sendable {
    func search(sourceKey: String, query: String) async throws -> [Manga]
    func chapters(sourceKey: String, mangaKey: String) async throws -> [Chapter]
}

public protocol ImageLoader: Sendable {
    func loadData(from url: URL) async throws -> Data
}

public protocol FileStore: Sendable {
    func put(_ data: Data, at path: String) async throws
    func read(at path: String) async throws -> Data
    func remove(at path: String) async throws
}

public struct AidokuPlatformServices: Sendable {
    public let mangaRepository: MangaRepository
    public let chapterRepository: ChapterRepository
    public let historyRepository: HistoryRepository
    public let downloadRepository: DownloadRepository
    public let tokenStore: AuthTokenStore
    public let trackers: [TrackerKind: TrackerClient]
    public let sourceRuntime: SourceRuntime
    public let scriptExecutor: ScriptExecutor
    public let imageLoader: ImageLoader
    public let fileStore: FileStore

    public init(
        mangaRepository: MangaRepository,
        chapterRepository: ChapterRepository,
        historyRepository: HistoryRepository,
        downloadRepository: DownloadRepository,
        tokenStore: AuthTokenStore,
        trackers: [TrackerKind: TrackerClient],
        sourceRuntime: SourceRuntime,
        scriptExecutor: ScriptExecutor,
        imageLoader: ImageLoader,
        fileStore: FileStore
    ) {
        self.mangaRepository = mangaRepository
        self.chapterRepository = chapterRepository
        self.historyRepository = historyRepository
        self.downloadRepository = downloadRepository
        self.tokenStore = tokenStore
        self.trackers = trackers
        self.sourceRuntime = sourceRuntime
        self.scriptExecutor = scriptExecutor
        self.imageLoader = imageLoader
        self.fileStore = fileStore
    }
}
