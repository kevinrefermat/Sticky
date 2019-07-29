import XCTest

import StickyTests

var tests = [XCTestCaseEntry]()
tests += StickyTests.allTests()
XCTMain(tests)
