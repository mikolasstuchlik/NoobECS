/// Type ereased protocol that represents an instance of ComponentStore.
public protocol OpaqueComponentStore {
    /// Type of the component associated with this Store instance.
    var type: OpaqueComponent.Type { get }

    /// Destroy an instance of an component at provided index.
    /// - Parameter index: Type ereased index.
    func destroy(at index: Any) 
}

/// Store item is a value-type container for instances of Component. It was introduced,
/// because it is simpler to provide default implementation for managing lifecycle
/// of such store item. It also solves some issues with space allocation, void spaces
/// and storeage of reference-type components.
public struct StoreItem<T: Component> {
    /// The unowned(unsafe) reference to the Entity that owns this item.
    public unowned(unsafe) let unownedEntity: Entity
    /// The instance of the component itself.
    public var value: T
}

/// Component store is a space, that stores instances of a Component of a specified type.
/// A Component store must allow to store, access and remove components stored inside of it.
/// Component store itself is stored alongside of Entities in EntityComponentDataManager. 
/// 
/// Component Sotre may implement various optimizations. It is generaly expected, that 
/// store/destroy operations would be much less frequent than access operations.
/// 
/// You are encouraged to use any collection (Array, R-Tree, ...) that fits your use
/// case the best. Some stores are provided in the `NoobECSStores` module.
/// 
/// The Component Store is absolutely encouraged to expose it's internal implementation
/// details and buffers, so the Systems using it would increase their performance.
public protocol ComponentStore: OpaqueComponentStore {
    /// Options, that are needed when an instance of compoent is being stored in order to provide 
    /// better efficiency.
    associatedtype StoreOptions
    /// Type, that identifies the instance of the component inside this store. Is is type
    /// ereased to Any in most contexts outside of this protocol.
    associatedtype ComponentIdentifier
    /// The type of component that is stored in the instance of this store.
    associatedtype StoredComponent: Component

    /// Component store may be initialized at any time by the EntityComponentDataManager.
    init()

    /// Store a new instance of an item. The instance is provided by an Entity. It is a calling convention,
    /// that the calling instance of Entity checks, whether an instance of the component associated with it
    /// exists in this store before calling this function. If it does, the Entity has to remove it first.
    /// - Parameters:
    ///   - item: The instance fully initialized component item that should be stored in this sotre.
    ///   - options: Options for the store associated with this component instance.
    /// - Returns: Idenitifier representing the component inside of this store.
    func store(item: StoreItem<StoredComponent>, with options: StoreOptions) throws -> ComponentIdentifier

    /// Destory the instance of the component stored with this identifier.
    /// - Parameter identifier: The identifier of the component in this store.
    func destroy(at identifier: ComponentIdentifier)

    /// Read/write access to the stored instance of the component.
    /// - Parameters:
    ///   - identifier: The identifier of the component in this store. The identifier is 
    /// inout because it provides a flexibility to the store, if the mutation in the block 
    /// requires some storage optimizations.
    ///   - validityScope: Block, that provides the inout reference to the stored component. Value 
    /// returned by this block is returned by the overall function call. If no such component exists 
    /// in this store, the block is not called and nil is returned to the caller.
    /// - Returns: The value returned by the block, or nil if the block was not called.
    func access<R>(at identifier: inout Any, validityScope: (inout StoredComponent) throws -> R) rethrows -> R?
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
