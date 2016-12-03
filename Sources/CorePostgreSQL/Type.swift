//
//  Type.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/30/16.
//
//

import Foundation
import libpq

public enum PGType: Oid {
    static let automaticOid: Oid = 0
    
    case boolean = 16
    case byteA = 17
    case char = 18
    case name = 19
    case int8 = 20
    case int2 = 21
    case int2Vector = 22
    case int4 = 23
    case regProc = 24
    case text = 25
    case oid = 26
    case tid = 27
    case xid = 28
    case cid = 29
    case oidVector = 30
    case json = 114
    case xml = 142
    case pgNodeTree = 194
    case pgDDLCommand = 32
    case point = 600
    case lSeg = 601
    case path = 602
    case box = 603
    case polygon = 604
    case line = 628
    case float4 = 700
    case float8 = 701
    case absTime = 702
    case relTime = 703
    case tInterval = 704
    case unknown = 705
    case circle = 718
    case cash = 790
    case macAddr = 829
    case inet = 869
    case cidr = 650
    case int2Array = 1005
    case int4Array = 1007
    case textArray = 1009
    case oidArray = 1028
    case float4Array = 1021
    case aclItem = 1033
    case cStringArray = 1263
    case bpChar = 1042
    case varChar = 1043
    case date = 1082
    case time = 1083
    case timestamp = 1114
    case timestampTZ = 1184
    case interval = 1186
    case timeTZ = 1266
    case bit = 1560
    case varBit = 1562
    case numeric = 1700
    case refCursor = 1790
    case regProcedure = 2202
    case regOper = 2203
    case regOperator = 2204
    case regClass = 2205
    case regType = 2206
    case regRole = 4096
    case regNamespace = 4089
    case regTypeArray = 2211
    case uuid = 2950
    case lsn = 3220
    case tsVector = 3614
    case gtsVector = 3642
    case tsQuery = 3615
    case regConfig = 3734
    case regDictionary = 3769
    case jsonB = 3802
    case int4Range = 3904
    case record = 2249
    case recordArray = 2287
    case cString = 2275
    case any = 2276
    case anyArray = 2277
    case void = 2278
    case trigger = 2279
    case evtTrigger = 3838
    case languageHandler = 2280
    case `internal` = 2281
    case opaque = 2282
    case anyElement = 2283
    case anyNonArray = 2776
    case anyEnum = 3500
    case fdwHandler = 3115
    case indexAMHandler = 325
    case tsmHandler = 3310
    case anyRange = 3831
}

func oids(of types: [PGType?]) -> [Oid] {
    return types.map { $0?.rawValue ?? PGType.automaticOid }
}
