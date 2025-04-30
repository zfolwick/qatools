# qatools
A collection of tools to make automation triage easier

# Capabilities
Currently, I've added testrail and jira integration, so users can query testrail for test case IDs, or they can query jira for search terms.

# Extending capabilities
Adding new providers is relatively simple:
1. Create a new file within qa_search/ directory, titled `search_myProvider.sh` and add your script to it.
2. Add any configuration you want to your config file.


# Configuration
This tool expects a config file called .qaconfig located in one of the following directories: ~/.local/bin, ~/, and the current working directory (not recommended).

For Jira access, add the following into your .qaconfig file
```ini
  [jira]
    JIRA_TOKEN=your-jira-token
    JIRA_PROJECT_TEXT="(project%20%3D%20USA%20OR%20project%20%3D%20"Television%20On%Demand")%20"
    JIRA_URL=https://your-domain.com
    JIRA_ENDPOINT=/rest/api/2/search
```
The above configuration expects you to set a jira token (see google if you don't know how to create one).  It also sets the project jql query text to `(project = USA OR project = "Television On Demand")`, which matches results that are either in the _USA_ project or in _Television On Demand_ project in jira; it then sets the JIRA domain to your specified domain, and the JIRA_ENDPOINT to v2 of the api.

# Installation
Depends on `jq`, so have that installed. Built in Bash on Mac.  You can either wget this whole project's files, or clone it.  Wherever you place it on your PATH, include a symlink to the qa_search directory as well, as that'll be needed to interact with the data providers.