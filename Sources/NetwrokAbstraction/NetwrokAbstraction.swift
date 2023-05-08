import Foundation

public protocol NetworkAbstractionInterface {
    func request(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

public class NetworkAbstraction: NetworkAbstractionInterface {
    private let queue = DispatchQueue(label: "com.app.networking", attributes: .concurrent)

    private let interceptor: NetworkInterceptor?
    private let core: NetworkInterface
    
    public init(core: NetworkInterface, interceptor: NetworkInterceptor? = nil) {
        self.interceptor = interceptor
        self.core = core
    }
    
    public func request(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let modifiedRequest = interceptor?.beforeRequest(request) ?? request
        queue.async(qos: .userInitiated) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.core.request(modifiedRequest) { data, response, error in
                strongSelf.interceptor?.afterRequest(request, response: response) { retryMechanism in
                    switch retryMechanism {
                    case .retry:
                        strongSelf.request(request) { data, response, error in
                            DispatchQueue.main.async {
                                completion(data, response, error)
                            }
                        }
                    case .retryWithDelay(let timeInterval):
                        strongSelf.queue.asyncAfter(deadline: .now() + timeInterval, qos: .userInitiated) {
                            strongSelf.request(request) { data, response, error in
                                DispatchQueue.main.async {
                                    completion(data, response, error)
                                }
                            }
                        }
                    case .doNotRetry:
                        break
                    }
                }
                
                DispatchQueue.main.async {
                    completion(data, response, error)
                }
            }
        }
    }
}
