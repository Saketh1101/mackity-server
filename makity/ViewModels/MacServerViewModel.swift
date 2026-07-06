import Combine
import Foundation

#if os(macOS)
@MainActor
final class MacServerViewModel: ObservableObject {
    @Published private(set) var deviceName = DeviceInfoProvider.deviceName
    @Published private(set) var localIPAddress = DeviceInfoProvider.localIPAddress
    @Published var selectedDisplayIndex = 0

    let server = MacRemoteServer()

    private var cancellables: Set<AnyCancellable> = []

    init() {
        server.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var availableDisplayCount: Int {
        server.availableDisplayCount
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

    func switchDisplay(to index: Int) {
        selectedDisplayIndex = index
        server.switchDisplay(to: index)
    }
}
#endif
