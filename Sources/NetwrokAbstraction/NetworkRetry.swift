import Foundation

enum NetworkRetry {
    case retry
    case retryWithDelay(TimeInterval)
    case doNotRetry
}
