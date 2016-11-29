//
//  _IntIndexedCollection.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation

public protocol _IntIndexedCollection {}

extension _IntIndexedCollection where Self: RandomAccessCollection {
    public var startIndex: Int {
        return 0
    }
    
    public func index(before i: Int) -> Int {
        return i - 1
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    public typealias Indices = DefaultRandomAccessIndices<Self>
}
