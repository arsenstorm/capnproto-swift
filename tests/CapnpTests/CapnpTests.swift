import XCTest
@testable import Capnp

final class CapnpTests: XCTestCase {
    func testVersionIsNonZero() {
        let version = Capnp.version
        XCTAssertGreaterThanOrEqual(version.major, 0)
        XCTAssertGreaterThanOrEqual(version.minor, 0)
        XCTAssertGreaterThanOrEqual(version.micro, 0)
    }

    func testMessageBuilderAndReaderRoundTrip() {
        guard let builder = CapnpMessageBuilder() else {
            XCTFail("Failed to create CapnpMessageBuilder")
            return
        }
        XCTAssertNotNil(builder.opaque)

        guard let bytes = builder.toBytes() else {
            XCTFail("Failed to serialize message builder to bytes")
            return
        }
        XCTAssertFalse(bytes.isEmpty)

        guard let reader = CapnpMessageReader(data: bytes, format: .unpacked) else {
            XCTFail("Failed to create CapnpMessageReader")
            return
        }
        XCTAssertNotNil(reader.opaque)
    }
}
