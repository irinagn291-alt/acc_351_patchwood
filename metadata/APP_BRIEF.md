<!-- gf-brief source=6da330d1f58f66301733ff400d5eae0e22d7b5355765287ad2934ebcc6292485 written=2026-11-14T16:06:32+03:00 -->
# Patchwood

## What it is

Patchwood is a Python learning app organized as a forest field course with 100 levels across 16 stations. It is for people practicing Python by reading examples, predicting output, filling gaps and assembling lines of code.

## Launch and onboarding

There is no separate onboarding flow. On a fresh launch, the app opens directly to “Basecamp”:

1. The header shows “Patchwood” and “0 XP”. The page is headed “PYTHON FIELD COURSE · 100 LEVELS” and “Basecamp”.
2. The featured card says “ON AIR WITH PIP”, “UP NEXT · LEVEL 1”, “First transmission” and “Printing text · 3 challenges”. Tapping it opens the mission briefing.
3. Under “Your trail”, “View map” opens “Trail map”. The first route, “Pinewood Station”, lists its missions; only “First transmission” is initially available.
4. The bottom navigation offers “Basecamp”, “Trail map” and “Field log”.

The first briefing is headed “LEVEL 1 / PINEWOOD STATION” and “First transmission”. It says: “The radio is quiet. Give Pip a voice! In Python, print() sends a value to the output. Put a message in quotes so Python reads it as text.” A “PYTHON” example shows `print("Pip online")`, followed by “PIP · FIELD RADIO” and “Pip here. Let's get this radio talking.” “Start challenges” begins the three challenges.

## Screens

### “Basecamp”

The header shows the current XP total. The featured mission card opens the current mission, resumes it if work is saved, or offers the first mission for replay after all 100 levels are complete. Its status changes between “UP NEXT”, “CONTINUE” and “REPLAY”; the accompanying banner changes between “ON AIR WITH PIP” and “PRACTICE CHANNEL”.

“Your trail” shows the featured mission’s route, its completion count and its mission rows. An available or completed mission row opens that mission; completed missions can be replayed. Locked rows cannot be opened. “View map” opens “Trail map” with that route expanded.

The bottom controls “Basecamp”, “Trail map” and “Field log” switch between the three main screens.

### “Trail map”

“Trail map” shows the number of levels complete out of 100 and “16 forest stations”. Each route card shows its name, subject, completion count and progress. Tapping a route card expands or collapses its mission list. Tapping an available or completed mission opens it; later missions are locked until preceding levels are completed.

The stations and their subjects are:

| Station | Subject |
|---|---|
| “Pinewood Station” | “Output, variables & numbers” |
| “Switchback Ridge” | “Decisions, loops & lists” |
| “Summit Relay” | “Functions, returns & a final relay” |
| “Granite Works” | “Integer math & measurement” |
| “Letterpress Grove” | “Working with strings” |
| “Willow Depot” | “Lists & trail inventory” |
| “Atlas Hollow” | “Dictionaries & lookups” |
| “Compass Crossing” | “Boolean logic & decisions” |
| “Timber Loop” | “Iteration & loop control” |
| “Lantern Workshop” | “Comprehensions & sets” |
| “Parcel Junction” | “Function arguments & results” |
| “Paper Mill” | “Parsing & formatting text” |
| “Sorting Bluff” | “Ordering & search” |
| “Rope Bridge” | “Queues, stacks & nested data” |
| “Signal Clinic” | “Errors, assertions & tests” |
| “Aurora Observatory” | “Algorithm missions & final relay” |

### Mission briefing and challenges

A mission opens full screen. Its close control, accessible as “Return to basecamp”, dismisses it. The briefing shows the level and station, mission title, lesson text, a “PYTHON” example and a message from “PIP · FIELD RADIO”. “Start challenges” begins the exercises.

Each mission has three challenges, with a progress indicator:

- “READ THE SIGNAL” presents a Python example and answer choices. Tap a choice, then “Check answer”.
- “PATCH THE CODE” presents a gap and answer choices. Tap a choice, then “Check answer”.
- “BUILD A LINE” presents code pieces. Tap them in order to fill “YOUR LINE”; “Undo” removes the last piece. The initial instruction is “Tap the pieces in order”.

After checking, a correct answer shows “Signal received!” and an explanation. “Continue” advances, or “Log mission” completes the final challenge. An incorrect answer shows “Let's tune that line.” and an explanation; “Try again” clears the selection for another attempt.

### Mission completion

“Mission complete!” shows the mission name, “XP EARNED” and “FIRST TRY” results. Completing a station also shows “NEW STATION PATCH” and the patch name. The message indicates whether the next mission is open, the replay was logged, or all 100 levels are complete. “Back to basecamp” closes the mission.

### “Field log”

“Field log” shows “TOTAL XP”, “DAY STREAK” and “Station patches”. Each patch card shows its name, station and either its level count or “EARNED”. The screen explains: “Earn a patch by completing every level at its station. Replaying a mission keeps your streak going.”

The patch names are “Signal Scout”, “Ridge Navigator”, “Relay Keeper”, “Granite Surveyor”, “Type Setter”, “Cache Steward”, “Atlas Keeper”, “Compass Scout”, “Loop Ranger”, “Lantern Maker”, “Parcel Engineer”, “Paper Cartographer”, “Bluff Surveyor”, “Bridge Builder”, “Signal Medic” and “Aurora Operator”.

## Features

- A “Python field course” with 100 levels and 16 forest stations.
- Mission briefings, worked Python examples and messages from Pip.
- “Read the signal”, “Patch the code” and “Build a line” challenges with answer explanations.
- Sequential mission unlocking and replay of completed missions.
- “XP”, “Day streak”, first-try results and station patches.
- A “Trail map” and “Field log” for viewing progress.

## Behaviours that can look like bugs

- Locked missions cannot be opened. Complete the current mission to unlock the next one. A locked station says “Complete the previous route to enter.”
- “Check answer” is disabled until at least one answer or code piece is selected.
- “Undo” is disabled when “YOUR LINE” is empty and after an answer has been checked. Selected pieces cannot be selected a second time in the same attempt.
- An incorrect answer does not advance the mission. Tap “Try again”, choose a new answer and check it.
- A completed mission can be replayed, but replay awards “+0” “XP EARNED”. It can still keep the day streak going.
- Before any completion, “Field log” shows zero XP, a zero-day streak and unearned patches. Complete levels to increase the totals and complete every level at a station to earn its patch.
- After all 100 levels, the featured card offers “REPLAY” and opens the first mission.

## Starter content and resume

The course content is built in: a fresh installation starts with “First transmission” available and the remaining missions locked. There is no pre-completed progress.

An unfinished mission resumes at its saved challenge, including the current selection and checked state. Completed missions remain available for replay.

## Permissions

None.

## Absent

Login or accounts, in-app purchase, ads, analytics, user-generated content, an account deletion flow and an App Tracking Transparency prompt are absent.

## Data and support

Progress, XP, streak days and unfinished mission state stay on this device. There is no on-screen Contact or Support control.

## Scanning and health

None. The app does not scan barcodes or QR codes and does not present health, medical or product-health information.

## Platform

The interface and course are in English, with no region-specific behaviour shown. iPhone supports portrait orientation; iPad supports portrait, upside-down portrait and both landscape orientations. The app supports iPhone and iPad and requires iOS 17.0 or later.

## Category

Education.
