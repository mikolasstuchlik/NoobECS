# NoobECS

NoobECS is an implementation of Component-Entity-System pattern in Swift. 

## Features

This package provides you with four main features:

 - defines basic protocols for ECS and provides base implementation
 - defines how Components and Entities are cross-referenced
 - defines how references to Components are stored inside of Entities
 - *does not force you to store Components in any particular data structure*  and allows you interact with Components independently of Entities.

Creation of an Entity and an Component looks like this:
```swift
let pool = Pool<Void, Void>()

let entity = Entity(dataManager: pool)
entity.developerLabel = "my new entity"

// Assume we have a Component that stores character position
try! entity.assign(
    component: PositionComponent.self,
    arguments: (
        positionX: 10,
        positionY: 10
    )
)
```

You can access and modify the instance of the Component via the Entity:
```swift
entity.access(component: PositionComponent.self) { component in 
    component.positionX = 100
    component.positionY = 100
}
```


## Examples
There is an [example application, that uses NoobECS](https://github.com/mikolasstuchlik/GameTest).

The main focus of NoobECS is the way Components are stored and Entities interact with them. However, the NoobECS also makes several assumptions about the application. The ECS assumes, that application runs in a loop, that has two discrete steps: the update step and render step. Both of those steps might need a different context information - for example, the render step may need a reference to a renderer. Let's define data structures for our contexts:

```swift
struct UpdateData { 
    let frameTime: Float
}

struct RenderData {
    let renderer: RenderContext
}
```

Then you need an instance, that keeps alive all of the Entities and their Components. For this purpose, the ECS provides a class called Pool. *Note: If you don't want use the Pool-System part of the ECS, you're welcome to create your own type conforming to the `EntityComponentDataManager` protocol.*

```swift
final class MyPool: Pool<UpdateData, RenderData> { }

// Somewhere in the Application run loop:

func run() throws {
    while true {
        let frameTime = ...
        let renderer = ...
        try myPool.update(with: UpdateData(frameTime: frameTime))
        try myPool.render(with: RenderData(renderer: renderer))
    }
}

```

When you have your Pool set up, you will need to define the systems, that operate on top of your Entites. System has also `update` and `render` steps. The default implementation of Pool expects, that all your system will inherit from `class System<UpdateContext, RenderContext>`. Systems have to be stored in the Pool instance and are executed in the order they are stored.

```
final class UserInputSystem: System<UpdateData, RenderData> { ... }
final class RenderingSystem: System<UpdateData, RenderData> { ... }

extension MyPool {
    func setup() {
        self.systems = [
            UserInputSystem(pool: self),
            RenderingSystem(pool: self)
        ]
    }
}
```

The strongest feature of the NoobECS is the ability to define your own way of storing components. Default implementation of most common stores in in module `NoobECSStore`. We will use here store called `VectorStorage<Component>` which stores Components inline in a Swift.Array. The storage for the Component is specified in the Component declaration:

```swift
struct PositionComponent: Component {
    typealias Store = VectorStorage<Self>
    
    var positionX: Float
    var positionY: Float
    
    init(arguments: (positionX: Float, positionY: Float)) {
        self.positionX = arguments.positionX
        self.positionY = arguments.positionY
    }
}
``` 


## Installation
Package is installed via SPM and contains multiple products.
```swift
let package = Package(
    name: "Game",
    dependencies: [
        .package(url: "https://github.com/mikolasstuchlik/NoobECS.git", from: "0.0.1")
    ],
    targets: [
        .executableTarget(
            name: "Game", 
            dependencies: [
                .product(name: "NoobECS", package: "NoobECS"),
                .product(name: "NoobECSStores", package: "NoobECS")
            ]
        )
    ]
)
```

## Known issues and TODO
 - Introduce tests, that would verify internal layout of various storages
 - Add more tests that would introduce more complex scenarios
 