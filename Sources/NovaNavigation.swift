import Foundation

enum NovaNavigation {
    enum Destination: Equatable {
        case website(URL)
        case search(String)
    }

    static func resolve(_ text: String) -> Destination? {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return nil }

        if let components = URLComponents(string: input),
           let scheme = components.scheme?.lowercased(),
           (scheme == "http" || scheme == "https"),
           components.host != nil, let url = components.url {
            return .website(url)
        }

        let localPattern = #"^(localhost|127\.0\.0\.1)(:\d+)?([/?#]|$)"#
        if input.range(of: localPattern, options: [.regularExpression, .caseInsensitive]) != nil,
           let url = URL(string: "http://\(input)") {
            return .website(url)
        }

        if input.contains(where: { $0.isWhitespace }) || !input.contains(".") {
            return .search(input)
        }

        guard let components = URLComponents(string: "https://\(input)"),
              components.host != nil, let url = components.url else { return nil }
        return .website(url)
    }
}
