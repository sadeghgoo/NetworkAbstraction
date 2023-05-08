import Foundation

public protocol NetworkInterceptor {
    func beforeRequest(_ urlRequest: URLRequest) -> URLRequest?
    func afterRequest(_ urlRequest: URLRequest, response: URLResponse?, completion: (NetworkRetry) -> Void)
}
