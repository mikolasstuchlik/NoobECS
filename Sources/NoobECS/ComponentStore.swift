public protocol OpaqueComponentStore {
    var type: OpaqueComponent.Type { get }
    func destroy(at index: Any) 
}

public struct StoreItem<T> {
    public unowned(unsafe) let unownedEntity: Entity
    public var value: T
}

public protocol ComponentStore: OpaqueComponentStore {
    associatedtype StoreOptions
    associatedtype ComponentIdentifier
    associatedtype StoredComponent: Component

    init()
    func store(item: StoreItem<StoredComponent>, with options: StoreOptions) throws -> ComponentIdentifier
    func destroy(at identifier: ComponentIdentifier)
    func access<R>(at identifier: inout Any, validityScope: (inout StoredComponent) throws -> R) rethrows -> R?
}

public extension ComponentStore where ComponentIdentifier == StoredComponent {
    func access<R>(at identifier: inout Any, validityScope: (inout StoredComponent) throws -> R) rethrows -> R? {
        var typedCopy = identifier as! StoredComponent
        defer { identifier = typedCopy }
        return try validityScope(&typedCopy)
    }

    func destroy(at index: ComponentIdentifier) {
        index.destroy()
    }

    func store(item: StoreItem<StoredComponent>, with options: StoreOptions) throws -> ComponentIdentifier {
        item.value
    }
}

public extension ComponentStore where StoreOptions == Void {
    func store(item: StoreItem<StoredComponent>) throws -> ComponentIdentifier {
        try store(item: item, with: ())
    }
}

public extension ComponentStore {
    func destroy(at index: Any) {
        destroy(at: index as! ComponentIdentifier)
    }
}
