/// Any type that is called during the application loop should conform to
/// this protocol. The loop consists of two steps. Update step and Render step.
/// The Update step should be called before the Render step.
///
/// Unlike Component and Entity types, this type is provided for user convenience.
/// It provides guidance on how the ECS is envisioned to work. 
public protocol LoopItem {
    /// Data needed for the update step.
    associatedtype UpdateContext
    /// Data needed for the render step.
    associatedtype RenderContext

    func update(with context: UpdateContext) throws
    func render(with context: RenderContext) throws
}
