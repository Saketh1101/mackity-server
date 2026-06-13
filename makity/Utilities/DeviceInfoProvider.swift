import Foundation

#if canImport(Darwin)
import Darwin
#endif

enum DeviceInfoProvider {
    static var deviceName: String {
        #if os(macOS)
        Host.current().localizedName ?? Host.current().name ?? "MacRemote Mac"
        #else
        UIDevice.current.name
        #endif
    }

    static var localIPAddress: String {
        localIPv4Address() ?? "Unavailable"
    }

    private static func localIPv4Address() -> String? {
        var address: String?
        var interfacesPointer: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&interfacesPointer) == 0, let firstInterface = interfacesPointer else {
            return nil
        }

        defer { freeifaddrs(interfacesPointer) }

        for interface in sequence(first: firstInterface, next: { $0.pointee.ifa_next }) {
            let flags = Int32(interface.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) == IFF_UP
            let isRunning = (flags & IFF_RUNNING) == IFF_RUNNING
            let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK

            guard isUp, isRunning, !isLoopback else { continue }
            guard let socketAddress = interface.pointee.ifa_addr else { continue }
            guard socketAddress.pointee.sa_family == UInt8(AF_INET) else { continue }

            let name = String(cString: interface.pointee.ifa_name)
            guard name.hasPrefix("en") || name.hasPrefix("bridge") else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                socketAddress,
                socklen_t(socketAddress.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            if result == 0 {
                address = String(cString: hostname)
                break
            }
        }

        return address
    }
}

#if os(iOS)
import UIKit
#endif
