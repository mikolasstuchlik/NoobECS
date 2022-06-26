/// Pool is a convenience class that serves as a basic building block of an application.
/// 
/// It conform to the EntityComponentDataManager and so it stores all entities and stores
/// and should avoid working with any Entities and Components that are owned by different
/// Data Managers.
/// It also stores it's systems in an array and executes them in order as stored in array.
///
/// Unlike Component and Entity types, this type is provided for user convenience.
/// It provides guidance on how the ECS is envisioned to work.
open class Pool<UpdateContext, RenderContext>: LoopItem, EntityComponentDataManager {
    open var systems: [System<UpdateContext, RenderContext>] = []
    open var entities: [ObjectIdentifier: Entity] = [:]
    open var stores: [OpaqueComponentStore] = []

    public init() {}

    open func update(with context: UpdateContext) throws {
        try systems.forEach { try $0.update(with: context) }
    }

    open func render(with context: RenderContext) throws {
        try systems.forEach { try $0.render(with: context) }
    }
}
