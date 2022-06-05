#if TESTING
import Foundation

extension Collection where Element == Range<Int>, Index == Int {
    var isStrictContinuation: Bool {
        for (prevIndex, item) in self.dropFirst().enumerated() {
            guard self[prevIndex].upperBound == item.lowerBound else {
                return false
            }
        }

        return true
    }

    var isContinuation: Bool {
        for (prevIndex, item) in self.dropFirst().enumerated() {
            guard self[prevIndex].upperBound <= item.lowerBound else {
                return false
            }
        }

        return true
    }
}
#endif