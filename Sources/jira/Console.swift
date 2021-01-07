//
//  File.swift
//
//
//  Created by Simon Anreiter on 07.01.21.
//

import Foundation
import TSCBasic

struct Console {
    let terminal = TerminalController(stream: stdoutStream)
    
    func writeLine(_ txt: String, inColor color: TerminalController.Color = .noColor, debug: Bool = false) {
        if let terminal = terminal {
            terminal.write(txt, inColor: color)
            terminal.endLine()
        } else if !debug {
            print(txt)
        }
    }
    
    func write(_ txt: String, inColor color: TerminalController.Color = .noColor, debug: Bool = false) {
        if let terminal = terminal {
            terminal.write(txt, inColor: color)
        } else if !debug {
            print(txt, terminator: "")
        }
    }
    
    func endLine(debug: Bool = false) {
        if let terminal = terminal {
            terminal.endLine()
        } else if !debug {
            print("")
        }
    }
}
