import XCTest

import jiraTests

var tests = [XCTestCaseEntry]()
tests += jiraTests.allTests()
XCTMain(tests)
