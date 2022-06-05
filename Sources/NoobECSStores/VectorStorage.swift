import NoobECS

/// Vector storage stores the Components in a simple Swift Array called `buffer`. The 
/// `buffer` itself should be never copied. 
/// 
/// The storage is designed to Components, that won't be destroyed often, so fragmentation
/// would not be an issue.
/// 
/// If an instance of Component is destroyed, the void space left after it is stored in 
/// array of `freedIndicies` and assigned to an instance of new Component when needed.
public final class VectorStorage<C: Component>: ComponentStore {
    public typealias StoreOptions = Void
    public typealias ComponentIdentifier = Int
    public typealias StoredComponent = C

    public let type: OpaqueComponent.Type = C.self
    public var buffer: [StoreItem<C>?] = []

    private(set) public var freedIndicies: [Int] = []

    public init() { }

    public func store(item: StoreItem<C>, with options: Void) throws -> Int {
        if let allocated = freedIndicies.popLast() {
            buffer[allocated] = item
            return allocated
        }

        buffer.append(item)
        return buffer.count - 1
    }

    public func access<R>(at identifier: inout Any, validityScope: (inout StoredComponent) throws -> R) rethrows -> R? {
        try validityScope(&buffer[identifier as! ComponentIdentifier]!.value)
    }

    public func destroy(at index: Int) {
        freedIndicies.append(index)
        buffer[index]?.value.destroy()
        buffer[index] = nil
    }
}