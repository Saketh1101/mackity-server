import Foundation
import Network

struct DiscoveredMac: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let endpoint: NWEndpoint
    let lastSeen: Date

    init(name: String, endpoint: NWEndpoint, lastSeen: Date = Date()) {
        self.name = name
        self.endpoint = endpoint
        self.lastSeen = lastSeen
        self.id = endpoint.stableIdentifier
    }

    static func == (lhs: DiscoveredMac, rhs: DiscoveredMac) -> Bool {
        lhs.id == rhs.id
    }
}

extension NWEndpoint {
    var stableIdentifier: String {
        switch self {
        case .hostPort(let host, let port):
            return "\(host):\(port.rawValue)"
        case .service(let name, let type, let domain, let interface):
            return "\(name).\(type).\(domain).\(interface?.debugDescription ?? "any")"
        case .unix(let path):
            return path
        case .url(let url):
            return url.absoluteString
        case .opaque:
            return debugDescription
        @unknown default:
            return debugDescription
        }
    }

    var displayName: String {
        switch self {
        case .service(let name, _, _, _):
            return name
        case .hostPort(let host, let port):
            return "\(host):\(port.rawValue)"
        default:
            return debugDescription
        }
    }
}
