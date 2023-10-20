//
//  String+truncated.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 11/30/16.
//
//

import Foundation

extension String {
    func truncated(to count: Int) -> String {
        guard self.count > count else {
            return self
        }
        
        return String(self.prefix(count - 1)) + "…"
    }
}
