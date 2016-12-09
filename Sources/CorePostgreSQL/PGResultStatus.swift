//
//  PGResultStatus.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 11/28/16.
//
//

import Foundation
import libpq

extension PGResult {
    /// - RecommendedOver: `PQresultStatus`, `PQresultErrorField`
    public var status: Status {
        return Status(self)
    }
    
    public struct Status {
        public var isSuccessful: Bool {
            switch status {
            case PGRES_COMMAND_OK, PGRES_TUPLES_OK, PGRES_SINGLE_TUPLE, PGRES_NONFATAL_ERROR, PGRES_COPY_OUT, PGRES_COPY_IN, PGRES_COPY_BOTH:
                return true
                
            default:
                return false
            }
        }
        
        public let status: ExecStatusType
        fileprivate let fields: [FieldCode: String]
        
        init(_ result: PGResult) {
            self.status = PQresultStatus(result.pointer)
            
            var dict: [FieldCode: String] = [:]
            
            for fieldCode in FieldCode.all {
                let cString = PQresultErrorField(result.pointer, Int32(fieldCode.rawValue.value))
                dict[fieldCode] = cString.map { String(cString: $0) }
            }
            
            fields = dict
        }
                
        public subscript(fieldCode: FieldCode) -> String? {
            return fields[fieldCode]
        }
        
        public var severity: Severity {
            let value = self[.severity] ?? self[.localizedSeverity]!
            return Severity(rawValue: value)!
        }
        
        public var sqlState: String {
            return self[.sqlState]!
        }
                
        public var statementPosition: Int? {
            return self[.statementPosition].map { Int($0)! - 1 }
        }
        
        public var internalPosition: Int? {
            return self[.internalPosition].map { Int($0)! - 1 }
        }
        
        public var internalQuery: String? {
            return self[.internalQuery]
        }
        
        public var context: String? {
            return self[.context]
        }
        
        public enum FieldCode: UnicodeScalar {
            static var all = [FieldCode.localizedSeverity, .severity, .sqlState, .localizedPrimaryMessage, .localizedDetailMessage, .localizedHintMessage, .statementPosition, .internalPosition, .internalQuery, .context, .schemaName, .tableName, .columnName, .datatypeName, .constraintName, .sourceFile, .sourceLine, .sourceFunction]
            
            case localizedSeverity = "S"
            case severity = "V"
            case sqlState = "C"
            case localizedPrimaryMessage = "M"
            case localizedDetailMessage = "D"
            case localizedHintMessage = "H"
            case statementPosition = "P"
            case internalPosition = "p"
            case internalQuery = "q"
            case context = "W"
            case schemaName = "s"
            case tableName = "t"
            case columnName = "c"
            case datatypeName = "d"
            case constraintName = "n"
            case sourceFile = "F"
            case sourceLine = "L"
            case sourceFunction = "R"
        }
        
        public enum Severity: String {
            case debug = "DEBUG"
            case info = "INFO"
            case notice = "NOTICE"
            case warning = "WARNING"
            case error = "ERROR"
            case log = "LOG"
            case fatal = "FATAL"
            case panic = "PANIC"
        }
    }
}
