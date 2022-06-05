/// Since component protocol has an associated type, we need opaque protocol.
public protocol OpaqueComponent {
    /// Whenever an instance of a component is no longer needed, this method 
    /// is called to safely dispose of all the resources an instance of this
    /// compoent may own.
    /// In case of class-based components, the same may be achieved by using
    /// deinit.
    /// Since we don't want to impose restriction on using value-types as 
    /// components, we need to introduce a mechanism like this.
    func destroy()
}

public extension OpaqueComponent {
    func destroy() { }
}

/// Component is a protocol that all components in your app should conform to.
/// Components are owned by an instance of Entity and stored separately in their
/// own stores.
/// 
/// You should not instantiate an instance of a component yourself. The instance
/// is created and managed by the instance of Entity for you.
public protocol Component: OpaqueComponent {
    /// Type (or a touple) that the component needs in order to create an instance.
    associatedtype InitArguments

    /// Store using by this type of components. Generaly each component should use
    /// it's own store. Stores are themselves stored in an `EntityComponentDataManager.`
    associatedtype Store: ComponentStore

    /// Initializer that is called by the Entity to instantiate the component.
    /// - Parameter arguments: Arguments for the initializer.
    init(arguments: InitArguments) throws
}
