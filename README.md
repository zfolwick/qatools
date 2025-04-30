# qatools
A collection of tools to make automation triage easier.

# Capabilities
* cross-reference test cases among different sources
* list test steps in manual test case repository
* whatever else you can think of

As someone who troubleshoots test automation failures, I'm constantly cross-referencing a test case id found in failing automated test case with JIRA to discover more bugs, and the manual bug repository. Navigating between websites to cross-reference information is needlessly laborious and limits productivity. With a simple query, I can discover which jira tickets a test case ID is mentioned in, whether they're bugs or not, and with another command, I can list test case information with the manual test cases. Currently, I've added testrail and jira integration, so users can query testrail for test case IDs, or they can query jira for search terms.

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

# Examples
Search in jira for bugs related to a test case:
## Simple jira searches
```bash
 $ ./search.sh jira --query=C123456 --type=Bug
{"expand":"names,schema","startAt":0,"maxResults":50,"total":1,"issues":[{"expand":"operations,versionedRepresentations,editmeta,changelog,renderedFields","id":"9876543","self":"https://your-enterprise-jira-domain.com/rest/api/2/issue/9876543","key":"USA-769"}]}
```
The output is raw json, and can be formatted with jq with a `--pretty` flag

```bash
$ ./search.sh jira --query=C123456 --type=Bug --pretty
{
  "expand": "names,schema",
  "startAt": 0,
  "maxResults": 50,
  "total": 1,
  "issues": [
    {
      "expand": "operations,versionedRepresentations,editmeta,changelog,renderedFields",
      "id": "9876543",
      "self": "https://sim.starbucks.com/rest/api/2/issue/9876543",
      "key": "USA-769"
    }
  ]
}
```
Most of this information is not useful, so I choose instead to use a `--issues-only` (or `-i`) flag:
```bash
$ ./search.sh jira --query=C123456 --type=Bug --issues-only
USA-759
```
this provides the compact output required.

## testrail examples
In order to verify test steps are in sync with automation steps, I can list out the steps via `$ ./search.sh testrail --case=12345 -p | jq '.. | objects | .step | select(.)'` and get the list of steps:
```bash
"Login into the app"
"Select \"scan payment\"."
"Scan a valid credit card."
"Log in to mobile app (app https://app.test.com/) with the same credentials as the credit card."
"Compare previous orders."
```
I now can simply read the test automation steps and compare to what is in the testrail test case repository for test case 12345.
