//
//  File.swift
//  
//
//  Created by Simon Anreiter on 25.05.20.
//

import Foundation

struct ToolChain {
    let api: JiraAPI
    let git: Git
}


struct Configuration {
    var credentials: String?
    
    static let environment = Configuration(
        credentials: ProcessInfo.processInfo.environment["JIRA_CREDENTIALS"]
    )
}

let api = API(credentials: Configuration.environment.credentials!)
