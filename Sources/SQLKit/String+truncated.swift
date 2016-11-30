//
//  String+truncated.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/30/16.
//
//

import Foundation

extension String {
    func truncated(to count: Int) -> String {
        guard characters.count > count else {
            return self
        }
        
        return String(characters.prefix(count - 1)) + "…"
    }
}
