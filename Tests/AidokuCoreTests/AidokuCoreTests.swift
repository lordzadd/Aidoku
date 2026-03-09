import XCTest
import AidokuCore
import AidokuBootstrap

final class AidokuCoreTests: XCTestCase {
    func testAppleBootstrapSupportsBasicLibraryFlow() async throws {
        let services = AidokuBootstrap.make(platform: .apple)
        let manga = Manga(
            identifier: MangaIdentifier(sourceKey: "test-source", mangaKey: "manga-1"),
            title: "One Piece"
        )

        try await services.mangaRepository.upsert(manga)
        let library = try await services.mangaRepository.library()

        XCTAssertEqual(library.count, 1)
        XCTAssertEqual(library.first?.identifier, manga.identifier)
    }

    func testAndroidBootstrapSupportsTokenStore() async throws {
        let services = AidokuBootstrap.make(platform: .android)

        try await services.tokenStore.setToken("token123", for: .anilist)
        let token = try await services.tokenStore.token(for: .anilist)

        XCTAssertEqual(token, "token123")
    }

    func testDownloadRepositoryRoundTrip() async throws {
        let services = AidokuBootstrap.make(platform: .android)
        let chapter = ChapterIdentifier(sourceKey: "source", mangaKey: "manga", chapterKey: "ch-1")
        let item = DownloadItem(chapterIdentifier: chapter, status: .queued)

        try await services.downloadRepository.enqueue(item)
        var downloads = try await services.downloadRepository.enqueuedDownloads()
        XCTAssertEqual(downloads.first?.status, .queued)

        var updated = item
        updated.status = .completed
        try await services.downloadRepository.update(updated)

        downloads = try await services.downloadRepository.enqueuedDownloads()
        XCTAssertEqual(downloads.first?.status, .completed)
    }
}
