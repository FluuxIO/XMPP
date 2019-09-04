import XCTest

extension IQEncoderTests {
    static let __allTests = [
        ("testP1PushIQSet", testP1PushIQSet),
        ("testP1PushPayload", testP1PushPayload),
    ]
}

extension MobileProvisionTests {
    static let __allTests = [
        ("testDecodeMobileProvision", testDecodeMobileProvision),
    ]
}

extension SerializerTests {
    static let __allTests = [
        ("testAuth", testAuth),
        ("testCustom", testCustom),
        ("testEmptyPresence", testEmptyPresence),
        ("testError", testError),
        ("testPresence", testPresence),
        ("testPriority", testPriority),
        ("testShow", testShow),
    ]
}

extension XMPPTests {
    static let __allTests = [
        ("testExample", testExample),
        ("testPerformanceExample", testPerformanceExample),
    ]
}

#if os(Linux)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(IQEncoderTests.__allTests),
        testCase(MobileProvisionTests.__allTests),
        testCase(SerializerTests.__allTests),
        testCase(XMPPTests.__allTests),
    ]
}
#endif
