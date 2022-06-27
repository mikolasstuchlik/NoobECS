/// Entities and Components are stored in a Data Manager. The Data Manager defines the 
/// lifetime of both Entites and Components. Each component holds an unowned(unsafe) 
/// reference to the Data Manager it belongs to. It does so in order to access 
/// the stores that contain the Component associated with it. The relation between Entity
/// and Data Manager is N:1.
public protocol EntityComponentDataManager: AnyObject {
    /// All entities owned by this manager. The only way to destroy an Entity is 
    /// to remove it from this collection. The Entity might live after it is removed
    /// from the entity list for convenience, but it must be guaranteed, that the entity
    /// does not outlive the Data Manager associated with it.
    var entities: [ObjectIdentifier: Entity] { get set }
    /// Storages for Components associated with the Entities stored in this Data Manager.
    var stores: [OpaqueComponentStore] { get set }

    /// Return existing or newly initialized instance of storage for provided Component type.
    /// - Parameter component: The type of the Component.
    func storage<C: Component>(for component: C.Type) -> C.Store

    /// Destroy an instance of a Component for specified Component type.
    /// - Parameters:
    ///   - component: Metatype of the Component to destroy.
    ///   - index: Index of the Component in Store associated with it.
    func destroy(opaque component: OpaqueComponent.Type, at index: Any)

    /// Gets called by entity destructor before it's components are unset
    /// - Parameters:
    ///   - entity: The entity being destroyed
    func willDestroy(entity: Entity)
}

public extension EntityComponentDataManager {
    func storage<C: Component>(for component: C.Type) -> C.Store {
        for store in stores where store is C.Store {
            return store as! C.Store
        }
        let new = C.Store()
        stores.append(new)
        return new
    }

    func destroy(opaque component: OpaqueComponent.Type, at index: Any) {
        for store in stores where store.type == component {
            store.destroy(at: index)
        }
    }

    func willDestroy(entity: Entity) { }
}
