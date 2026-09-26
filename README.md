# Buttershell

A native macOS terminal app built around useful splits, fast command discovery, and sessions that come back when you do. Requires macOS 26 or newer.

## Run

```sh
swift run
```

To create a launchable app bundle in `dist/`:

```sh
./scripts/package-app.sh
open dist/Buttershell.app
```

## Included

- Tabs and nested split panes with draggable dividers, pane focus, and close controls.
- A command palette with a first-run catalog of common commands and app actions. Selecting a command inserts it at the prompt; it does not run it.
- Inline zsh suggestions from the bundled starter catalog and commands available on `PATH`; right arrow accepts a suggestion. Tab keeps zsh's normal command and path completion.
- Five color themes with translucent macOS material styling.
- Workspace restore for tabs, split layout, and the last directory reported by each shell. Restored panes start fresh shells; they do not restore running programs or old terminal output.
- Shell integration lives in `~/Library/Application Support/Buttershell/Zsh`; it sources your existing zsh startup files without editing them.
- By default, exiting a shell closes its pane or tab, and exiting the last shell closes the window. Change this in the color menu.

## Shortcuts

| Action | Shortcut |
| --- | --- |
| New tab | `⌘T` |
| Close tab | `⌘W` |
| Command palette | `⌘K` |
| Split right | `⌘⇧D` |
| Split below | `⌘⇧E` |
| Focus next pane | `⌘⇧]` |
