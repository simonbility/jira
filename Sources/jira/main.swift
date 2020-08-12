import Foundation
import TSCBasic

let git = try Git()
let api = API()
let terminal = TerminalController(stream: stdoutStream)

Jira.main()
