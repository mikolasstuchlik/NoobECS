import NoobECS

public final class VectorStorage<C: Component>: ComponentStore {
    public typealias StoreOptions = Void
    public typealias ComponentIdentifier = Int
    public typealias StoredComponent = C

    public let type: OpaqueComponent.Type = C.self
    public var buffer: [C] = []

    private(set) var freedIndicies: [Int] = []

    public init() { }

    public func allocInit(for entity: Entity, options: StoreOptions, with arguments: StoredComponent.InitArguments) throws -> ComponentIdentifier {
        let new = try C.init(entity: entity, arguments: arguments)

        if let allocated = freedIndicies.popLast() {
            buffer[allocated] = new
            return allocated
        }

        buffer.append(new)
        return buffer.count - 1
    }

    public func access<R>(at identifier: inout Any, validityScope: (inout StoredComponent) throws -> R) rethrows -> R? {
        try validityScope(&buffer[identifier as! ComponentIdentifier])
    }

    public func destroy(at index: Int) {
        freedIndicies.append(index)
        buffer[index].destroy()
        buffer[index].entity = nil
    }
}