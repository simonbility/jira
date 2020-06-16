//
//  File.swift
//  
//
//  Created by Simon Anreiter on 16.06.20.
//

import Foundation
import TSCUtility
import TSCBasic

enum Shell {
    
    static func execute(arguments: [String], reason: String?) throws -> String {
        let tc = TerminalController(stream: stdoutStream)
        if let reason = reason {
            tc?.write(reason, bold: true)
            tc?.write(": ")
            
        }
        tc?.write(arguments.joined(separator: " "), inColor: .cyan)
        let result = try Process.popen(arguments: arguments)

        
        guard result.exitStatus == .terminated(code: 0) else {
            let output = try result
                .utf8stderrOutput()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            tc?.writeCompact(color: .red, output)
            throw ProcessResult.Error.nonZeroExit(result)
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
        if output.contains(where: { $0.isNewline }) || output.count > 60 {
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
            reason: "Initialize Git"
        )
    }

    func callAsFunction(reason: String? = nil, _ args: String...) throws -> String {
        try execute(arguments: args, reason: reason)
    }

    func execute(reason: String? = nil, _ args: String...) throws -> String {
        return try execute(arguments: args, reason: reason)
    }

    func execute(arguments: [String], reason: String?) throws -> String {
        return try Shell.execute(arguments:  [executable] + arguments, reason: reason)
    }

    func getCurrentBranch() throws -> String {
        return try execute(
            reason: "Get Branch Name",
            "rev-parse",
            "--abbrev-ref",
            "HEAD"
        )
    }
}
