import Foundation
import TSCBasic

struct Console {
    let terminal = TerminalController(stream: stdoutStream)

    var isInteractive: Bool {
        terminal != nil
    }

    func writeLine(
        _ txt: String,
        inColor color: TerminalController.Color = .noColor,
        debug: Bool = false
    ) {
        if let terminal = terminal {
            terminal.write(txt, inColor: color)
            terminal.endLine()
        } else if !debug {
            print(txt)
        }
    }

    func write(
        _ txt: String,
        inColor color: TerminalController.Color = .noColor,
        debug: Bool = false
    ) {
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

    func ask(_ question: String) -> String {
        askChecked(question, transform: { $0 })
    }

    func askChecked<Value>(
        _ question: String,
        default defaultValue: Value? = nil,
        transform: (String) throws -> Value
    ) -> Value {
        while true {
            write("\(question):")
            let value = readLine(strippingNewline: true)

            if let value = value {
                if let defaultValue = defaultValue, value.isEmpty {
                    return defaultValue
                }
                do {
                    return try transform(value)
                } catch {
                    write("\(error)", inColor: .red)
                }
            }
        }
    }

    func askChecked<Value>(
        _ question: String,
        default defaultValue: Value? = nil,
        transformRequiring transform: (String) -> Value?
    ) -> Value {
        while true {
            write("\(question):")
            let value = readLine(strippingNewline: true)

            if let value = value {
                if let defaultValue = defaultValue, value.isEmpty {
                    return defaultValue
                }

                if let value = transform(value) {
                    return value
                }
            }
        }
    }
}
