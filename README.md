# jira

A description of this package.

# Setup
Environment Variable `JIRA_CREDENTIALS` has to be set

```
export JIRA_CREDENTIALS='<email>:<access-token>'
```

# Install
```
swift build -c release
cp -rf .build/release/jira /usr/local/bin
```

# Usage
```
USAGE: jira <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  search                  Search issues on jira
  start                   start new feature branch using ticket-number (without
                          prefix like DEV)
  current                 get current jira ticket from branch-name
```
