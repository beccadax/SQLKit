//
//  Utility.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 11/28/16.
//
//

import Foundation

func withUnsafePointers<R>(to array: [Data?], do body: ([UnsafePointer<Int8>?]) throws -> R) rethrows -> R {
    var buffer = Data()
    var offsets: [Int?] = []

    for element in array {
        guard let data = element else {
            offsets.append(nil)
            continue
        }
        offsets.append(buffer.endIndex)
        buffer.append(data)
    }

    return try buffer.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
        try rawBufferPointer.withMemoryRebound(to: Int8.self) { bufferPointer in
            let pointers = offsets.map { $0.flatMap { bufferPointer.baseAddress! + $0 } }
            return try body(pointers)
        }
    }
}
