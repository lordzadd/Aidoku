//
//  FilterGroup.swift
//  Aidoku
//
//  Created by Skitty on 2/27/26.
//

struct SharedLibraryFilter: Codable, Hashable, Sendable {
    var type: SharedLibraryFilterMethod
    var value: String?
    var exclude: Bool
}

enum SharedLibraryFilterMethod: Int, Codable, CaseIterable, Sendable {
    case downloaded
    case tracking
    case hasUnread
    case started
    case completed
    case source
    case contentRating
    case category
}

struct FilterGroup: Equatable {
    let title: String
    let filters: [SharedLibraryFilter]

    static func == (lhs: FilterGroup, rhs: FilterGroup) -> Bool {
        lhs.title == rhs.title
    }
}
