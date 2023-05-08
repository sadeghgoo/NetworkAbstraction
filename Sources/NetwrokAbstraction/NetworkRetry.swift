import Foundation

public enum NetworkRetry {
    case retry
    case retryWithDelay(TimeInterval)
    case doNotRetry
}
