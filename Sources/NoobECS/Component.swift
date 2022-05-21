public protocol OpaqueComponent {
    func destroy()
}

public protocol OpaqueComponentStore {
    var type: OpaqueComponent.Type { get }
    func destroy(at index: Any) 
}

public protocol ComponentStore: OpaqueComponentStore {
    associatedtype StoreOptions
    associatedtype ComponentIdentifier
    associatedtype StoredComponent: Component

    init()
    func allocInit(for entity: Entity, options: StoreOptions, with arguments: StoredComponent.InitArguments) throws -> ComponentIdentifier
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

    func allocInit(for entity: Entity, options: StoreOptions, with arguments: StoredComponent.InitArguments) throws -> ComponentIdentifier {
        try StoredComponent.init(entity: entity, arguments: arguments)
    }
}

public extension ComponentStore where StoreOptions == Void {
    func allocInit(for entity: Entity, with arguments: StoredComponent.InitArguments) throws -> ComponentIdentifier {
        try allocInit(for: entity, options: (), with: arguments)
    }
}

public extension ComponentStore {
    func destroy(at index: Any) {
        destroy(at: index as! ComponentIdentifier)
    }
}

public protocol Component: OpaqueComponent {
    associatedtype InitArguments
    associatedtype Store: ComponentStore

    /// MUST be unowned(unsafe)
    var entity: Entity? { get set }

    init(entity: Entity, arguments: InitArguments) throws
}

public extension Component {
    var isValid: Bool { entity != nil }
}
