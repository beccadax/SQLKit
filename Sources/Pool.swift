//
//  Pool.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/27/16.
//
//

import Dispatch

/// Errors emitted by a Pool.
public enum PoolError: Error {
    /// Attempting to `retrieve()` an unused `Resource` took longer than the 
    /// `timeout`.
    case timedOut
}

/// A shared pool of `Resource` which can be added to and removed from in a 
/// threadsafe fashion.
/// 
/// To use a `Pool`, initialize it with a `maximum` number of `Resources` to 
/// manage, a `timeout` indicating the maximum time it should wait for a 
/// `Resource` to be relinquished if all of them are in use, and a `constructor` 
/// which creates a new `Resource`.
/// 
/// A `Pool` can manage any kind of object, but it's included in this module to 
/// support `SQLConnection` pools. When managing a pool of `SQLConnection`s, you 
/// can use a special constructor which creates connections from a provided 
/// `SQLDatabase`.
/// 
/// Once the `Pool` has been created, you use the `retrieve()` method to get an 
/// object from the pool, and the `relinquish(_:)` method to return it to the pool. 
/// Alternatively, use `discard(_:)` to indicate that the object should be destroyed 
/// and a new one created; this is useful when the object is in an unknown state. 
/// If you want to wrap up all these calls into one mistake-resistant method, use 
/// the `withOne(do:)` method.
// 
// FIXME: I actually have little experience with these primitives, particularly 
// semaphores. Review by someone who knows more about them than I do would be 
// welcome.
public final class Pool<Resource: AnyObject> {
    private let constructor: () throws -> Resource
    private let timeout: DispatchTimeInterval
    
    private let counter: DispatchSemaphore
    private var resourceIsAvailable: [ByIdentity<Resource>: Bool] = [:]
    private let queue = DispatchQueue(label: "ConnectionPool.queue")
    
    /// Creates a `Pool`. The pool is initially empty, but it may eventually contain 
    /// up to `maximum` objects.
    /// 
    /// - Parameter maximum: The maximum number of `Resource` objects in the pool.
    /// 
    /// - Parameter timeout: Indicates the maximum time to wait when there are 
    ///                `maximum` objects in the pool and none of them have been 
    ///                relinquished.
    /// 
    /// - Parameter constructor: A function which can create a new `Resource`. 
    ///                Automatically called when someone tries to `retrieve()` an 
    ///                existing `Resource` and there aren't any, but the `maximum` 
    ///                has not been reached.
    public init(maximum: Int = 10, timeout: DispatchTimeInterval = .seconds(10), constructor: @escaping () throws -> Resource) {
        self.constructor = constructor
        self.counter = DispatchSemaphore(value: maximum)
        self.timeout = timeout
    }
    
    /// Retrieves a currently unused `Resource` from the `Pool`, marking it as 
    /// used until it's passed to `relinquish(_:)`.
    /// 
    /// - Throws: `PoolError.timedOut` if there are none available and none are 
    ///             relinquished within `timeout`, or any error thrown by `constructor`.
    /// 
    /// - Note: This call is synchronized so that it is safe to call from any thread 
    ///           or queue.
    public func retrieve() throws -> Resource {
        func isAvailable(_: ByIdentity<Resource>, available: Bool) -> Bool {
            return available
        }
        
        guard counter.wait(timeout: .now() + timeout) != .timedOut else {
            throw PoolError.timedOut
        }
        
        return try queue.sync {
            if let index = resourceIsAvailable.index(where: isAvailable) {
                let resource = resourceIsAvailable[index].key.object
                resourceIsAvailable[resource] = false
                return resource
            }
                        
            let newResource = try constructor()
            resourceIsAvailable[newResource] = false
            return newResource
        }
    }
    
    private func resetAvailability(of resource: Resource, to available: Bool?) {
        queue.sync {
            precondition(resourceIsAvailable[resource] == false)
            resourceIsAvailable[resource] = available
            counter.signal()
        }
    }
    
    /// Returns `resource` to the `Pool` to be reused.
    /// 
    /// - Parameter resource: The resource to relinquish. It may be returned by a 
    ///               future call to `retrieve()`.
    /// 
    /// - Precondition: `resource` was returned by a prior call to `retrieve()`.
    /// 
    /// - Note: This call is synchronized so that it is safe to call from any thread 
    ///           or queue.
    public func relinquish(_ resource: Resource) {
        resetAvailability(of: resource, to: true)
    }
    
    /// Frees up `resource`'s slot in the pool. `resource` itself will never be 
    /// reused, but a new instance of `Resource` may be allocated in its place.
    /// 
    /// This is useful when `resource` may be in an inconsistent state, such as 
    /// when an error occurs.
    /// 
    /// - Parameter resource: The resource to discard. It will not be returned by 
    ///               any future call to `retrieve()`.
    /// 
    /// - Precondition: `resource` was returned by a prior call to `retrieve()`.
    /// 
    /// - Note: This call is synchronized so that it is safe to call from any thread 
    ///           or queue.
    public func discard(_ resource: Resource) {
        resetAvailability(of: resource, to: nil)
    }
    
    /// Calls `fn` with a newly-`retrieve()`d `Resource`, then `relinquish(_:)`es 
    /// or `discard(_:)`s the resource as appropriate.
    /// 
    /// The resource is `relinquish(_:)`ed if `fn` returns successfully, or 
    /// `discard(_:)`ed if `fn` throws.
    /// 
    /// - Parameter fn: The function to run with the `Resource`.
    /// 
    /// - Returns: The return value of `fn`.
    /// 
    /// - Throws: If `retrieve()` or `fn` throw.
    public func withOne<R>(do fn: (Resource) throws -> R) throws -> R {
        let resource = try retrieve()
        do {
            let ret = try fn(resource)
            relinquish(resource)
            return ret
        }
        catch {
            discard(resource)
            throw error
        }
    }
}

// WORKAROUND: #2 Swift doesn't support same-type requirements on generics
private protocol _ByIdentityProtocol: Hashable {
    associatedtype Object: AnyObject
    init(_ object: Object)
}

private struct ByIdentity<Object: AnyObject> {
    let object: Object
    init(_ object: Object) {
        self.object = object
    }
}

// WORKAROUND: #2 Swift doesn't support same-type requirements on generics
extension ByIdentity: Hashable, _ByIdentityProtocol {
    static func == (lhs: ByIdentity, rhs: ByIdentity) -> Bool {
        return ObjectIdentifier(lhs.object) == ObjectIdentifier(rhs.object)
    }
    
    var hashValue: Int {
        return ObjectIdentifier(object).hashValue
    }
}

// WORKAROUND: #2 Swift doesn't support same-type requirements on generics
extension Dictionary where Key: _ByIdentityProtocol {
    subscript(key: Key.Object) -> Value? {
        get {
            return self[Key(key)]
        }
        set {
            self[Key(key)] = newValue
        }
    }
}

