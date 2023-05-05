import Foundation

protocol NetworkInterceptor {
    func beforeRequest(_ urlRequest: URLRequest)
    func afterRequest(_ urlRequest: URLRequest, response: URLResponse?, completion: (NetworkRetry) -> Void)
}
