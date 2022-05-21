open class Pool<UpdateContext, RenderContext>: LoopItem, EntityComponentDataManager {
    open var systems: [System<UpdateContext, RenderContext>] = []
    open var entities: Set<Entity> = []
    open var stores: [OpaqueComponentStore] = []

    public init() {}

    open func update(with context: UpdateContext) throws {
        try systems.forEach { try $0.update(with: context) }
    }

    open func render(with context: RenderContext) throws {
        try systems.forEach { try $0.render(with: context) }
    }
}
