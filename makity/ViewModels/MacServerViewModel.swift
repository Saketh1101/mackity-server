import Combine
import Foundation

#if os(macOS)
@MainActor
final class MacServerViewModel: ObservableObject {
    @Published private(set) var deviceName = DeviceInfoProvider.deviceName
    @Published private(set) var localIPAddress = DeviceInfoProvider.localIPAddress

    let server = MacRemoteServer()

    private var cancellables: Set<AnyCancellable> = []

    init() {
        server.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func refreshNetworkInfo() {
        deviceName = DeviceInfoProvider.deviceName
        localIPAddress = DeviceInfoProvider.localIPAddress
    }

    func toggleServer() {
        if server.isRunning {
            server.stop()
        } else {
            refreshNetworkInfo()
            server.start(deviceName: deviceName)
        }
    }
}
#endif
