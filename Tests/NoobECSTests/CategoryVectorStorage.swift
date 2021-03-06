import XCTest
@testable import NoobECS
@testable import NoobECSStores

private final class TestPool: Pool<Void, Void> { }

private struct StructComponent: CategoryComponent {
    typealias Categories = Int
    typealias Store = CategoryVectorStorage<Self>

    var aValue: Int

    init(
        arguments: Int
    ) {
        self.aValue = arguments
    }

    func destroy() { }
}

private class ClassComponent: CategoryComponent {
    typealias Categories = Int
    typealias Store = CategoryVectorStorage<ClassComponent>

    var aValue: Int

    required init(
        arguments: Int
    ) {
        self.aValue = arguments
    }

    func destroy() { }
}

extension Collection where Element == Range<Int>, Index == Int {
    var isStrictContinuation: Bool {
        for (prevIndex, item) in self.dropFirst().enumerated() {
            guard self[prevIndex].upperBound == item.lowerBound else {
                return false
            }
        }

        return true
    }
}

final class CategoryStorageTests: XCTestCase {
    func testStoreAndRemoveStruct() throws {
        let pool = TestPool()
        let store = pool.storage(for: StructComponent.self)

        let entity0 = Entity(dataManager: pool)
        let entity1 = Entity(dataManager: pool)
        let entity2 = Entity(dataManager: pool)
        let entity3 = Entity(dataManager: pool)

        try entity0.assign(component: StructComponent.self, options: 1, arguments: 100)
        try entity1.assign(component: StructComponent.self, options: 1, arguments: 110)
        try entity2.assign(component: StructComponent.self, options: 1, arguments: 120)

        XCTAssertEqual(store.buffer.count, 3)
        XCTAssertNil(store.categoryFreedIndicies[1])

        XCTAssertEqual(store.buffer[0]!.value.aValue, 100)
        XCTAssertEqual(store.buffer[1]!.value.aValue, 110)
        XCTAssertEqual(store.buffer[2]!.value.aValue, 120)

        entity1.destroy(component: StructComponent.self)
        
        XCTAssertEqual(store.buffer.count, 3)
        XCTAssertEqual(store.categoryFreedIndicies[1]!.count, 1)
        XCTAssertEqual(store.categoryFreedIndicies[1]!.first, 1)

        XCTAssertEqual(store.buffer[0]!.value.aValue, 100)
        XCTAssertNil(store.buffer[1])
        XCTAssertEqual(store.buffer[2]!.value.aValue, 120)

        try entity3.assign(component: StructComponent.self, options: 1, arguments: 130)
        try entity1.assign(component: StructComponent.self, options: 1, arguments: 111)

        XCTAssertEqual(store.buffer.count, 4)
        XCTAssertEqual(store.categoryFreedIndicies[1]!.count, 0)

        XCTAssertEqual(store.buffer[0]!.value.aValue, 100)
        XCTAssertEqual(store.buffer[1]!.value.aValue, 130)
        XCTAssertEqual(store.buffer[2]!.value.aValue, 120)
        XCTAssertEqual(store.buffer[3]!.value.aValue, 111)
    }

    func testStoreAndRemoveClass() throws {
        let pool = TestPool()
        let store = pool.storage(for: ClassComponent.self)

        let entity0 = Entity(dataManager: pool)
        let entity1 = Entity(dataManager: pool)
        let entity2 = Entity(dataManager: pool)
        let entity3 = Entity(dataManager: pool)

        try entity0.assign(component: ClassComponent.self, options: 1, arguments: 100)
        weak var comp0: ClassComponent? = entity0.access(component: ClassComponent.self) { $0 }
        try entity1.assign(component: ClassComponent.self, options: 1, arguments: 110)
        weak var comp1: ClassComponent? = entity1.access(component: ClassComponent.self) { $0 }
        try entity2.assign(component: ClassComponent.self, options: 1, arguments: 120)
        weak var comp2: ClassComponent? = entity2.access(component: ClassComponent.self) { $0 }

        XCTAssertEqual(store.buffer.count, 3)
        XCTAssertNil(store.categoryFreedIndicies[1])

        XCTAssertEqual(store.buffer[0]!.value.aValue, 100)
        XCTAssertEqual(store.buffer[1]!.value.aValue, 110)
        XCTAssertEqual(store.buffer[2]!.value.aValue, 120)

        XCTAssertNotNil(comp0)
        XCTAssertNotNil(comp1)
        XCTAssertNotNil(comp2)

        entity1.destroy(component: ClassComponent.self)
        
        XCTAssertEqual(store.buffer.count, 3)
        XCTAssertEqual(store.categoryFreedIndicies[1]!.count, 1)
        XCTAssertEqual(store.categoryFreedIndicies[1]!.first, 1)

        XCTAssertEqual(store.buffer[0]!.value.aValue, 100)
        XCTAssertNil(store.buffer[1])
        XCTAssertEqual(store.buffer[2]!.value.aValue, 120)

        XCTAssertNotNil(comp0)
        XCTAssertNil(comp1)
        XCTAssertNotNil(comp2)

        try entity3.assign(component: ClassComponent.self, options: 1, arguments: 130)
        try entity1.assign(component: ClassComponent.self, options: 1, arguments: 111)

        XCTAssertEqual(store.buffer.count, 4)
        XCTAssertEqual(store.categoryFreedIndicies[1]!.count, 0)

        XCTAssertEqual(store.buffer[0]!.value.aValue, 100)
        XCTAssertEqual(store.buffer[1]!.value.aValue, 130)
        XCTAssertEqual(store.buffer[2]!.value.aValue, 120)
        XCTAssertEqual(store.buffer[3]!.value.aValue, 111)
    }

    func testStructOrdering() throws {
        let pool = TestPool()
        let store = pool.storage(for: StructComponent.self)

        let insertItems = (0..<100).map { $0 % 10 }

        for i in insertItems.shuffled() {
            let entity = Entity(dataManager: pool)
            try entity.assign(component: StructComponent.self, options: i, arguments: i)
        }

        for (index, item) in store.buffer.enumerated() {
            XCTAssert(store.category[item!.value.aValue]!.contains(index))
        }
    }

    func testStructReserve() throws {
        let pool = TestPool()
        let store = pool.storage(for: StructComponent.self)

        store.initialize(
            categories: Dictionary( (0..<5).map { ($0, 5) }) { $1 }, 
            reserve: 5
        )

        XCTAssert(store.buffer.count == 25)
        XCTAssert(store.buffer.allSatisfy { $0 == nil })
        XCTAssert(store.category.sorted { $0.key < $1.key }.map(\.value).isStrictContinuation)

        store.initialize(
            categories: Dictionary( (5..<10).map { ($0, 5) }) { $1 }, 
            reserve: 5
        )

        XCTAssert(store.buffer.count == 50)
        XCTAssert(store.buffer.allSatisfy { $0 == nil })
        XCTAssert(store.category.sorted { $0.key < $1.key }.map(\.value).isStrictContinuation)

        let insertItems = (0..<100).map { $0 % 10 }

        for i in insertItems.shuffled() {
            let entity = Entity(dataManager: pool)
            try entity.assign(component: StructComponent.self, options: i, arguments: i)
            
            if !store.category.sorted { $0.key < $1.key }.map(\.value).isStrictContinuation {
                print("first")
            }
            XCTAssert(store.category.sorted { $0.key < $1.key }.map(\.value).isStrictContinuation)
            XCTAssertEqual(
                store.category.sorted { $0.key < $1.key }.map(\.value.upperBound).last!, 
                store.buffer.count    
            )
            for (index, item) in store.buffer.enumerated() where item != nil {
                XCTAssert(store.category[item!.value.aValue]!.contains(index))
            }
        }

        for (index, item) in store.buffer.enumerated() {
            XCTAssert(store.category[item!.value.aValue]!.contains(index))
        }
    }

    func testStructDestruct() throws {
        var pool: TestPool! = TestPool()

        pool.storage(for: StructComponent.self).initialize(
            categories: [
                2: 10,
                0: 100
            ],
            reserve: 5
        )

        let insertItems = (
            Array(repeating: 0, count: 100)
            + Array(repeating: 1, count: 20)
            + Array(repeating: 2, count: 3)
        )

        for i in insertItems.shuffled() {
            let entity = Entity(dataManager: pool)
            try entity.assign(component: StructComponent.self, options: i, arguments: i)
        }

        pool = nil
    }
}
