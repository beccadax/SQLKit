//
//  Pool.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/27/16.
//
//

import Foundation
import Dispatch

public enum PoolError: Error {
    case timedOut
}

public final class Pool<Resource: AnyObject> {
    let constructor: () throws -> Resource
    let timeout: DispatchTimeInterval
    
    private let counter: DispatchSemaphore
    private var resourceIsAvailable: [ByIdentity<Resource>: Bool] = [:]
    private let queue = DispatchQueue(label: "ConnectionPool.queue")
    
    public init(maximum: Int = 10, timeout: DispatchTimeInterval = .seconds(10), constructor: @escaping () throws -> Resource) {
        self.constructor = constructor
        self.counter = DispatchSemaphore(value: maximum)
        self.timeout = timeout
    }
    
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
    
    public func relinquish(_ resource: Resource) {
        queue.sync {
            precondition(resourceIsAvailable[resource] == false)
            resourceIsAvailable[resource] = true
            counter.signal()
        }
    }
    
    public func withOne<R>(do fn: (Resource) throws -> R) throws -> R {
        let resource = try retrieve()
        defer { relinquish(resource) }
        return try fn(resource)
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

