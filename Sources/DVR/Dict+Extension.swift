import Foundation

extension Dictionary where Key == String {
    subscript(caseInsensitive key: Key) -> Value? {
        get {
            if let k = keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                return self[k]
            }
            return nil
        }
        set {
            if let k = keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                // remove the old key and set the new one
                self[k] = nil
                self[key] = newValue
            } else {
                self[key] = newValue
            }
        }
    }
}
