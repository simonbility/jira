//
//  File.swift
//  
//
//  Created by Simon Anreiter on 16.06.20.
//

import Foundation
import TSCUtility
import TSCBasic
import ArgumentParser

enum Shell {
    
    struct Errors: LocalizedError {
        let errorDescription: String?
    }
    
    static func execute(arguments: [String], quiet: Bool = false) throws -> String {
        let tc = quiet ? nil : TerminalController(stream: stdoutStream)
        tc?.write(arguments.joined(separator: " "), inColor: .cyan)
        let result = try Process.popen(arguments: arguments)
        
        guard result.exitStatus == .terminated(code: 0) else {
            let output = try result
                .utf8stderrOutput()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            tc?.writeCompact(color: .red, output)
            
            throw ExitCode.failure
        }

        let output = try
            result
            .utf8Output()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        tc?.writeCompact(color: .green, output)

        return output
    }
}

extension TerminalController {
    
    func writeCompact(color: TerminalController.Color, _ output: String) {
        if output.contains(where: \.isNewline) || output.count > 60 {
            endLine()
            write(output, inColor: color)
        } else {
            write(" > ")
            write(output, inColor: color)
        }
        endLine()
    }
    
}

struct Git {
    enum Error: Swift.Error {
        case enexpectedExitCode(Int)
    }

    let executable: String

    init() throws {
        executable = try Shell.execute(
            arguments: ["which", "git"],
            quiet: true
        )
    }

    func callAsFunction(reason: String? = nil, _ args: String...) throws -> String {
        try execute(arguments: args, reason: reason)
    }

    @discardableResult
    func execute(reason: String? = nil, _ args: String...) throws -> String {
        return try execute(arguments: args, reason: reason)
    }

    @discardableResult
    func execute(arguments: [String], reason: String?) throws -> String {
        return try Shell.execute(arguments:  [executable] + arguments)
    }

    func getCurrentBranch() throws -> String {
        return try execute(
            reason: "Get Branch Name",
            "rev-parse",
            "--abbrev-ref",
            "HEAD"
        )
    }
    
    func getIssueKeyFromBranch() throws -> String {
        let branch = try getCurrentBranch() as NSString
            
        let range = branch.range(of: #"[A-Z]+-[0-9]+"#, options: .regularExpression)
        
        guard range.location != NSNotFound else {
            throw Current.Errors.noTicketPatternFound
        }
        
        return branch.substring(with: range)
    }
}
