//
//  Parser.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/3/16.
//
//

import Foundation

protocol StringParser {
    associatedtype ParseState: PGConversionErrorParsingState
    associatedtype ParseResult
    
    var initialParseState: ParseState { get }
    func continueParsing(_ char: Character, in state: ParseState) throws -> ParseState
    func finishParsing(in state: ParseState) throws -> ParseResult
    func wrapError(_ error: Error, at index: String.Index, in string: String, during state: ParseState) -> Error
}

extension StringParser {
    func parse(_ string: String) throws -> ParseResult {
        let characters = string.characters
        let indices = characters.indices
        
        let finalState = try indices.reduce(initialParseState) { state, index in
            do {
                let char = characters[index]
                return try continueParsing(char, in: state)
            }
            catch {
                throw wrapError(error, at: index, in: string, during: state)
            }
        }
        do {
            return try finishParsing(in: finalState)
        }
        catch {
            throw wrapError(error, at: string.endIndex, in: string, during: finalState)
        }
    }
}
