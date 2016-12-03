//
//  Parser.swift
//  LittlinkRouterPerfect
//
//  Created by Brent Royal-Gordon on 12/3/16.
//
//

import Foundation

enum StringParserError: Error {
    case parseError(Error, at: String.Index, in: String, during: PGConversionErrorParsingState)
}

protocol StringParser {
    associatedtype ParseState: PGConversionErrorParsingState
    associatedtype ParseResult
    
    var initialParseState: ParseState { get }
    func continueParsing(_ char: Character, in state: ParseState) throws -> ParseState
    func finishParsing(in state: ParseState) throws -> ParseResult
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
                throw StringParserError.parseError(error, at: index, in: string, during: state)
            }
        }
        do {
            return try finishParsing(in: finalState)
        }
        catch {
            throw StringParserError.parseError(error, at: string.endIndex, in: string, during: finalState)
        }
    }
}
