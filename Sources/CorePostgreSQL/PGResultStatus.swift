//
//  PGResultStatus.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 11/28/16.
//
//

import Foundation
import Clibpq

extension PGResult {
    /// Represents the status of a statement's execution.
    /// 
    /// This `status` will always be `isSuccessful`; if it weren't, the `Status` 
    /// would have instead been thrown in a `PGError.executionFailed` error. 
    /// However, it may indicate that a non-fatal error occurred. If so, it will 
    /// contain details of that error.
    /// 
    /// - RecommendedOver: `PQresultStatus`, `PQresultErrorField`
    public var status: Status {
        return Status(self)
    }
    
    /// Represents the status of a statement's execution—that is, whether it was 
    /// successful, emitted warnings, contains data, etc.
    /// 
    /// A `Status` may be thrown as part of a `PGError.executionFailed` error, or 
    /// it may be accessed through the `PGResult.status` property. In either case, 
    /// it describes the result associated with it and includes detailed information 
    /// about it, which may be accessed by subscripting with a 
    /// `PGResult.Status.FieldCode` or, in some cases, through certain properties. 
    public struct Status {
        /// Whether the status is considered "successful" or not.
        /// 
        /// The value of `isSuccessful` determines whether `PGResult.init(pointer:)`
        /// (and thereby the various `execute(…)` methods as well) will throw the 
        /// status in a `PGError.executionFailed` error or return the result.
        /// 
        /// Successful statuses include:
        /// 
        /// * `PGRES_COMMAND_OK`
        /// * `PGRES_TUPLES_OK`
        /// * `PGRES_SINGLE_TUPLE`
        /// * `PGRES_NONFATAL_ERROR`
        /// * `PGRES_COPY_OUT`
        /// * `PGRES_COPY_IN`
        /// * `PGRES_COPY_BOTH`
        /// 
        /// Other statuses, including the following, are not considered successful:
        /// 
        /// * `PGRES_EMPTY_QUERY`
        /// * `PGRES_BAD_RESPONSE` 
        /// * `PGRES_FATAL_ERROR`
        public var isSuccessful: Bool {
            switch status {
            case PGRES_COMMAND_OK, PGRES_TUPLES_OK, PGRES_SINGLE_TUPLE, PGRES_NONFATAL_ERROR, PGRES_COPY_OUT, PGRES_COPY_IN, PGRES_COPY_BOTH:
                return true
                
            default:
                return false
            }
        }
        
        /// The actual execution status. This is a high-level overview of how the 
        /// execution went. Values come from constants in `libpq`.
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
        
        /// Accesses string versions of the error fields associated with this 
        /// status's result.
        /// 
        /// The fields include detailed information about the error, including 
        /// most importantly the human-readable `localizedPrimaryMessage`, 
        /// `localizedDetailMessage, and `localizedHintMessage` fields. Some of 
        /// these fields have non-`String` equivalents which are properties of 
        /// `Status`.
        public subscript(fieldCode: FieldCode) -> String? {
            return fields[fieldCode]
        }
        
        /// The severity of the status. See `PGResult.Status.Severity` for more 
        /// details.
        /// 
        /// - RecommendedOver: `PGResult.Status.FieldCode.severity`
        public var severity: Severity {
            let value = self[.severity] ?? self[.localizedSeverity]!
            return Severity(rawValue: value)!
        }
        
        /// The `sqlState` of the status.
        /// 
        /// `sqlState` is a semi-standardized error code. See 
        /// [the PostgreSQL documentation](https://www.postgresql.org/docs/9.4/static/errcodes-appendix.html)
        /// for detailed information about the possible SQL states.
        public var sqlState: String {
            return self[.sqlState]!
        }
        
        /// The position of the error in the statement, in number of characters 
        /// from the beginning of the statement. `nil` if no such position is 
        /// included in the status.
        /// 
        /// - Note: Although the underlying `statementPosition` field code returns 
        ///          a 1-based index, this value is 0-based.
        /// 
        /// - RecommendedOver: `PGResult.Status.FieldCode.statementPosition`
        public var statementPosition: Int? {
            return self[.statementPosition].map { Int($0)! - 1 }
        }
        
        /// The position of the error in the `internalQuery`, in number of characters 
        /// from the beginning of the statement. `nil` if no such position is 
        /// included in the status.
        /// 
        /// - Note: Although the underlying `internalPosition` field code returns 
        ///          a 1-based index, this value is 0-based.
        /// 
        /// - RecommendedOver: `PGResult.Status.FieldCode.internalPosition`
        public var internalPosition: Int? {
            return self[.internalPosition].map { Int($0)! - 1 }
        }
        
        /// The error message fields which may be included in a `PGResult.Status`.
        /// 
        /// These fields include a mixture of human-readable error messages and 
        /// machine-readable details about the error. They may not all be present 
        /// in a given status.
        public enum FieldCode: UnicodeScalar {
            static var all = [FieldCode.localizedSeverity, .severity, .sqlState, .localizedPrimaryMessage, .localizedDetailMessage, .localizedHintMessage, .statementPosition, .internalPosition, .internalQuery, .context, .schemaName, .tableName, .columnName, .datatypeName, .constraintName, .sourceFile, .sourceLine, .sourceFunction]
            
            /// The severity of the message as a localized string. Some versions of 
            /// PostgreSQL only support this value, not the non-localized `severity`.
            case localizedSeverity = "S"
            
            /// The severity of the message. This is always one of a small number of 
            /// strings.
            /// 
            /// - Recommended: `PGResult.Status.severity`
            case severity = "V"
            
            /// The `sqlState` of the status.
            /// 
            /// `sqlState` is a semi-standardized error code. See 
            /// [the PostgreSQL documentation](https://www.postgresql.org/docs/9.4/static/errcodes-appendix.html)
            /// for detailed information about the possible SQL states.
            case sqlState = "C"
            
            /// A terse, human-readable description of the error.
            case localizedPrimaryMessage = "M"
            
            /// A more detailed human-readable description of the error. May be 
            /// several lines long.
            case localizedDetailMessage = "D"
            
            /// A suggestion about how the error may be fixed. The advice it offers 
            /// may not always be correct.
            case localizedHintMessage = "H"
            
            /// The position of the error in the statement, in number of characters 
            /// from the beginning of the statement. This is a 1-based number of 
            /// characters; the status's `statementPosition` property provides the 
            /// same information as a more useful 0-based `Int`.
            /// 
            /// - Recommended: `PGResult.Status.statementPosition`
            case statementPosition = "P"
            
            /// The position of the error in the `internalQuery`, in number of characters 
            /// from the beginning of the statement. This is a 1-based number of 
            /// characters; the status's `internalPosition` property provides the 
            /// same information as a more useful 0-based `Int`.
            /// 
            /// - Recommended: `PGResult.Status.internalPosition`
            case internalPosition = "p"
            
            /// The text of a query generated by `PostgreSQL` itself. For instance, if 
            /// a PL/pgSQL function uses a query and that query encounters an error, 
            /// this will be the source of that query.
            case internalQuery = "q"
            
            /// A stack trace of any stored procedures and internally-generated 
            /// queries involved in this error.
            case context = "W"
            
            /// The name of the schema, if any, associated with this status.
            case schemaName = "s"
            
            /// The name of the table, if any, associated with this status.
            case tableName = "t"
            
            /// The name of the column, if any, associated with this status.
            case columnName = "c"
            
            /// The name of the data type, if any, associated with this status.
            case datatypeName = "d"
            
            /// The name of the constraint, if any, associated with this status.
            case constraintName = "n"
            
            /// The name of the source file where the error occurred.
            case sourceFile = "F"
            
            /// The line of the source file where the error occurred.
            case sourceLine = "L"
            
            /// The name of the source function where the error occurred.
            case sourceFunction = "R"
        }
        
        /// Possible severities for a message associated with a status.
        /// 
        /// See [the PostgreSQL documentation](https://www.postgresql.org/docs/9.4/static/runtime-config-logging.html#RUNTIME-CONFIG-SEVERITY-LEVELS)
        /// for details on the meaning of PostgreSQL's severity levels.
        public enum Severity: String, Hashable, Comparable {
            /// The lowest severity; indicates diagnostic information useful for 
            /// developers.
            case debug = "DEBUG"
            
            /// Information of interest to administrators.
            case log = "LOG"
            
            /// Information requested by the user, such as the output of a 
            /// `VACUUM VERBOSE` command. 
            case info = "INFO"
            
            /// Information that might be helpful to the user, such as notice of a 
            /// truncated identifier.
            case notice = "NOTICE"
            
            /// Information warning of a likely problem, such as a `COMMIT` without 
            /// a transaction.
            case warning = "WARNING"
            
            /// An error which caused the current command to abort.
            case error = "ERROR"
            
            /// An error which caused the current connection to abort.
            case fatal = "FATAL"
            
            /// An error which caused all sessions on the server to abort.
            case panic = "PANIC"
            
            private var ordering: Int {
                switch self {
                case .debug: return 0
                case .log: return 1
                case .info: return 2
                case .notice: return 3
                case .warning: return 4
                case .error: return 5
                case .fatal: return 6
                case .panic: return 7
                }
            }
            
            public static func < (lhs: Severity, rhs: Severity) -> Bool {
                return lhs.ordering < rhs.ordering
            }
        }
    }
}
