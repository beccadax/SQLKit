//
//  PGConnVariables.swift
//  LittlinkRouterPerfect
//
//  Created by Becca Royal-Gordon on 12/3/16.
//
//

import Foundation
import Clibpq

extension PGConn {
    /// Returns a quoted form of the string which can be concatenated with a 
    /// SQL statement to add an identifier, such as a table or column name.
    /// 
    /// - Parameter identifier: The identifier string to quote.
    /// - Returns: A string that can be concatenated into a SQL string.
    /// 
    /// - RecommendedOver: `PQescapeIdentifier`
    public func quotedIdentifier(_ identifier: String) -> String {
        return identifier.withCString { inCString in
            let outCString = PQescapeLiteral(pointer, inCString, Int(strlen(inCString)))!
            defer { PQfreemem(outCString) }
            return String(cString: outCString)
        }
    }
    
    /// Returns a quoted form of the string which can be concatenated with a 
    /// SQL statement to add a string literal.
    ///
    /// - Parameter string: The string to quote, or `nil` if a `NULL` should be 
    ///               added.
    /// - Returns: A string that can be concatenated into a SQL string.
    /// 
    /// - Note: While it's usually better to use `PGConn.execute(_:with:returningIn:)`  
    ///          to pass data without concatenating it into a SQL string, occasionally  
    ///          PostgreSQL will not allow a placeholder at a particular location. 
    ///          This method can help you in such a situation.
    /// 
    /// - RecommendedOver: `PQescapeLiteral`
    public func quotedLiteral(_ string: String?) -> String {
        guard let string = string else {
            return "NULL"
        }
        
        return string.withCString { inCString in
            let outCString = PQescapeLiteral(pointer, inCString, Int(strlen(inCString)))!
            defer { PQfreemem(outCString) }
            return String(cString: outCString)
        }
    }
    
    internal func value(for variable: String) -> String? {
        let result = try! execute("SHOW \(variable)")
        
        precondition(result.tuples.count == 1, "Retrieved \(result.tuples.count) rows while trying to show \(variable)")
        precondition(result.fields.count == 1, "Retrieved \(result.tuples.count) columns while trying to show \(variable)")
        
        return try! result.tuples[0].value(at: 0, as: String.self)!
    }
    
    internal func setValue(_ value: String?, for variable: String) {
        let quotedValue = quotedLiteral(value)
        
        _ = try! execute("SET \(variable) = \(quotedValue)")
    }
    
    /// The encoding which strings are retrieved as; equivalent to the 
    /// `client_encoding` configuration variable.
    /// 
    /// This property is read-only because this library requires that the 
    /// client encoding always be set to `Encoding.utf8`. If it is set to anything 
    /// else, this library may not be able to correctly convert data between 
    /// Swift `String`s and the raw data buffers PostgreSQL uses. Never use any  
    /// mechanism to set the `client_encoding` configuration variable to 
    /// anything but `UTF8`.
    /// 
    /// The fact that Unicode is used as the client encoding should not affect 
    /// the data stored by the PostgreSQL server; you can access text in 
    /// databases that use any server encoding.
    /// 
    /// - RecommendedOver: `PQclientEncoding`
    public internal(set) var clientEncoding: Encoding? {
        get {
            guard let pointer = pointer else {
                preconditionFailure("Can't access client encoding after finishing")
            }
            
            let encodingID = PQclientEncoding(pointer)
            let encodingCString = pg_encoding_to_char(encodingID)!
            return Encoding(rawValue: String(cString: encodingCString))
        }
        set {
            let hadError = PQsetClientEncoding(pointer, newValue?.rawValue ?? Encoding.unknownSQLASCIIName)
            precondition(hadError == 0, "Can't set client encoding to \(newValue)")
        }
    }
    
    /// The format of DATE, TIME, and TIMESTAMP columns when rendered as text.
    /// 
    /// This property is read-only because this library requires that the 
    /// date style always be set to `DateStyle(format: .iso, order: .ymd)`. 
    /// If it is set to anything else, this library may not be able to correctly 
    /// interpret date values returned by queries. Never use any  
    /// mechanism to set the `DateStyle` configuration variable to 
    /// anything but `ISO, YMD`.
    public internal(set) var dateStyle: DateStyle {
        get {
            let rawValue = value(for: "DateStyle")!
            return DateStyle(rawValue: rawValue)!
        }
        set {
            setValue(newValue.rawValue, for: "DateStyle")
        }
    }
    
    /// The format of INTERVAL columns when rendered as text.
    /// 
    /// This property is read-only because this library requires that the 
    /// date style always be set to `IntervalStyle.iso8601`. 
    /// If it is set to anything else, this library may not be able to correctly 
    /// interpret interval values returned by queries. Never use any  
    /// mechanism to set the `IntervalStyle` configuration variable to 
    /// anything but `iso_8601`.
    public internal(set) var intervalStyle: IntervalStyle {
        get {
            let rawValue = value(for: "IntervalStyle")!
            return IntervalStyle(rawValue: rawValue)!
        }
        set {
            setValue(newValue.rawValue, for: "IntervalStyle")
        }
    }
    
    /// Supported styles for INTERVAL columns and values.
    public enum IntervalStyle: String {
        /// The `sql_standard` format (e.g. `-1-2 +3 -4:05:06`).
        case sqlStandard = "sql_standard"
        
        /// The `postgres` format (e.g. `-1 year -2 mons +3 days -04:05:06`).
        case postgres = "postgres"
        
        /// The `postgres_verbose` format (e.g. 
        /// `@ 1 year 2 mons -3 days 4 hours 5 mins 6 secs ago`).
        case postgresVerbose = "postgres_verbose"
        
        /// The `iso_8601` format (e.g. `P-1Y-2M3DT-4H-5M-6S`).
        case iso8601 = "iso_8601"
    }
    
    /// Supported styles for DATE, TIME, and TIMESTAMP columns and values. 
    public enum DateStyle: RawRepresentable {
        /// The `ISO` format (e.g. `1997-12-17 07:37:16-08`).
        /// 
        /// - Note: This is, at best, an ISO-inspired format; it does not follow 
        ///          ISO-8601 faithfully.
        case iso
        
        /// The `German` format (e.g. `17.12.1997 07:37:16.00 PST`).
        case german
        
        /// The `SQL` format (e.g. `12/17/1997 07:37:16.00 PST`).
        case sql(Order)
        
        /// The `Postgres` format (e.g. `Wed Dec 17 07:37:16 1997 PST`).
        case postgres(Order)
        
        /// The order of the date fields in `sql` or `postgres` formats.
        public enum Order: String {
            /// Day, month, year order.
            case dmy = "DMY"
            /// Month, day, year order.
            case mdy = "MDY"
            /// Year, month, day order.
            case ymd = "YMD"
            
            private static let names: [String: Order] = [
                "DMY": .dmy, "Euro": .dmy, "European": .dmy,
                "MDY": .mdy, "US": .mdy, "NonEuro": .mdy, "NonEuropean": .mdy,
                "YMD": .ymd,
            ]
            
            public init?(rawValue: String) {
                guard let order = Order.names[rawValue] else {
                    return nil
                }
                self = order
            }
        }
        
        public init?(rawValue: String) {
            let parts = rawValue.components(separatedBy: ", ")
            precondition(parts.count == 1 || parts.count == 2, "DateStyle string should have two parts")
            
            switch (parts[0], parts.last) {
            case ("ISO", _):
                self = .iso
                
            case ("German", _):
                self = .german
                
            case ("SQL", nil):
                self = .sql(.mdy)
            case ("SQL", let orderRaw?):
                guard let order = Order(rawValue: orderRaw) else {
                    return nil
                }
                self = .sql(order)
                
            case ("Postgres", nil):
                self = .postgres(.mdy)
            case ("Postgres", let orderRaw?):
                guard let order = Order(rawValue: orderRaw) else {
                    return nil
                }
                self = .postgres(order)
                
            default: 
                return nil
            }
        }
        
        public var rawValue: String {
            switch self {
            case .iso:
                return "ISO"
            case .german:
                return "German"
            case .sql(let order):
                return "SQL, \(order.rawValue)"
            case .postgres(let order):
                return "Postgres, \(order.rawValue)"
            }
        }
    }
    
    /// Text encodings supported in some fashion by PostgreSQL.
    public enum Encoding: String {
        static let unknownSQLASCIIName = "SQL_ASCII"
        
        case utf8 = "UTF8"          // Unicode
        case big5 = "BIG5"          // WIN950, Windows950
        case eucCN = "EUC_CN"
        case eucJP = "EUC_JP"
        case eucJIS2004 = "EUC_JIS_2004"
        case eucKR = "EUC_KR"
        case eucTW = "EUC_TW"
        case gb18030 = "GB18030"
        case gbk = "GBK"            // WIN936, Windows936
        case iso8859_5 = "ISO_8859_5"
        case iso8859_6 = "ISO_8859_6"
        case iso8859_7 = "ISO_8859_7"
        case iso8859_8 = "ISO_8859_8"
        case johab = "JOHAB"
        case koi8R = "KOI8R"        // KOI8
        case koi8U = "KOI8U"
        case latin1 = "LATIN1"      // ISO88591
        case latin2 = "LATIN2"      // ISO88592
        case latin3 = "LATIN3"      // ISO88593
        case latin4 = "LATIN4"      // ISO88594
        case latin5 = "LATIN5"      // ISO88595
        case latin6 = "LATIN6"      // ISO88596
        case latin7 = "LATIN7"      // ISO88597
        case latin8 = "LATIN8"      // ISO88598
        case latin9 = "LATIN9"      // ISO88599
        case latin10 = "LATIN10"    // ISO885910
        case muleInternal = "MULE_INTERNAL"
        case shiftJIS = "SJIS"      // Mskanji, ShiftJIS, WIN932, Windows932
        case shiftJIS2004 = "SHIFT_JIS_2004"
        case uhc = "UHC"
        case win866 = "WIN866"      // ALT
        case win874 = "WIN874"
        case win1250 = "WIN1250"
        case win1251 = "WIN1251"    // WIN
        case win1252 = "WIN1252"
        case win1253 = "WIN1253"
        case win1254 = "WIN1254"
        case win1255 = "WIN1255"
        case win1256 = "WIN1256"
        case win1257 = "WIN1257"
        case win1258 = "WIN1258"
        
        private static let names: [String: Encoding?] = [
            "UTF8": .utf8, "UNICODE": .utf8,
            "BIG5": .big5, "WIN950": .big5, "Windows950": .big5,
            "EUC_CN": .eucCN,
            "EUC_JP": .eucJP,
            "EUC_JIS_2004": .eucJIS2004,
            "EUC_KR": .eucKR,
            "EUC_TW": .eucTW,
            "GB18030": .gb18030,
            "GBK": .gbk, "WIN936": .gbk, "Windows936": .gbk,
            "ISO_8859_5": .iso8859_5,
            "ISO_8859_6": .iso8859_6,
            "ISO_8859_7": .iso8859_7,
            "ISO_8859_8": .iso8859_8,
            "JOHAB": .johab,
            "KOI8R": .koi8R, "KOI8": .koi8R,
            "KOI8U": .koi8U,
            "LATIN1": .latin1, "ISO88591": .latin1,
            "LATIN2": .latin2, "ISO88592": .latin2,
            "LATIN3": .latin3, "ISO88593": .latin3,
            "LATIN4": .latin4, "ISO88594": .latin4,
            "LATIN5": .latin5, "ISO88595": .latin5,
            "LATIN6": .latin6, "ISO88596": .latin6,
            "LATIN7": .latin7, "ISO88597": .latin7,
            "LATIN8": .latin8, "ISO88598": .latin8,
            "LATIN9": .latin9, "ISO88599": .latin9,
            "LATIN10": .latin10, "ISO885910": .latin10,
            "MULE_INTERNAL": .muleInternal,
            "SJIS": .shiftJIS, "Mskanji": .shiftJIS, "ShiftJIS": .shiftJIS, "WIN932": .shiftJIS, "Windows932": .shiftJIS,
            "SHIFT_JIS_2004": .shiftJIS2004,
            "UHC": .uhc,
            "WIN866": .win866, "ALT": .win866,
            "WIN874": .win874,
            "WIN1250": .win1250,
            "WIN1251": .win1251, "WIN": .win1251,
            "WIN1252": .win1252,
            "WIN1253": .win1253,
            "WIN1254": .win1254,
            "WIN1255": .win1255,
            "WIN1256": .win1256,
            "WIN1257": .win1257,
            "WIN1258": .win1258,
            "SQL_ASCII": nil
        ]
        
        public init?(rawValue: String) {
            guard let enc = Encoding.names[rawValue] ?? nil else {
                return nil
            }
            self = enc
        }
    }
}
