    # Sticky

Sticky is a Core Data wrapper that simplifies several aspects of development and testing.

TODO: table of contests

# Getting Started

## Installation

### Swift Package Manager

To install Sticky for use in an app, add Sticky to your Package Dependencies in Xcode.

<!-- ![App Dependency](Assets/xcode-package-dependencies-screenshot.png?raw=true "App Dependency Screenshot") -->

<img src="Assets/xcode-package-dependencies-screenshot.png" alt="App Dependency Screenshot" width="800"/>

To install Sticky for use in a Swift Package Manager-powered tool, add Sticky as a dependency to your `Package.swift` file. 

```swift
dependencies: [
    .package(url: "https://github.com/kevinrefermat/Sticky", .upToNextMajor(from: "1.0.0"))
]
```

For more information, see the [Swift Package Manager documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation).

## Setup your Core Data stack

### Instantiation

`PersistentContainer` encapsulates your Core Data stack. Instantiating `PersistentContainer` will load your data model but will not load your persistent stores.

#### Basic

If your project contains a single target, this method will work.

```swift
let persistentContainer = PersistentContainer(name: "MyDataModel")
```

#### Advanced

If your project contains multiple targets, it be be necessary to manually load and inject your `NSManagedObjectModel`.

```swift
let persistentContainer = PersistentContainer(
    name: "MyDataModel",
    managedObjectModel: .mergedModel(
        from: [
            Bundle(for: type(of: self))
        ]
    )
)
```

### Initialization

Initialize your Core Data stack by calling `start()`. This will load the persistent stores and perform any work necessary for your app to access your persisted data. There is a synchronous and asynchronous version of `start()`.

Upon success, both `start()` functions return an instance of `ContextProvider`, which is used by your app to create and access fully initialized instances of `NSManagedObjectContext`.

Note: During app initialization, it can be hard to guarantee that contexts are only used after the Core Data stack is fully and successfully initialized. Sticky helps avoid this issue by exclusively providing contexts from `ContextProvider`. `ContextProvider` does not have a public initializer and is not made available to your app until `PersistentContainer` is fully and successfully initialized. In this way, Sticky statically guarantees that your app will only be able to use contexts that are ready to be accessed.

#### Synchronous

The synchronous `start()` function is the simplest way to initialize your `PersistentContainer`, but it blocks the calling thread.

```swift
do {
    let contextProvider = try persistentContainer.start()
    // use contextProvider to build Core Data dependent object graph
} catch {
    ...
}
```

#### Asynchronous

The asynchronous `start()` function has the advantage offloading the work to a background queue, thus freeing up the calling thread. 

This is useful in cases where there are computationally expensive data migrations occuring during initialization that could block the calling thread (which is likely to be the main thread) for seconds.

```swift
persistentContainer.start() { result in
    switch result {
    case .success(let contextProvider):
        // use contextProvider to build Core Data dependent object graph
    case .failure(let error):
        ...
    }
}
```

## Usage

### Testable

#### For unit tests, instantiate `PersistentContainer` with `inMemory` set to `true`

Running your tests with an in memory store makes them run faster. It also ensures that your test environment does not have persisted state from previous runs.

```swift
let persistentContainer = PersistentContainer(
    name: "MyDataModel", 
    inMemory: true
)
```

```swift
let persistentContainer = PersistentContainer(
    name: "MyDataModel",
    managedObjectModel: .mergedModel(
        from: [
            Bundle(for: type(of: self))
        ]
    ),
    inMemory: true
)
```

#### Mock `PersistentContainer` to customize behavior for tests

Create a mock object that conforms to `PersistentContainerProtocol` to simulate edge cases or behavior that is hard to replicate in the real world.

Want to simulate a failed initialization? Create a new object that throws an error inside `start()`.

Want to simulate a slow data migration? Create a new object that wraps `PersistentContainer` and inside `start()` have it sleep for a few seconds before calling the underlying `start()`.

TODO: make contextprovider a protocol

### Enhanced `perform(block:)` and `performAndWait(block:)`

#### Receiving context is passed into `block`

This allows you to avoid an unnecessary declaration of `context` outside the scope of the `block`.

Note: `perform(block:)` retains the receiving context until `block` returns.

```swift
contextProvider.newBackgroundContext().perform { context in
    // use context
}

contextProvider.newBackgroundContext().performAndWait { context in
    // use context
}
```

#### `performAndWait(block:)` rethrows errors

This matches the rethrowing behavior of [`DispatchQueue.sync()`](https://developer.apple.com/documentation/dispatch/dispatchqueue/2016081-sync).

```swift
do {
    try contextProvider.newBackgroundContext().performAndWait { context in
        try context.doSomethingThatThrows()
    }
} catch {
    // handle errors thrown by context.doSomethingThatThrows()
}
```


#### `performAndWait(block:)` returns the value returned by `block`

This matches the return behavior of [`DispatchQueue.sync()`](https://developer.apple.com/documentation/dispatch/dispatchqueue/2016081-sync).

```swift
let bookTitles = try contextProvider.newBackgroundContext().performAndWait { context in
    return try context.fetch(Book.self).map(\.title)
}
```

### TODO: there is no Update Statically typed CRUD methods for `NSManagedObject` subclasses

#### Create

Create an instance of a certain type. 

Note: Core Data provides `NSManagedObject.init(context:)` to instantiate subclasses of `NSManagedObject`. However, there is an implementation detail that may cause warnings/errors when running unit tests. See this [StackOverflow question](https://stackoverflow.com/questions/51851485/multiple-nsentitydescriptions-claim-nsmanagedobject-subclass/53498777) for what the warnings/errors look like and this [answer](https://stackoverflow.com/a/53498777) to see how to safely avoid the issue. The `create()` function below uses the method outlined in the [answer](https://stackoverflow.com/a/53498777) to safely avoid the issue.

```swift
try contextProvider.newBackgroundContext().perform { context in
    let book = try context.create(Book.self)
    ...
}
```

#### Fetch

Fetch all managed objects of a certain type.

```swift
try contextProvider.newBackgroundContext().perform { context in
    let books = try context.fetch(Book.self)
    ...
}
```

Fetch all managed objects of a certain type with a block to customize the fetch request. The fetch request will have the generic type and entity corresponding to the specified `NSManagedObject` subclass.

```swift
try contextProvider.newBackgroundContext().perform { context in
    let historyBooks = try context.fetch(Book.self) { request in
        request.predicate = NSPredicate(
            format: "genre = %@", "history"
        )
    }
    ...
}
```

#### Delete

Delete all managed objects of a certain type.

```swift
try contextProvider.newBackgroundContext().perform { context in
    try context.delete(Book.self)
    ...
}
```

Delete all managed objects of a certain type with a block to customize the fetch request for objects to delete.

```swift
try contextProvider.newBackgroundContext().perform { context in
    try context.delete(Book.self) { (request) in
        request.predicate = NSPredicate(format: "genre == history")
    }
    ...
}
```

### Simulate a first time launch

Sticky provides two ways to simulate a first time launch without actually uninstalling and reinstalling the app.

#### Delete the persistent stores

The most straightforward way to test a fresh launch experience is to delete the underlying database and kill the app. The next time your app is launched, it will have to create a new database as if it's the first time it's launched.

```swift
try persistentContainer.deleteSQLLiteStores()
```

#### Launch the app in memory

Instead of deleting the stores on disk, you can initialize the `PersistentContainer` with the `inMemory` flag set to `true`. On initialization the `PersistentContainer` will ignore the stores on disk and will instead create and use a new store in memory. As this new store will be in memory, it will be destroyed when the app process is killed. 

When you are finished testing the fresh launch experience, you can initialize the `PersistentContainer` with the `inMemory` flag set back to `false` and use your preserved on disk persistence.

```swift
let persistentContainer = PersistentContainer(name: "MyDataModel", inMemory: true)
```

#### Practical consideration

Both of the above methods are most conveniently used by building a debug setting into your build. Add a button to delete the on disk persistence and a switch to toggle `inMemory` when initializing `PersistentContainer`. 

For the `inMemory` switch, the state will need to be persisted outside of Core Data (`UserDefaults` for example) so that it is guaranteed to be available to your app on next launch.