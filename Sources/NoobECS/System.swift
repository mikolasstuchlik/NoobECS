/// System is a class that serves as a model for any System in the application.
/// 
/// Systems are stored in an instace of Pool associated with it.
///
/// Unlike Component and Entity types, this type is provided for user convenience.
/// It provides guidance on how the ECS is envisioned to work.
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
