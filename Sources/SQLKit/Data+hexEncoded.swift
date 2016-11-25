//
//  Data+hexEncoded.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 10/28/16.
//
//

import Foundation

extension Data {
    struct HexEncodingOptions: OptionSet {
        static let preferringUppercase = HexEncodingOptions(rawValue: 1)
        
        var rawValue: Int
    }
    
    init?(hexEncoded hexString: String) {
        let scalars = hexString.unicodeScalars
        self.init(capacity: scalars.count / 2)
        
        var firstIndex = scalars.startIndex
        while firstIndex < scalars.endIndex {
            guard let nextIndex = scalars.index(firstIndex, offsetBy: 2, limitedBy: scalars.endIndex) else {
                return nil
            }
            
            let hexPair = String(scalars[firstIndex ..< nextIndex])
            guard let byte = UInt8(hexPair, radix: 16) else {
                return nil
            }
            
            append(byte)
            firstIndex = nextIndex
        }
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let upper = options.contains(.preferringUppercase)
        return reduce("") { string, byte in string + String(byte, radix: 16, uppercase: upper) }
    }
}
