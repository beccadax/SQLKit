//
//  _IntIndexedCollection.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 11/28/16.
//
//

import Foundation

/// Internal protocol used for implementation sharing. Do not use.
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
    
    public typealias Indices = DefaultIndices<Self>
}
