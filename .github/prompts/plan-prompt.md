---
mode: "edit"
description: "Plan an implementation"
---

Your goal is to generate an implementation plan for a specification document provided to you.

RULES:

- Keep implementations simple, do not over architect
- Do not generate real code for your plan, pseudocode is OK
- For each step in your plan, include the objective of the step, the steps to achieve that objective, and an AI Prompt.
- Call out any necessary user intervention required for each step
- Consider accessibility part of each step and not a separate step
- Ask clarifying questions
- The AI prompt should include:
- - Exact requirements and technical specifications
- - Integration points with existing code
- - Accessibility considerations
- - File locations and naming conventions
- - Methods and architectural patterns to follow

FIRST:

- Ask clarifying questions. Help me discover things I have not thought of.
- Review #file:../project-overview.md to understand the project.

THEN:

- Create a detailed implementation plan that outlines the steps needed to create the feature.
- The plan should be structured, clear and easy to follow.
- Structure the plan as follows. Add an AI Prompt that is output as a Markdown code block:

```
## Phase 1: Core Multiplayer Infrastructure

### Task 1.1 GameCenter Integration Setup

**AI Prompt:**

```

Set up GameCenter integration for the BlockBomb iOS game to support turn-based multiplayer:

Requirements:

- Add GameKit framework to the project
- Create `GameCenterManager.swift` in `/Features/Multiplayer/` directory
- Singleton pattern with proper GameCenter authentication

Follow the same architectural patterns as existing managers (AdManager, ReviveHeartManager).

```

```

- At the end of each prompt add a step to return to the file and mark each step of the prompt complete like this:

```
Requirements:
- [✅] Add GameKit framework to the project
- [✅] Create `GameCenterManager.swift` in `/Features/Multiplayer/` directory
- [✅] Singleton pattern with proper GameCenter authentication

```

- After each task add a step to build and run the app
- Add a step to write unit and UI tests for the feature
- Add a step to run all unit and UI tests as the last step
- At the end of the plan include an implementation order
- At the end of the plan include new file structure changes such as new directories, new UI components, configuration extensions, test coverage

NEXT:

- iterate with me until I am satisfied with the plan

FINALLY:

- Output the plan in docs/features/plan-name.md
- DO NOT start implementation without my permisssion
