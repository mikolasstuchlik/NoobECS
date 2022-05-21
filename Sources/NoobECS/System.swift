open class System<UpdateContext, RenderContext>: LoopItem {
    open weak var pool: Pool<UpdateContext, RenderContext>!

    public init(pool: Pool<UpdateContext, RenderContext>) {
        self.pool = pool
    }

    open func update(with context: UpdateContext) throws {
    }

    open func render(with context: RenderContext) throws {
    }
}
