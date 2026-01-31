import Foundation

/// Pull request status
struct PRStatus: Equatable {
    let number: Int
    let state: String  // OPEN, CLOSED, MERGED
    let url: String
    let title: String?

    var isOpen: Bool {
        state.uppercased() == "OPEN"
    }

    var isMerged: Bool {
        state.uppercased() == "MERGED"
    }
}

