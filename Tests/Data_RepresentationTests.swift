//  Data_RepresentationTests.swift

import Foundation
import XCTest
@testable import LogHub

class Data_RepresentationTests: XCTestCase {

    func test_representation() {
        
        let input = "value"
        let data = input.data(using: String.Encoding.utf8)!
        
        let representation = input
        let target = data.stringRepresentation()
        
        XCTAssertEqual(representation, target)
    }
}
