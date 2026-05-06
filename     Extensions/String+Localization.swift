import Foundation

extension String {
    func localized(_ fallback: String) -> String {
        NSLocalizedString(self, value: fallback, comment: "")
    }
}
