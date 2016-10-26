//
//  SourceEditorCommand.swift
//  Quick NSLocalized
//
//  Created by Nik Savko on 10/26/16.
//  Copyright © 2016 Nik Savko. All rights reserved.
//

import Foundation
import XcodeKit

extension NSRange {
    func intersects(_ range: NSRange) -> Bool {
        return (location >= range.location && location <= range.location + range.length) || (range.location >= location && range.location <= location + length)
    }
}

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        var completionError: Error?
        defer { completionHandler(completionError) }
        
        guard let selection = invocation.buffer.selections
            .map({ $0 as! XCSourceTextRange})
            .first(where: { $0.start.line == $0.end.line }) else {
                return
        }
        let selectionRange = NSRange(location: selection.start.column, length: selection.start.line)
        let line = invocation.buffer.lines[selection.start.line] as! NSString
        do {
            //TODO: handle interpolated strings
            let regex = try NSRegularExpression(pattern: "\".*?(\\\\\\\\\"|(?<=[^\\\\])\")", options: .caseInsensitive)
            guard let matchRange = regex.matches(in: line as String, options: [], range: NSRange(0..<line.length))
                .first(where: { $0.range.intersects(selectionRange) })?.range else {
                    return
            }
            let replacement = "NSLocalizedString(\(line.substring(with: matchRange)), comment: \"\")"
            invocation.buffer.lines[selection.start.line] = line.replacingCharacters(in: matchRange, with: replacement)
        } catch {
            completionError = error
            return
        }
    }
}
