# devz_notes_logseq_launcher

This repository contains a small launcher script for opening a Logseq DB graph with all Logseq state isolated inside a single document workspace.

## External dependencies

- `Logseq` AppImage: the desktop application that opens the graph.
- `logseq-cli`: used to create the graph structure before the desktop app starts.

The launcher currently expects both of these to already be installed and available at the paths used in [devz_notes_logseq_launcher.sh](/dpool/vcmain/dev/linux/devz_notes_logseq_launcher/devz_notes_logseq_launcher.sh).

## Why this exists

The goal is to keep one document's Logseq environment self-contained.

Instead of using normal user-level locations such as `~/.config`, `~/.logseq`, or other shared home-directory state, the launcher redirects Logseq state into the document's `.devz` area. That keeps:

- graph data
- application state
- preferences
- Logseq-specific metadata

separated from the rest of the machine.

## Reasoning

This approach makes the setup easier to reason about because each document can have its own Logseq state without interference from global settings or previously opened graphs. It also reduces the chance that one workspace accidentally reuses another workspace's cached preferences or startup state.

In short: one document, one isolated Logseq state tree.

## Software Development Chagne Requests
I had developed a process many years back of maintaining standalone folders to track all changes to a system or systems in one change request (CR). This change request will contain code baseline and current working code, all DB schema CRUD scripts and any other work products for tracking the CR over its lifecycle. Each CR also contains a single document which houses all notes for that specific CR. 

Up to now I have used Ecco Pro for my notes as its a single pane graph / no formatting editor that is just super fast for entering and editing information. I wanted to look at migrating to a more modern single pane editor and Logseq checks almost all the boxes; with one exception of not supporting standalone notes databases. This project aims to close this gap.

I have written this to have a dummy launcher called `cr_notes.lsdb` in the root of my CR folders and have configured a right click option to launch standalone LogSeq via the shell script in this project. I use `Actions for Nautilus` for the right click (shell extensions) in Nautilus.


## Files
*launch.json*: file to put under .vscode to allow you to debug the shell script
*devz_notes_logseq_launcher.sh*: Main script