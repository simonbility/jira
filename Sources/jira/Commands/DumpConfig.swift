import ArgumentParser
import Foundation
import Yams

struct DumpConfig: AsyncParsableCommand {
    func run() async throws {
        let config = try Configuration.load()
        let encoder = YAMLEncoder()

        try terminal.write(encoder.encode(config))
    }
}
