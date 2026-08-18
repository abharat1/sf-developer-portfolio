# Salesforce Developer Portfolio Platform

A Salesforce-native developer portfolio: your projects live as records, rendered
by a Lightning Web Component, enriched with live GitHub stats via an Apex
callout, with real visitor analytics powered by a trigger + Queueable Apex.

## What's in this repo

```
force-app/main/default/
├── objects/
│   ├── Project__c/            # your portfolio items
│   └── Visitor_Log__c/        # one record per page view
├── classes/
│   ├── ProjectController.cls          # LWC-facing Apex (@AuraEnabled)
│   ├── ProjectControllerTest.cls
│   ├── GitHubCalloutService.cls       # REST callout to api.github.com
│   ├── GitHubCalloutServiceTest.cls   # HttpCalloutMock-based tests
│   ├── VisitorLogTriggerHandler.cls   # thin-trigger pattern
│   ├── VisitorLogTriggerHandlerTest.cls
│   ├── VisitorAnalyticsQueueable.cls  # async rollup job
│   └── VisitorAnalyticsQueueable.cls-meta.xml
├── triggers/
│   └── VisitorLogTrigger.trigger
└── lwc/
    └── projectGallery/        # the visible portfolio UI
```

## Setup steps

### 1. Create a scratch org (or use a dev org / sandbox)

```bash
sf org create scratch -f config/project-scratch-def.json -a portfolio-dev
sf project deploy start -o portfolio-dev
```

If you don't have a `config/project-scratch-def.json`, run
`sf project generate` in a fresh folder first, or just deploy this
`force-app` straight into an existing Developer Edition org:

```bash
sf project deploy start --source-dir force-app -o your-org-alias
```

### 2. Create the Named Credential for GitHub

GitHub's public repo read endpoints don't require auth, but a Named
Credential is still the right pattern (and required if you later add a
personal access token for higher rate limits):

- Setup → Named Credentials → New Named Credential
- Label / Name: `GitHub_API`
- URL: `https://api.github.com`
- Identity Type: Anonymous (or Named Principal + a PAT if you want higher
  GitHub rate limits later)

### 3. Assign field-level access

The generated fields default to hidden on profiles. Either add them to a
Permission Set (recommended) or edit field-level security so your admin
profile can see everything under `Project__c` and `Visitor_Log__c`.

### 4. Load some project data

Insert a `Project__c` record per project on your resume, e.g.:

| Name | Tech_Stack__c | GitHub_Repo_Path__c | Description__c |
|---|---|---|---|
| TensorFlow Acrobot | Python,TensorFlow,ML | abharat1/TFAcrobot | RL agent solving a physics-based acrobot problem |
| Word Lookup REST API | Java,Spring Boot,REST | abharat1/wordlookup | REST API for managing words and relations |

Then run the GitHub stats refresh (Anonymous Apex or the LWC button) to pull
live star counts and last-commit dates.

### 5. Drop the LWC on a page

- App Builder → create/edit a Lightning App Page (or Experience Cloud page)
- Drag `projectGallery` onto the page
- Activate it as your org's default Home page, or expose it via
  Experience Cloud as a public site so you have a link to send recruiters

### 6. Run the tests

```bash
sf apex run test --test-level RunLocalTests -o portfolio-dev --result-format human
```

You should see 100% pass with meaningful coverage on the trigger, the
callout service (including a mocked failure case), and the controller.

## Extending this further

- Add `Skill__c` and `Certification__c` objects (same pattern as `Project__c`)
  and a second LWC to round out the "About Me" section
- Wire `VisitorAnalyticsQueueable` to upsert onto a singleton
  `Portfolio_Stats__c` record so the gallery can show a running total without
  a `COUNT()` query on every page load
- Add a Scheduled Apex job that calls `GitHubCalloutService.refreshStatsInvocable`
  nightly so star counts/last-commit dates stay fresh without manual refresh
- Add a contact form LWC that inserts a `Lead` or custom `Contact_Request__c`
  and fires an email alert - closes the loop from "visitor" to "inquiry"
