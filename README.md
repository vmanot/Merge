# Merge

Robust task management and concurrency utilities built atop Combine.

## Task Management

### `ObservableTask`

`ObservableTask` is the main export of this framework. 

```swift
/// An observable task is a token of activity with status-reporting.
public protocol ObservableTask: Identifiable, ObservableObject where
    ObjectWillChangePublisher.Output == TaskStatus<Self.Success, Self.Error> {
    associatedtype Success
    associatedtype Error: Swift.Error
      
    /// The status of this task.
    var status: TaskStatus<Success, Error> { get }
        
    /// The progress of the this task.
    var progress: Progress { get }
    
    /// Start the task.
    func start()
        
    /// Pause the task.
    func pause() throws
        
    /// Resume the task.
    func resume() throws
        
    /// Cancel the task.
    func cancel()
}

```

An observable task can be thought of a status-reporting publisher subscription. 

## `@PublishedObject`
The `@PublishedObject` property wrapper extends the capabilities of the `@Published` property wrapper to instances that conform to the `ObservableObject` protocol. This allows for automatic observation and reaction to changes within objects that are marked as observable.

```swift
struct MyObjectViewModel {
    @PublishedObject var currentObject: MyObject? = nil
    @PublishedObject var objects: [MyObject] = []
}

// a class that comforms to ObservableObject protocol
class MyObject: ObservableObject {
    @Published var someText: String
    
    init(someText: String) {
        self.someText = someText
    }
}
```

#### Motivation

While **Combine** publishers are great, they're not suited for complex task management for the following reasons:

- Publishers fundamentally lack the concept of progress reporting. Publishers aren't 'live' reactive streams, they *create* live streams upon initiating a new subscription but these streams are opaque (beyond the support of backpressure/cancellation).

- Publishers support the concept of backpressure, but do not support hard/well-defined concepts of pause/resume. This may be favorable in design for a general-purpose reactive programming framework, but a deficit for constructing complex task graphs that need to unambiguously support pause/resume.

`ObservableTask` was created to fill the need for a modern-day `NSOperation` replacement.
