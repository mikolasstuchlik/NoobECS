public protocol OpaqueComponent {
    func destroy()
}

public protocol Component: OpaqueComponent {
    associatedtype InitArguments
    associatedtype Store: ComponentStore

    init(arguments: InitArguments) throws
}
