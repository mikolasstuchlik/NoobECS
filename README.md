# NoobECS

This package contains protocols and basic declarations for Component-Entity-System in pure Swift by a guy who never created a game.

Visit https://github.com/mikolasstuchlik/GameTest for use-case example.
 
This ECS is designed to leverage strong points of Swift like value/reference semantics. The main goal is "simple performance" meaning we want to achieve the best performance using very single primitives - like arrays - without the need for some C-backed magic.

The ECS is designed to be "storage agnostic" and "type agnostic." To put it simply, it shouls be possible to store Components as the user desires - simple Array, R Tree or even in the Entity itself! We also wan't to allow the user to choose whether to use reference type or value type for his Component.

TODO:
 - Introduce tests, that would verify internal layout of various storages
 - Add more tests that would introduce more complex scenarios
 - Add documentation
 - Release version 0.0.1
 - Fix issue with Category Vector: insertion does not work
