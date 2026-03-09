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
        NavigationSplitView {
            List(MacRootSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("Aidoku")
            .listStyle(.sidebar)
        } detail: {
            detailView(for: selection ?? .library)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func detailView(for section: MacRootSection) -> some View {
        switch section {
            case .library:
                PlaceholderSectionView(
                    title: NSLocalizedString("LIBRARY", comment: ""),
                    subtitle: "iPad-style layout scaffold for macOS"
                )
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
