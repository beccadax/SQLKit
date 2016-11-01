//
//  Collection+LastIndex.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/31/16.
//
//

import Foundation

extension Collection {
    func lastIndex(where predicate: (Iterator.Element) throws -> Bool) rethrows -> Index? {
        var lastIndex: Index? = nil
        var i = startIndex
        
        while i < endIndex {
            if try predicate(self[i]) {
                lastIndex = i
            }
            i = index(after: i)
        }
        
        return lastIndex
    }
}

extension Collection where Iterator.Element: Equatable {
    func lastIndex(of elem: Iterator.Element) -> Index? {
        return lastIndex { $0 == elem }
    }
}

extension BidirectionalCollection {
    func lastIndex(where predicate: (Iterator.Element) throws -> Bool) rethrows -> Index? {
        var i = endIndex
        
        while i > startIndex {
            i = index(before: i)
            if try predicate(self[i]) {
                return i
            }
        }
        
        return nil
    }
}

extension BidirectionalCollection where Iterator.Element: Equatable {
    func lastIndex(of elem: Iterator.Element) -> Index? {
        return lastIndex { $0 == elem }
    }
}

