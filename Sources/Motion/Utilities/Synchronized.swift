import Foundation

final class Synchronized<Wrapped> {
    private var data: Wrapped
    private var lock = NSLock()
    
    init(data: Wrapped) {
        self.data = data
    }
    
    var value: Wrapped {
        get {
            with { data in
                data
            }
        }
        set {
            with { data in
                data = newValue
            }
        }
    }
    
    func with<T>(_ body: (inout Wrapped) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body(&self.data)
    }
}
