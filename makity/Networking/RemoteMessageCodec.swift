import Foundation

enum RemoteMessageCodec {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func encodeFrame(_ message: RemoteMessage) throws -> Data {
        let payload = try encoder.encode(message)
        guard payload.count <= Int(UInt32.max) else {
            throw RemoteMessageCodecError.payloadTooLarge
        }

        var length = UInt32(payload.count).bigEndian
        var frame = Data(bytes: &length, count: MemoryLayout<UInt32>.size)
        frame.append(payload)
        return frame
    }

    static func decode(_ data: Data) throws -> RemoteMessage {
        try decoder.decode(RemoteMessage.self, from: data)
    }

    static func frameLength(from data: Data) -> Int? {
        guard data.count == MemoryLayout<UInt32>.size else { return nil }
        let value = data.reduce(UInt32(0)) { partialResult, byte in
            (partialResult << 8) | UInt32(byte)
        }
        return Int(value)
    }
}

enum RemoteMessageCodecError: LocalizedError {
    case payloadTooLarge
    case invalidLengthPrefix

    var errorDescription: String? {
        switch self {
        case .payloadTooLarge:
            return "The encoded message is too large to send."
        case .invalidLengthPrefix:
            return "The incoming TCP frame has an invalid length prefix."
        }
    }
}
