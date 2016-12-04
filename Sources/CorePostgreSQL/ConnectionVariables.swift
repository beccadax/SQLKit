//
//  ConnectionVariables.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/3/16.
//
//

import Foundation
import libpq

extension PGConn {
    /// The encoding which strings are retrieved as; equivalent to the 
    /// `client_encoding` configuration variable.
    /// 
    /// This property is read-only because this library requires that the 
    /// client encoding always be set to "Unicode". If it is set to anything 
    /// else, this library may not be able to correctly convert data between 
    /// Swift `String`s and the raw data buffers PostgreSQL uses. Never use any  
    /// mechanism to set the `client_encoding` configuration variable to 
    /// anything but `Unicode`.
    /// 
    /// The fact that Unicode is used as the client encoding should not affect 
    /// the data stored by the PostgreSQL server; you can access text in 
    /// databases that use any server encoding.
    /// 
    /// - RecommendedOver: `PQclientEncoding`
    public internal(set) var clientEncoding: String {
        get {
            guard let pointer = pointer else {
                preconditionFailure("Can't access client encoding after finishing")
            }
            
            let encodingID = PQclientEncoding(pointer)
            let encodingCString = pg_encoding_to_char(encodingID)!
            return String(cString: encodingCString)
        }
        set {
            let hadError = PQsetClientEncoding(pointer, newValue)
            precondition(hadError == 0, "Can't set client encoding to \(newValue)")
        }
    }

}
