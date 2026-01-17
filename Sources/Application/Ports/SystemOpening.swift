import Foundation

protocol SystemOpening {
    func openURL(_ url: URL)
    func revealInFinder(path: String)
    func openTerminal(atPath path: String)
}

