import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct Search: ParsableCommand {

    @Option(parsing:.upToNextOption)
    var key: [String]

    @Option(parsing:.singleValue)
    var raw: [String]
    
    @Option(parsing:.upToNextOption)
    var component: [String]
    
    
    @Option(parsing:.upToNextOption)
    var status: [String]
    
    @Option(parsing:.singleValue)
    var sprint: [String]
    
    @Flag()
    var currentSprint: Bool
    
    @Flag()
    var open: Bool

    @Flag()
    var closed: Bool

    var query: JQL {
        var builder = raw

        if !key.isEmpty {
            builder.append("key in (\(key.joined(separator: ", ")))")
        }

        if !sprint.isEmpty {
            builder.append("sprint in (\(sprint.joined(separator: ", ")))")
        }
        if !component.isEmpty {
            builder.append("component in (\(component.joined(separator: ", ")))")
        }
        if !status.isEmpty {
            builder.append("status in (\(status.map { "\"\($0)\"" }.joined(separator: ", ")))")
        }
        if currentSprint {
            builder.append("sprint in openSprints()")
        }
        if open {
            builder.append("status NOT in (\"closed\")")
        }
        if closed {
            builder.append("status in (closed)")
        }

        return JQL(rawValue: builder.joined(separator: " AND "))
    }

    func run() throws {
        
        guard let terminalController = TerminalController(stream: stdoutStream) else {
            return
        }
        guard !query.rawValue.isEmpty else {
            Darwin.exit(EXIT_FAILURE)
        }
        api.search(query) { result in

            switch result {
            case .success(let results):
                
                for issue in results.issues.sorted(by: { $0.fields.status < $1.fields.status }) {
                    issue.write(to: terminalController)
                }
                Darwin.exit(EXIT_SUCCESS)
            case .failure(let e):
                print(e)
                Darwin.exit(EXIT_FAILURE)
            }
        }

        dispatchMain()
    }

}
