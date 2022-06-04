import NoobECS

public protocol Category: Hashable, Comparable {}

public protocol CategoryComponent: Component {
    associatedtype Categories: Category
}

#if TESTING
extension Collection where Element == Range<Int>, Index == Int {
    var isStrictContinuation: Bool {
        for (prevIndex, item) in self.dropFirst().enumerated() {
            guard self[prevIndex].upperBound == item.lowerBound else {
                return false
            }
        }

        return true
    }

    var isContinuation: Bool {
        for (prevIndex, item) in self.dropFirst().enumerated() {
            guard self[prevIndex].upperBound <= item.lowerBound else {
                return false
            }
        }

        return true
    }
}
#endif

public final class CategoryVectorStorage<C: CategoryComponent>: ComponentStore {

    public typealias StoreOptions = C.Categories
    public typealias ComponentIdentifier = Int
    public typealias StoredComponent = C

    public let type: OpaqueComponent.Type = C.self
    public var buffer: [StoreItem<C>?] = []
#if TESTING 
    public var category: [C.Categories: Range<Int>] = [:] {
        didSet {
            assert(self.category.sorted { $0.key < $1.key }.map(\.value).isContinuation)
        }
    }
#else
    public var category: [C.Categories: Range<Int>] = [:]
#endif

    private(set) var categoryFreedIndicies: [C.Categories: [Int]] = [:]

    public init() { }


    public func store(item: StoreItem<C>, with options: C.Categories) throws -> Int {
#if TESTING
        defer {
            assert(self.category.sorted { $0.key < $1.key }.map(\.value).isStrictContinuation)
        }
#endif

        if let allocated = categoryFreedIndicies[options]?.popLast() {
            buffer[allocated] = item
            return allocated
        }

        // At this point we know, that there is no free space in our category
        var categories = self.category
        categories[options] = categories[options] ?? 0..<0
        let sortedCategories = categories.sorted { $0.key < $1.key }
        let myIndex = sortedCategories.firstIndex { $0.key == options }!
        let newRange: Range<Int>
        switch myIndex {
        case 0 where sortedCategories.count == 1:
            newRange = 0..<(1 + sortedCategories[0].value.upperBound)
        case 0:
            newRange = 0..<(1 + sortedCategories[1].value.lowerBound)
        case let index:
            newRange = sortedCategories[index - 1].value.upperBound..<(
                1 
                + sortedCategories[index - 1].value.upperBound
                + sortedCategories[index].value.count
            )
        }

        // At this point we know how will the new category look like, we shall insert it and move space
        if myIndex == sortedCategories.count - 1 {
            self.category[options] = newRange
            buffer.append(item)
            return buffer.count - 1
        } else {
            recursiveFree(fist: 1, category: sortedCategories[myIndex + 1].key)
            self.category[options] = newRange
            let newIndex = newRange.upperBound - 1

            if newIndex >= buffer.count {
                assert(newIndex == buffer.count, "Failed to determine correct new index!")
                buffer.append(item)
                return buffer.count - 1
            }

            buffer[newIndex] = item
            return newIndex
        }
    }

    public func access<R>(at identifier: inout Any, validityScope: (inout StoredComponent) throws -> R) rethrows -> R? {
        try validityScope(&buffer[identifier as! ComponentIdentifier]!.value)
    }

    public func initialize(categories: [C.Categories: Int], reserve tail: Int, addToExisting: Bool = false) {
        var spaceToInitialize: [C.Categories: Int] = categories
        if !addToExisting {
            for (category, space) in categories {
                spaceToInitialize[category] = max(
                    0,
                    space - (self.category[category]?.count ?? 0)
                )
            }
        }

        // Compute spatial properties
        let currentSpace = category.mapValues(\.count)
        let targetCategoriesSize = spaceToInitialize
                .merging(currentSpace) { $0 + $1 }
        let initializedSpace = targetCategoriesSize
                .reduce(0) { $0 + $1.value }

        // Reserve required space
        buffer.reserveCapacity(initializedSpace + tail)

        // Initialize required space
        buffer.append(contentsOf: Array(
            repeating: nil, 
            count: max(0, initializedSpace - buffer.count)
        ))

        // Start moving from behind
        let orderedCategories = targetCategoriesSize.sorted { $0.key > $1.key }
        var endIndex = buffer.count
        for (category, space) in orderedCategories { 
            let newRange = (endIndex - space)..<(endIndex)
            endIndex = newRange.startIndex

            guard let currentSpace = self.category[category] else {
                self.category[category] = newRange
                self.categoryFreedIndicies[category] = Array(newRange)
                continue
            }

            self.category[category] = newRange
            unsafeMove(range: currentSpace, toIndex: newRange.startIndex)
            defragment(category: category, updateAllLocations: true)
        }
        assert(endIndex == 0, "End index is not 0 at the end of enlarging")
    }

    public func destroy(at index: Int) {
        if let category = categoryOf(index: index) {
            categoryFreedIndicies[category, default: []].append(index)
        }

        buffer[index]!.value.destroy()
        buffer[index] = nil
    }

    public func categoryOf(index: Int) -> C.Categories? {
        category.first { $1.contains(index) }?.key
    }

    private func recursiveFree(fist nItems: Int, category: C.Categories) {
        let sortedCategories = self.category.sorted { $0.key < $1.key }
        let myIndex = sortedCategories.firstIndex { $0.key == category }!
        let currentRange = sortedCategories[myIndex].value
        let freeIndicies = categoryFreedIndicies[category] ?? []
        let freeIndiciesInResignedSpace = freeIndicies.filter { $0 < currentRange.lowerBound + nItems }
        let numberOfDisplacedItems = (currentRange.lowerBound..<(currentRange.lowerBound + nItems)).count - freeIndiciesInResignedSpace.count
        let requiredSpace = max(
            0,
            numberOfDisplacedItems - (freeIndicies.count - freeIndiciesInResignedSpace.count)
        )

        // Special case when category exists but is empty
        guard currentRange.count != 0 else {
            if myIndex < sortedCategories.count - 1 {
                recursiveFree(fist: nItems, category: sortedCategories[myIndex + 1].key)
            }
            self.category[category] = (currentRange.lowerBound + nItems)..<(currentRange.upperBound + nItems)
            return
        }

        // After this if, we assume that there is enough space to write to
        if requiredSpace > 0 {
            if myIndex < sortedCategories.count - 1 {
                recursiveFree(fist: requiredSpace, category: sortedCategories[myIndex + 1].key)
            } else {
                buffer.append(contentsOf: Array(repeating: nil, count: requiredSpace))
            }
        }

        let targetRange = (currentRange.lowerBound + nItems)..<(currentRange.upperBound + requiredSpace)
        let additionalIndicies = Array(currentRange.upperBound..<targetRange.upperBound)
        var targetFreeIndicies = freeIndicies.filter { currentRange.lowerBound + nItems <= $0 } + additionalIndicies

        for i in currentRange.lowerBound..<targetRange.lowerBound where buffer[i] != nil {
            let newIndex = targetFreeIndicies.popLast()!
            buffer[newIndex] = buffer[i]
            buffer[newIndex]!.unownedEntity.relocated(component: C.self, to: newIndex)
            buffer[i] = nil
        }

        self.category[category] = targetRange
        self.categoryFreedIndicies[category] = targetFreeIndicies
    }

    private func unsafeMove(range: Range<Int>, toIndex: Int) {
        for i in range {
            buffer[i + toIndex] = buffer[i]
        }
    }

    private func defragment(category: C.Categories, updateAllLocations: Bool = false) {
        guard let range = self.category[category] else {
            return
        }
        var firstFreeIndex: Int? = nil 

        for i in range {
            if buffer[i] == nil {
                firstFreeIndex = min(firstFreeIndex ?? i, i)
                continue
            }

            guard let freeIndex = firstFreeIndex else {
                if updateAllLocations {
                    buffer[i]!.unownedEntity.relocated(component: C.self, to: i)
                }
                continue
            }

            buffer[freeIndex] = buffer[i]
            buffer[freeIndex]!.unownedEntity.relocated(component: C.self, to: freeIndex)
            buffer[i] = nil
            firstFreeIndex = firstFreeIndex.flatMap { $0 + 1 } ?? i
        }

        if let firstFreeIndex = firstFreeIndex, range.contains(firstFreeIndex) {
            categoryFreedIndicies[category] = Array(firstFreeIndex..<range.endIndex).reversed()
        } else {
            categoryFreedIndicies[category] = nil
        }
    }
}