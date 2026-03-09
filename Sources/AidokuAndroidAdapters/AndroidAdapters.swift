import Foundation
import AidokuCore

public enum AndroidAdapterFactory {
    public static func makeServices(storageRootPath: String? = nil) -> AidokuPlatformServices {
        let mangaRepo = AndroidMangaRepository()
        let chapterRepo = AndroidChapterRepository()
        let historyRepo = AndroidHistoryRepository()
        let downloadRepo = AndroidDownloadRepository()
        let tokenStore = AndroidTokenStore()

        let anilist = AndroidTrackerClient(kind: .anilist)
        let mal = AndroidTrackerClient(kind: .myanimelist)

        let root = storageRootPath ?? FileManager.default.temporaryDirectory.path

        return AidokuPlatformServices(
            mangaRepository: mangaRepo,
            chapterRepository: chapterRepo,
            historyRepository: historyRepo,
            downloadRepository: downloadRepo,
            tokenStore: tokenStore,
            trackers: [.anilist: anilist, .myanimelist: mal],
            sourceRuntime: AndroidSourceRuntime(),
            scriptExecutor: AndroidScriptExecutor(),
            imageLoader: AndroidImageLoader(),
            fileStore: AndroidFileStore(rootPath: root)
        )
    }
}

actor AndroidMangaRepository: MangaRepository {
    private var items: [MangaIdentifier: Manga] = [:]

    func library() async throws -> [Manga] {
        items.values.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func upsert(_ manga: Manga) async throws {
        items[manga.identifier] = manga
    }

    func manga(identifier: MangaIdentifier) async throws -> Manga? {
        items[identifier]
    }
}

actor AndroidChapterRepository: ChapterRepository {
    private var chaptersByManga: [MangaIdentifier: [ChapterIdentifier: Chapter]] = [:]

    func chapters(for manga: MangaIdentifier) async throws -> [Chapter] {
        let byID = chaptersByManga[manga] ?? [:]
        return byID.values.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func upsertChapters(_ chapters: [Chapter], for manga: MangaIdentifier) async throws {
        var existing = chaptersByManga[manga] ?? [:]
        for chapter in chapters {
            existing[chapter.identifier] = chapter
        }
        chaptersByManga[manga] = existing
    }

    func setRead(_ isRead: Bool, chapter: ChapterIdentifier) async throws {
        let mangaID = MangaIdentifier(sourceKey: chapter.sourceKey, mangaKey: chapter.mangaKey)
        var existing = chaptersByManga[mangaID] ?? [:]
        guard var stored = existing[chapter] else {
            return
        }
        stored.isRead = isRead
        existing[chapter] = stored
        chaptersByManga[mangaID] = existing
    }
}

actor AndroidHistoryRepository: HistoryRepository {
    private var entries: [HistoryEntry] = []

    func recent(limit: Int) async throws -> [HistoryEntry] {
        Array(entries.sorted { $0.openedAt > $1.openedAt }.prefix(limit))
    }

    func add(_ entry: HistoryEntry) async throws {
        entries.append(entry)
    }
}

actor AndroidDownloadRepository: DownloadRepository {
    private var items: [ChapterIdentifier: DownloadItem] = [:]

    func enqueuedDownloads() async throws -> [DownloadItem] {
        items.values.sorted { $0.chapterIdentifier.chapterKey < $1.chapterIdentifier.chapterKey }
    }

    func enqueue(_ item: DownloadItem) async throws {
        items[item.chapterIdentifier] = item
    }

    func update(_ item: DownloadItem) async throws {
        items[item.chapterIdentifier] = item
    }
}

actor AndroidTokenStore: AuthTokenStore {
    private var tokens: [TrackerKind: String] = [:]

    func token(for tracker: TrackerKind) async throws -> String? {
        tokens[tracker]
    }

    func setToken(_ token: String, for tracker: TrackerKind) async throws {
        tokens[tracker] = token
    }

    func clearToken(for tracker: TrackerKind) async throws {
        tokens.removeValue(forKey: tracker)
    }
}

struct AndroidTrackerClient: TrackerClient {
    let kind: TrackerKind

    func isAuthenticated() async throws -> Bool {
        false
    }

    func search(title: String) async throws -> [TrackedManga] {
        [TrackedManga(tracker: kind, remoteID: "android-stub-\(title)", title: title, progress: TrackerProgress())]
    }

    func update(remoteID: String, progress: TrackerProgress) async throws {}
}

struct AndroidSourceRuntime: SourceRuntime {
    func search(sourceKey: String, query: String) async throws -> [Manga] {
        []
    }

    func chapters(sourceKey: String, mangaKey: String) async throws -> [Chapter] {
        []
    }
}

struct AndroidScriptExecutor: ScriptExecutor {
    func execute(script: String, context: [String: String]) async throws -> String {
        script + "::android"
    }
}

struct AndroidImageLoader: ImageLoader {
    func loadData(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}

struct AndroidFileStore: FileStore {
    private let rootPath: String

    init(rootPath: String) {
        self.rootPath = rootPath
    }

    func put(_ data: Data, at path: String) async throws {
        let fullURL = URL(fileURLWithPath: rootPath).appendingPathComponent(path)
        let directory = fullURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fullURL)
    }

    func read(at path: String) async throws -> Data {
        let fullURL = URL(fileURLWithPath: rootPath).appendingPathComponent(path)
        return try Data(contentsOf: fullURL)
    }

    func remove(at path: String) async throws {
        let fullURL = URL(fileURLWithPath: rootPath).appendingPathComponent(path)
        if FileManager.default.fileExists(atPath: fullURL.path) {
            try FileManager.default.removeItem(at: fullURL)
        }
    }
}
