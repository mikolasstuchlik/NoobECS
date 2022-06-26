import Foundation

/// Entity represents a singular object in the game.
/// 
/// Entity is responsible for keeping track of Components associated with it.
/// Entity has unowned reference to it's data manager which it should never outlive. 
/// You should never store any strong reference that may outlive the dataManager.
///
/// The identifier of an instance of Entity is the memory address. It does not ensure
/// uniqueness in a long-running application, but it's good-enough solution with interesting
/// side effects. If the reference to the Entity is stored as an identifier, it should be stored
/// as an unowned(unsafe) reference.
public final class Entity: Hashable {

    /// Container used to store references to individual components.
    public struct ComponentReference {
        /// The type of the component.
        public let type: OpaqueComponent.Type
        /// Opaque identifier of the component. Type of identifier completely depends on the Component.
        /// 
        /// Identifier is of type Any. This implies, that there is 3-pointer wide buffer inline and an 
        /// ISA pointer. If an identifier is a value-type that is more than 3 pointers in size, there is 
        /// a mandatory heap allocation.
        public var identifier: Any
    }

    /// Unowned reference to data manager which manages this entity.
    public unowned(unsafe) let dataManager: EntityComponentDataManager

    /// Storage for references to components associated with this entity.
    /// It is guaranteed, that if component reference exists in this array, it also
    /// exists in the component storage belonging to this component in the
    /// data manager which manages this entity.
    public private(set) var componentReferences: [ComponentReference] = []

    /// Optional label for developer's convenience.
    public var developerLabel: String?

    /// Initialize new Entity.
    /// - Parameters:
    ///   - dataManager: Data manager which will store and manage this entity.
    ///   - developerLabel: Optional label for developer's convenience.
    public init(dataManager: EntityComponentDataManager, developerLabel: String? = nil) {
        self.dataManager = dataManager
        self.developerLabel = developerLabel
        dataManager.entities[ObjectIdentifier(self)] = self
    }

    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }

    /// Test, whether entity has a reference to following component.
    /// - Parameter component: Component to be tested.
    public func has<C: Component>(component: C.Type) -> Bool {
        componentReferences.contains { $0.type == C.self }
    }

    /// Assign new instance of a component to this entity. If component of the same type already
    /// exists, it is destroyed and replaced by new one.
    /// - Parameters:
    ///   - component: Type of the component.
    ///   - arguments: Arguments that are needed to initialize the new component.
    public func assign<C: Component>(component: C.Type, arguments: C.Store.StoredComponent.InitArguments) throws where C.Store.StoreOptions == Void {
        try assign(component: C.self, options: (), arguments: arguments)
    }

    /// Assign new instance of a component to this entity. If component of the same type already
    /// exists, it is destroyed and replaced by new one.
    /// - Parameters:
    ///   - component: Type of the component.
    ///   - options: Additional options for the component store required to store the new component properly.
    ///   - arguments: Arguments that are needed to initialize the new component.
    public func assign<C: Component>(component: C.Type, options: C.Store.StoreOptions, arguments: C.Store.StoredComponent.InitArguments) throws {
        let storage = dataManager.storage(for: C.self)
        let newItem = StoreItem<C.Store.StoredComponent>(
            unownedEntity: self, 
            value: try C.Store.StoredComponent.init(arguments: arguments)
        )

        if let oldIndex = index(of: C.self) {
            storage.destroy(at: componentReferences[oldIndex].identifier)
            componentReferences[oldIndex].identifier = ComponentReference(
                type: C.self, 
                identifier: try storage.store(item: newItem, with: options)
            )
        } else {
            componentReferences.append(ComponentReference(
                type: C.self, 
                identifier: try storage.store(item: newItem, with: options)
            ))
        }
    }

    /// This method provides access to the instance of the component that is associated with this entity.
    /// - Parameters:
    ///   - component: Type of the component.
    ///   - accessBlock: Access block that provides inout access to the component. 
    /// - Returns: Return value forwarded from the access block. If 'nil', access block was not called, because no instance of such component was set for this entity.
    public func access<C: Component, R>(component: C.Type, accessBlock: (inout C.Store.StoredComponent) throws -> R ) rethrows -> R? {
        guard let index = index(of: C.self) else {
            return nil
        }

        return try dataManager.storage(for: C.self).access(at: &componentReferences[index].identifier, validityScope: accessBlock)
    }

    /// Destroys 
    /// - Parameter component: Type of the component that should be destroyed.
    /// - Returns: `true` if a component was destroyed.
    @discardableResult
    public func destroy<C: Component>(component: C.Type) -> Bool {
        guard let index = index(of: C.self) else {
            return false
        }

        let old = componentReferences.remove(at: index)
        dataManager.storage(for: C.self).destroy(at: old.identifier)
        return true
    }

    /// Call this method, if the location of a component in a component store has changed.
    /// - Parameters:
    ///   - component: The type of the component. 
    ///   - newIndex: The new index of the component.
    public func relocated<C: Component>(component: C.Type, to newIndex: Any) {
        guard let index = index(of: C.self) else {
            return
        }

        componentReferences[index].identifier = newIndex
    }

    private func index<C: Component>(of component: C.Type) -> Int? {
        componentReferences.enumerated().first { $1.type == C.self }?.offset
    }

    /// When intity is deallocated, it needs to remove all of the components that belong to it.
    /// Otherwise unowned(unsafe) pointer to the entity would became dangling pointer.
    deinit {
        componentReferences.forEach { 
            dataManager.destroy(opaque: $0.type, at: $0.identifier)
        }
    }
}