import Foundation

public enum EntityFactory { }

public final class Entity: Hashable {
    public struct ComponentReference {
        let type: OpaqueComponent.Type
        var storage: Any
    }

    public unowned(unsafe) let dataManager: EntityComponentDataManager
    public private(set) var componentReferences: [ComponentReference] = []

    public var developerLabel: String?

    public init(dataManager: EntityComponentDataManager, developerLabel: String? = nil) {
        self.dataManager = dataManager
        self.developerLabel = developerLabel
        dataManager.entities.insert(self)
    }

    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }

    public func has<C: Component>(component: C.Type) -> Bool {
        componentReferences.contains { $0.type == C.self }
    }

    public func assign<C: Component>(component: C.Type, arguments: C.Store.StoredComponent.InitArguments) throws where C.Store.StoreOptions == Void {
        try assign(component: C.self, options: (), arguments: arguments)
    }

    public func assign<C: Component>(component: C.Type, options: C.Store.StoreOptions, arguments: C.Store.StoredComponent.InitArguments) throws {
        let storage = dataManager.storage(for: C.self)

        let oldIndex = index(of: C.self)
        destroy(component: C.self)
        let newIndex = try storage.allocInit(for: self, options: options, with: arguments)

        if let oldIndex = oldIndex {
            componentReferences[oldIndex].storage = newIndex
        } else {
            componentReferences.append(ComponentReference(type: C.self, storage: newIndex))
        }
    }

    public func access<C: Component, R>(component: C.Type, accessBlock: (inout C.Store.StoredComponent) throws -> R ) rethrows -> R? {
        guard let index = index(of: C.self) else {
            return nil
        }

        return try dataManager.storage(for: C.self).access(at: &componentReferences[index].storage, validityScope: accessBlock)
    }

    @discardableResult
    public func destroy<C: Component>(component: C.Type) -> Bool {
        guard let index = index(of: C.self) else {
            return false
        }

        let old = componentReferences.remove(at: index)
        dataManager.storage(for: C.self).destroy(at: old.storage)
        return true
    }

    public func relocated<C: Component>(component: C.Type, to newIndex: Any) {
        guard let index = index(of: C.self) else {
            return
        }

        componentReferences[index].storage = newIndex
    }

    private func index<C: Component>(of component: C.Type) -> Int? {
        componentReferences.enumerated().first { $1.type == C.self }?.offset
    }

    deinit {
        componentReferences.forEach { 
            dataManager.destroy(opaque: $0.type, at: $0.storage)
        }
    }
}