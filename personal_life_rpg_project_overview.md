# Personal Life RPG — Project Overview and Agreed Design

**Status:** Initial concept and architecture  
**Purpose of this document:** Capture the decisions and ideas agreed so far. Proposals and unresolved details are explicitly marked; they are not requirements unless confirmed.

## 1. Project vision

Build a lightweight Android application (APK) that helps the user track personal development as a role-playing game (RPG).

The user has one character with multiple branches of development. The application records activities and their metrics; an AI agent interprets the recorded history and provides simple, spontaneous, balanced feedback. The agent can recognize progress, award rewards such as badges and levels, and suggest new quests when the user has not assigned any.

The experience should feel natural to the user. The system should not impose a complete set of branches, activities, progression rules, or reward mechanics before the user has defined them through use.

## 2. Design principles

- **Low friction:** Opening the app, recording an activity, and saving the information should take only a few interactions.
- **User-defined structure:** The user can create branches, activities within branches, and fields/parameters for activities.
- **Flexible by design:** The application should not require every possible branch or activity to be defined in advance.
- **Evidence-based progression:** Feedback should use recorded metrics and their history, not unsupported assumptions.
- **Simple AI interaction:** The agent should provide concise, spontaneous, balanced feedback.
- **Iterative discovery:** Begin with an empty repository and let the first elements be created from the application. Learn what is needed through real use.
- **Suggestions are not decisions:** Assistant proposals must remain proposals until the user confirms them.

## 3. Main application structure

### 3.1 Branches

The user expects approximately three or four top-level branches. Possible examples mentioned so far are:

- Physical Development / body training
- Professional skills
- Personal skills
- Family relationships

These are examples under consideration, not a finalized branch list. The structure should allow the user to add branches later.

### 3.2 Activities

Each branch can contain activities. Activities are created by the user from the application.

Examples discussed to illustrate the concept:

- Push-ups, where a record could contain a repetition count.
- Running, where a record could contain duration (and potentially other user-defined measurements).

These are examples only. No initial activity catalogue is required.

### 3.3 Configurable activity fields

Each activity can define its own parameters/fields, appropriate to what the user wants to measure. The data-entry UI should adapt to those definitions rather than requiring a separately hardcoded screen for every activity.

The exact field types, validation rules, optional metadata, and versioning behavior have not yet been specified.

### 3.4 Recorded entries and history

When the user performs an activity, the app should make recording the result quick and simple. Records must persist and retain enough context to identify the activity and its parent branch.

History is needed so the AI agent can compare performance over time. For example, an increase from three push-ups in an earlier period to ten now is traceable progress.

The exact record schema and history presentation remain to be defined.

## 4. Navigation and UI

The intended interaction model is:

- **Horizontal swipe:** Move between branches.
- **Vertical swipe:** Move between elements belonging to the current branch.
- **Home button:** Located in the upper-right area.
- **Configuration area:** Accessible from Home.

The configuration area should allow the user to:

1. Add branches.
2. Add activities to branches.
3. Add or configure fields/parameters for activities.

The primary recording experience should require only a couple of interactions where practical. Detailed visual design has not yet been defined.

## 5. AI agent responsibilities

The AI agent is intended to be simple to interact with and to provide spontaneous, balanced feedback based on the user's actual metrics.

Intended responsibilities discussed so far:

- Analyze activity measurements and history.
- Identify traceable progress.
- Provide feedback about that progress.
- Award or recommend badges, including possible streak and improvement badges.
- Manage or award levels as the progression model is defined.
- Offer new quests when the user has not assigned new ones.

The exact meaning of “trained agent,” the model choice, whether rewards are automatically applied or proposed, quest-generation rules, progression formulas, and safety boundaries are unresolved. They should not be treated as settled design decisions.

The agent should be able to work with activities created later, using their definitions and recorded data, rather than requiring a custom implementation for every activity.

## 6. Persistence and GitHub-based workflow

The current proposal is to use JSON files in a GitHub repository as a lightweight persistence mechanism rather than introducing a conventional database server at the outset. This fits the project's very small expected initial scale, but practical repository and API limits still apply.

### 6.1 Creation workflow

For a new activity (and any corresponding structure the design requires):

1. The app triggers a GitHub Actions workflow through an endpoint/API call.
2. The workflow runs an audit script to check whether the relevant structure already exists.
3. If it exists, creation is rejected and a result/message is recorded.
4. If it does not exist, another script creates the structure and persists it in the repository.

The initial concept described a separate table for each activity. Because storage is proposed to use JSON files rather than a database engine, the exact mapping between “table” and JSON file/object is not yet finalized. Preserve the user's intent—independent activity structure and inherited branch context—while validating the storage design before implementation.

### 6.2 Asynchronous result retrieval

The endpoint that triggers the workflow does **not** return the final operation result directly to the app.

Instead:

1. The app triggers the workflow.
2. It waits briefly.
3. It queries the repository through a separate endpoint to check the result.

A robust implementation should distinguish pending, succeeded, rejected, and failed outcomes so that an early check is not mistaken for a failed operation. The precise status-file or response format has not yet been selected.

### 6.3 Engineering considerations to resolve during implementation

These are implementation concerns, not changes to the agreed concept:

- Protect repository write credentials; do not embed privileged secrets in the APK.
- Handle simultaneous creation requests to avoid duplicate structures.
- Decide how personal metric data is protected. A private repository and careful consideration of Git history are important if sensitive data is stored there.
- Consider API limits and the overhead of frequent commits as usage grows.
- Define how the app confirms that the result it reads corresponds to the operation it initiated.

## 7. Initial validation strategy

The preferred first test is to start with an **empty repository of user-defined branches, activities, and records**, while the APK already contains the generic logic needed to create and manage them.

The first end-to-end test should create the initial elements from within the application, rather than seeding examples manually.

Suggested validation sequence:

1. Create the first branch in the APK.
2. Confirm that the creation workflow persists it.
3. Retrieve the new branch through the separate read endpoint.
4. Create an activity under that branch.
5. Configure the activity's fields.
6. Confirm that the activity retains its branch context.
7. Record a result.
8. Retrieve the result and verify that its history persists.

**Physical Development** has been discussed as the likely first branch to create, but the first branch and activities have not yet been explicitly finalized. No activities need to be preloaded.

## 8. Decisions and open questions

### Agreed direction

- An Android APK is the primary interface.
- The user is represented as one character with multiple development branches.
- The user can create branches, activities, and activity fields dynamically.
- Activity data is metric-based and retained over time.
- Navigation uses horizontal swipes between branches and vertical swipes between elements within a branch.
- Home is in the upper-right area, with configuration accessible from Home.
- An AI agent analyzes metrics and supports feedback, rewards, levels, and quests.
- GitHub Actions and JSON files are the proposed lightweight persistence approach.
- The workflow is asynchronous; the app retrieves its result through a separate endpoint.
- The initial repository should be empty of user-defined elements so creation can be tested from the app.
- Suggestions are not requirements until the user confirms them.

### Still open

- Final branch names and branch count.
- Initial activities and their fields.
- Exact JSON schema and whether each activity maps to its own file or another structure.
- The meaning and implementation of “table” in the JSON-based approach.
- Exact endpoints, authentication, operation IDs, and workflow status format.
- Metric validation and activity-field types.
- How branch context is inherited and represented.
- AI model/agent architecture and what “trained” means in practice.
- Reward, badge, streak, level, and quest rules.
- Whether the agent directly grants rewards or suggests them.
- Whether data is stored only in GitHub or can later be moved to another storage backend.
- Detailed visual design and accessibility behavior.

## 9. Working agreement for future design

The project should be developed collaboratively and incrementally:

1. The user explains the intended experience and architecture.
2. The assistant may suggest alternatives, risks, and improvements.
3. Suggestions must be clearly distinguished from decisions.
4. Gaps should remain open when the user has not decided; do not fill them with assumptions.
5. Implement the flexible mechanism first, then discover the content through real use.
6. Prefer validation with a small end-to-end flow over premature expansion.

The goal is not to design every aspect of the user's life in advance. It is to build a flexible system that can evolve as the user creates and uses it.
