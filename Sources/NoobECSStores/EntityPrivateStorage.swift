import NoobECS

public final class EntityPrivateStorage<C: Component>: ComponentStore {
    public typealias StoreOptions = Void
    public typealias ComponentIdentifier = C
    public typealias StoredComponent = C

    public let type: OpaqueComponent.Type = C.self

    public init() { }
}
