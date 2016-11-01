//
//  Int+LosslessStringConvertible.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/28/16.
//
//

extension Int: LosslessStringConvertible {
    public init?(_ description: String) {
        self.init(description, radix: 10)
    }
}
