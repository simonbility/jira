# jira

A description of this package.

# Setup
Environment Variable `JIRA_CREDENTIALS` has to be set

```
export JIRA_CREDENTIALS='<email>:<access-token>'
```

Its also recommended to install
`gh` for interacting with github (creating PullRequests)
`figlet` for creating fancy asci-art in sprint-reports


before using you should run `jira init` 
for Backend devs `jira init --global --default-fix-version Backend` is recommended

# Install
```
swift build -c release
ditto .build/release/jira /usr/local/bin
```

# Usage
```
USAGE: jira <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  init
  search                  Search issues on jira
  start                   start new feature branch using ticket-number
  current                 get current jira ticket from branch-name
  finish
  sprint-report           Generates a report about all Tickets in Sprint

  See 'jira help <subcommand>' for detailed help.
```
