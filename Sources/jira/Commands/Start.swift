import ArgumentParser
import Foundation
import TSCBasic
import TSCUtility

struct Start: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "start new feature branch using ticket-number (without prefix like DEV)"
    )

    @Argument()
    var number: String

    func run() throws {

        let git = try Git()

        api.find(key: "DEV-\(number)") { result in
            switch result {
            case .success(let issue):
                let branch = issue.branch

                _ = try! git.execute(
                    reason: "New Branch",
                    "flow",
                    branch.type,
                    "start",
                    branch.name
                )

                Darwin.exit(EXIT_SUCCESS)
            case .failure(let e):
                print(e)
                Darwin.exit(EXIT_FAILURE)
            }
        }

        dispatchMain()
    }

}
