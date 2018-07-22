//
//  Lexer.swift
//  Kaleidoscope
//
//  Created by Tyler Thompson on 7/15/18.
//  Copyright © 2018 Asynchrony Labs. All rights reserved.
//

import Foundation
class Lexer {
    let input: String
    var index: String.Index
    var atLineStart = true
    var lastScope:Scope?
    var lastKeyword:Step.Keyword?
    
    init(input: String) {
        self.input = input
        self.index = input.startIndex
    }
    
    var currentChar: Character? {
        return index < input.endIndex ? input[index] : nil
    }
    
    var nextChar: Character? {
        if let i = input.index(index, offsetBy: 1, limitedBy: input.endIndex) {
            return input[i]
        }
        return nil
    }
    
    func advanceIndex() {
        _ = input.formIndex(&index, offsetBy: 1, limitedBy: input.endIndex)
    }
    
    @discardableResult func readLineUntil(_ evaluation:((Character) -> Bool)) -> String {
        var str = ""
        while let char = currentChar, !char.isNewline, !evaluation(char) {
            str.append(char)
            advanceIndex()
        }
        return str
    }
    
    @discardableResult func stripSpaceIfNecessary() -> Bool {
        if let c = currentChar, c.isSpace {
            readLineUntil { !$0.isSpace }
            return true
        }
        return false
    }
    
    func advanceToNextToken() -> Token? {
        guard let char = currentChar else {
            return nil
        }
        if (char.isNewline) {
            advanceIndex()
            atLineStart = true
            lastScope = nil
            lastKeyword = nil
            return .newLine
        } else if char.isComment {
            advanceIndex()
            while let char = currentChar, !char.isNewline {
                advanceIndex()
            }
            advanceIndex()
            return advanceToNextToken()
        } else if char.isTagMarker {
            atLineStart = false
            advanceIndex()
            return .tag(readLineUntil({ !$0.isAlphanumeric }))
        } else if char.isTableCellDelimiter {
            atLineStart = false
            advanceIndex()
            let tableCellContents = readLineUntil({ $0.isTableCellDelimiter }).trimmingCharacters(in: .whitespaces)
            if (!tableCellContents.isEmpty) {
                return .tableCell(tableCellContents)
            }
            return advanceToNextToken()
        }
        if (atLineStart) {
            if (stripSpaceIfNecessary()) {
                return advanceToNextToken()
            }
            atLineStart = false
            let i = index
            let scope = Scope.scopeFor(str: readLineUntil{ $0.isScopeTerminator }
                + String(describing: Character.scopeTerminator))
            if (scope != .unknown) {
                advanceIndex() //strip scope terminator
                lastScope = scope
                stripSpaceIfNecessary()
                return .scope(scope)
            } else { index = i }
            if let keyword = Step.Keyword(rawValue: readLineUntil{ $0.isSpace }.lowercased()) {
                lastKeyword = keyword
                stripSpaceIfNecessary()
                return .keyword(keyword)
            } else {
                index = i
                return .description(readLineUntil{ $0.isNewline }.trimmingCharacters(in: .whitespaces))
            }
        } else if let _ = lastScope {
            return .title(readLineUntil{ $0.isSymbol }.trimmingCharacters(in: .whitespaces))
        } else if char.isHeaderOpen {
            advanceIndex()
            let str = readLineUntil{ $0.isHeaderClosed }
            advanceIndex()
            return .tableHeader(str)
        } else if char.isQuote {
            advanceIndex()
            let str = readLineUntil{ $0.isQuote }
            advanceIndex()
            return .string(str)
        } else if let _ = lastKeyword {
            return .match(readLineUntil{ $0.isSymbol })
        } else {
            advanceIndex()
            return advanceToNextToken()
        }
        //        else if char.isNumeric {
        //            let digits = readLineUntil{ !$0.isNumeric }
        //            if let next = currentChar,
        //                next.isDecimal {
        //                advanceIndex()
        //                let decimalDigits = readLineUntil{ !$0.isNumeric }
        //                var isDouble = false
        //                if let n = currentChar,
        //                    n.isSpace {
        //                    isDouble = true
        //                } else { //EOF
        //                    isDouble = true
        //                }
        //                if (isDouble) {
        //                    return .double(Double(digits + "." + decimalDigits)!)
        //                } else {
        //                    return .integer(Int(digits)!)
        //                }
        //            } else {
        //                return .integer(Int(digits)!)
        //            }
        //        }
    }
    
    func lex() -> [Token] {
        var toks = [Token]()
        while let tok = advanceToNextToken() {
            toks.append(tok)
        }
        return toks
    }
}