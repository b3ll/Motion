import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MotionTests.allTests),
        testCase(MotionPerformanceTests.allTests)
    ]
}
#endif
