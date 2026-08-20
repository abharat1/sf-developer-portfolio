# Salesforce Developer Portfolio Platform

A Salesforce-native developer portfolio: instead of a static resume site, my
projects live as actual Salesforce records, rendered by a Lightning Web
Component, enriched with live GitHub stats pulled via an Apex REST callout,
with real visitor analytics powered by an Apex trigger and async Queueable
job — publicly hosted on an Experience Cloud site.

**Live site:** www.resilient-bear-ltto5c-dev-ed.trailblaze.my.site.com
**Built by:** [Anshul Bharati](https://github.com/abharat1) — Salesforce Administrator / Developer

---

## Why I built this

I wanted a portfolio that was actually built on the platform I work in every
day, instead of a generic template site — something that demonstrates the
full stack of Salesforce development: declarative admin work, Apex,
async processing, LWC, external integrations, and public-facing security
configuration, all in one working app.

## What it demonstrates

- **Apex triggers & bulk-safe async processing** — a trigger on visitor logs
  enqueues a single Queueable per transaction (not one per record), avoiding
  a classic bulkification bug
- **REST integration** — an Apex callout to the GitHub API pulls live star
  counts, primary language, and last-commit date for each project, refreshed
  on demand
- **Callout/DML ordering** — the GitHub refresh logic batches all callouts
  before any database writes, avoiding Salesforce's "uncommitted work
  pending" error that shows up when callouts and DML are interleaved in a
  loop
- **Lightning Web Components** — a filterable project gallery with wired and
  imperative Apex calls, client-side filtering, and error handling
  surfaced back to the UI
- **Public security configuration** — published as a guest-accessible
  Experience Cloud site under Salesforce's Secure Guest User Record Access
  model: reads are scoped through a deliberately narrow `without sharing`
  Apex method (not a broad sharing rule), writes are blocked server-side
  even if someone calls the Apex method directly, and field-level security
  is enforced on every query
- **Test coverage** — `HttpCalloutMock`-based tests covering success,
  failure, and bulk scenarios, plus assertions on async job behavior

## Tech stack

Apex · Lightning Web Components · SOQL · Named Credentials & External
Credentials · Queueable Apex · Experience Cloud (LWR) · GitHub REST API

---

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
├── permissionsets/
│   └── Portfolio_Full_Access.permissionset-meta.xml
├── tabs/
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
