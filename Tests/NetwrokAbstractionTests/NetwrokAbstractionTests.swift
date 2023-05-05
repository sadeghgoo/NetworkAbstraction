import XCTest
@testable import NetwrokAbstraction

final class NetwrokAbstractionTests: XCTestCase {
    func testExample() throws {
        let networking = NetworkAbstraction()
        let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")
        XCTAssertNotNil(url)
        networking.get(url!) { result in
            switch result {
            case .success(let data):
                break
            case .failure(let error):
                break
            }
        }
    }
}
