import NoobECS

/// This store does not store any Components. The Components are stored in their
/// Entities, taking advantage of the type-ereased nature of the Identifier.
/// 
/// Use this store for Components, that are not read frequently and don't need 
/// their own storage.
public final class EntityPrivateStorage<C: Component>: ComponentStore {
    public typealias StoreOptions = Void
    public typealias ComponentIdentifier = C
    public typealias StoredComponent = C

    public let type: OpaqueComponent.Type = C.self

    public init() { }

    public func access<R>(at identifier: inout Any, validityScope: (inout StoredComponent) throws -> R) rethrows -> R? {
        var typedCopy = identifier as! StoredComponent
        defer { identifier = typedCopy }
        return try validityScope(&typedCopy)
    }

    public func destroy(at index: ComponentIdentifier) {
        index.destroy()
    }

    public func store(item: StoreItem<StoredComponent>, with options: StoreOptions) throws -> ComponentIdentifier {
        item.value
    }
}
