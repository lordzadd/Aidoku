//
//  LibraryView.swift
//  Aidoku (macOS)
//
//  Created by Skitty on 1/2/22.
//

import SwiftUI

private enum MacRootSection: String, CaseIterable, Hashable {
    case library
    case browse
    case history
    case search
    case settings

    var title: String {
        switch self {
            case .library: NSLocalizedString("LIBRARY", comment: "")
            case .browse: NSLocalizedString("BROWSE", comment: "")
            case .history: NSLocalizedString("HISTORY", comment: "")
            case .search: NSLocalizedString("SEARCH", comment: "")
            case .settings: NSLocalizedString("SETTINGS", comment: "")
        }
    }

    var icon: String {
        switch self {
            case .library: "books.vertical.fill"
            case .browse: "globe"
            case .history: "clock.fill"
            case .search: "magnifyingglass"
            case .settings: "gear"
        }
    }
}

struct LibraryView: View {
    @State private var selection: MacRootSection? = .library

    var body: some View {
        if #available(macOS 13.0, *) {
            NavigationSplitView {
                sidebarView
            } detail: {
                detailView(for: selection ?? .library)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            NavigationView {
                sidebarView
                detailView(for: selection ?? .library)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var sidebarView: some View {
        List(MacRootSection.allCases, id: \.self, selection: $selection) { section in
            Label(section.title, systemImage: section.icon)
                .tag(section)
        }
        .navigationTitle("Aidoku")
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private func detailView(for section: MacRootSection) -> some View {
        switch section {
            case .library:
                MacLibrarySectionView()
            case .browse:
                PlaceholderSectionView(
                    title: NSLocalizedString("BROWSE", comment: ""),
                    subtitle: "Browse sources and updates"
                )
            case .history:
                PlaceholderSectionView(
                    title: NSLocalizedString("HISTORY", comment: ""),
                    subtitle: "Reading history"
                )
            case .search:
                PlaceholderSectionView(
                    title: NSLocalizedString("SEARCH", comment: ""),
                    subtitle: "Global search"
                )
            case .settings:
                PlaceholderSectionView(
                    title: NSLocalizedString("SETTINGS", comment: ""),
                    subtitle: "Application settings"
                )
        }
    }
}

@MainActor
private final class MacLibraryDataModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published private(set) var manga: [MangaInfo] = []

    var filteredManga: [MangaInfo] {
        guard !searchQuery.isEmpty else { return manga }
        return manga.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(searchQuery) ||
            ($0.author ?? "").localizedCaseInsensitiveContains(searchQuery)
        }
    }

    func loadLibrary() {
        manga = CoreDataManager.shared.getLibraryManga()
            .compactMap { object in
                guard let manga = object.manga?.toManga() else {
                    return nil
                }
                return MangaInfo(
                    mangaId: manga.id,
                    sourceId: manga.sourceId,
                    coverUrl: manga.coverUrl,
                    title: manga.title,
                    author: manga.author,
                    url: manga.url
                )
            }
            .sorted { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending }
    }
}

private struct MacLibrarySectionView: View {
    @StateObject private var model = MacLibraryDataModel()

    var body: some View {
        List(model.filteredManga, id: \.identifier) { manga in
            VStack(alignment: .leading, spacing: 2) {
                Text(manga.title ?? NSLocalizedString("UNTITLED", comment: ""))
                    .font(.headline)
                if let author = manga.author, !author.isEmpty {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
        .overlay {
            if model.filteredManga.isEmpty {
                PlaceholderSectionView(
                    title: NSLocalizedString("LIBRARY", comment: ""),
                    subtitle: NSLocalizedString("NO_RESULTS_FOUND", comment: "")
                )
            }
        }
        .searchable(text: $model.searchQuery, placement: .toolbar, prompt: NSLocalizedString("SEARCH", comment: ""))
        .navigationTitle(NSLocalizedString("LIBRARY", comment: ""))
        .task {
            model.loadLibrary()
        }
        .refreshable {
            model.loadLibrary()
        }
    }
}

private struct PlaceholderSectionView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text(subtitle)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}
