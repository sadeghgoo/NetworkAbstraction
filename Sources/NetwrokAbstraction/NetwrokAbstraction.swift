import Foundation

class NetworkAbstraction {
    private let queue = DispatchQueue(label: "com.app.networking", attributes: .concurrent)

    private let interceptor: NetworkInterceptor?
    private let session: URLSession
    
    init(interceptor: NetworkInterceptor? = nil, configuration: URLSessionConfiguration = .default) {
        self.interceptor = interceptor
        self.session = URLSession(configuration: configuration)
    }
    
    private func urlSessionDataTask(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        interceptor?.beforeRequest(request)
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let strongSelf = self else { return }
            strongSelf.interceptor?.afterRequest(request, response: response) { retryMechanism in
                switch retryMechanism {
                case .retry:
                    strongSelf.urlSessionDataTask(request, completion: completion)
                case .retryWithDelay(let timeInterval):
                    strongSelf.queue.asyncAfter(deadline: .now() + timeInterval) {
                        strongSelf.urlSessionDataTask(request, completion: completion)
                    }
                case .doNotRetry:
                    break
                }
            }
        }.resume()
    }
    
    private func makeRequest(_ request: Request, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        urlSessionDataTask(request.urlRequest) { [weak self] data, response, error in
            guard let strongSelf = self else { return }
            if let response {
                if !strongSelf.isValideURLResponse(response) {
                    completion(.failure(.invalidResponse))
                }
            }
            if let data {
                completion(.success(data))
                return
            }
            
            if let error {
                completion(.failure(.requestFailed(error)))
                return
            }
        }
    }
    
    private func isValideURLResponse(_ response: URLResponse) -> Bool {
        if let httpResponse = response as? HTTPURLResponse {
            return !(200...299).contains(httpResponse.statusCode)
        } else {
            return false
        }
    }
}

extension NetworkAbstraction {
    func get(_ url: URL, headers: [String: String] = [:], completion: @escaping (Result<Data, NetworkError>) -> Void) {
        let request = Request(url: url, method: .get, headers: headers, body: nil)
        makeRequest(request, completion: completion)
    }
    
    func post(_ url: URL, body: Data, headers: [String: String] = [:], completion: @escaping (Result<Data, NetworkError>) -> Void) {
        let request = Request(url: url, method: .post, headers: headers, body: body)
        makeRequest(request, completion: completion)
    }
}

extension NetworkAbstraction {
    struct Request {
        enum HttpMethod: String {
            case get = "GET"
            case post = "POST"
        }
        
        let url: URL
        let method: HttpMethod
        let headers: [String: String]
        let body: Data?
                
        var urlRequest: URLRequest {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.allHTTPHeaderFields = headers
            request.httpBody = body
            return request
        }
    }
}

extension NetworkAbstraction {
    enum NetworkError: Error {
        case invalidUrl
        case invalidResponse
        case requestFailed(Error)
    }
}
