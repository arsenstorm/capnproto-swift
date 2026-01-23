import CapnpCLib
import Foundation

public enum Capnp {
    public static var version: (major: Int, minor: Int, micro: Int) {
        (
            major: Int(capnp_c_version_major()),
            minor: Int(capnp_c_version_minor()),
            micro: Int(capnp_c_version_micro())
        )
    }
}

public final class CapnpMessageBuilder {
    private let handle: OpaquePointer

    public init?() {
        guard let ptr = capnp_c_message_builder_new() else {
            return nil
        }
        self.handle = ptr
    }

    deinit {
        capnp_c_message_builder_free(handle)
    }

    public var opaque: UnsafeMutableRawPointer? {
        capnp_c_message_builder_get(handle)
    }

    public func toBytes() -> Data? {
        var size: size_t = 0
        guard let buffer = capnp_c_message_builder_to_bytes(handle, &size) else {
            return nil
        }
        let data = Data(bytes: buffer, count: size)
        capnp_c_free(buffer)
        return data
    }
}

public final class CapnpMessageReader {
    private let handle: OpaquePointer

    public enum Format {
        case unpacked
        case packed
    }

    public init?(data: Data, format: Format = .unpacked) {
        let bytes = [UInt8](data)
        guard !bytes.isEmpty else {
            return nil
        }
        let ptr = bytes.withUnsafeBytes { raw -> OpaquePointer? in
            guard let base = raw.baseAddress else { return nil }
            let bytePtr = base.assumingMemoryBound(to: UInt8.self)
            switch format {
            case .unpacked:
                return capnp_c_message_reader_new_unpacked(bytePtr, raw.count)
            case .packed:
                return capnp_c_message_reader_new_packed(bytePtr, raw.count)
            }
        }
        guard let reader = ptr else {
            return nil
        }
        self.handle = reader
    }

    deinit {
        capnp_c_message_reader_free(handle)
    }

    public var opaque: UnsafeMutableRawPointer? {
        capnp_c_message_reader_get(handle)
    }
}
