//
//  File.swift
//
//
//  Created by Simon Anreiter on 28.05.20.
//

import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct Current: ParsableCommand {

    func run() throws {
        guard let tc = TerminalController(stream: stdoutStream) else {
            return
        }
        tc.endLine()
        let git = try Git()
        
        let branch = try git.getCurrentBranch() as NSString

        let range = branch.range(of: #"[A-Z]+-[0-9]+"#, options: .regularExpression)
        let key = branch.substring(with: range)

        guard range.location != NSNotFound else {
            tc.write("couldnt extract ticket from branch-name", inColor: .red)
            Darwin.exit(EXIT_FAILURE)
        }
        

        api.find(key: key) { result in
            switch result {
            case .success(let issue):
                issue.write(to: tc)
                Darwin.exit(EXIT_SUCCESS)
            case .failure(let e):
                print(e)
                Darwin.exit(EXIT_FAILURE)
            }
        }

        dispatchMain()
    }

}
