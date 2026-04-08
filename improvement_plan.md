# SurfDirectory API Improvement Plan

## Problems with the Current API

### 1. The most common operations require too many keystrokes

Back/forward navigation is the bread-and-butter of a directory surfer, yet it's three words:

```matlab
sd go back          % 10 chars
sd go fwd           % 9 chars
sd book go myproj   % 17 chars to jump to a bookmark
sd files open conf  % 18 chars to open a file
```

### 2. `go` is overloaded across three different contexts

| Command | What `go` means |
|---------|-----------------|
| `sd go back` | "navigate" (go is the category) |
| `sd book go <name>` | "jump to" (go is an action inside `book`) |
| `sd hist go <index>` | "jump to" (go is an action inside `hist`) |

The same word serves as both a top-level namespace and a subcommand verb.

### 3. No defaults — every command requires an explicit subcommand

`sd book` does nothing useful (falls through). You must always say `sd book show`. In most CLI tools, invoking a category with no action shows its contents (e.g., `git stash` lists stashes).

### 4. `$add` is non-standard syntax

The `$` prefix isn't idiomatic MATLAB. It's not discoverable — a user reading `sd book add` would never guess `sd book $add` exists. It also hardcodes `matlabroot` as the only relative base.

### 5. Asymmetries between modules

| Feature | `book` | `hist` | `files` |
|---------|--------|--------|---------|
| `export` | yes | no | yes |
| `load` | yes | no | yes |
| `go`/`open` | `go <name>` | `go <index>` | `open <alias>` |
| `add` signature | `add <name>` (1 arg, implicit target) | n/a | `add <file> <alias>` (2 args, explicit target) |

The verb to "use" a stored reference is `go` for bookmarks, `go` for history, but `open` for files.

### 6. `files add` only works for files in current directory

```matlab
% This works:
sd files add myfile.m config

% This doesn't — no way to add a file by full path:
sd files add C:\path\to\myfile.m config
```

### 7. No search or filtering

With history capped at 1000 entries, `sd hist show` dumps everything. There's no way to search bookmarks by name pattern either.

---

## Proposed Changes

### Tier 1 — Reduce keystrokes for common operations (high impact, low risk)

#### A. Promote `back`/`fwd` to top-level commands

```matlab
sd back       % same as sd go back (also: sd b)
sd fwd        % same as sd go fwd  (also: sd f)
sd -          % alias for sd back (shell convention)
```

Keep `sd go back`/`sd go fwd` as aliases. Implementation: add these as additional cases in the `nargin == 1` branch.

**Ambiguity with folder names:** If a folder called `back` or `fwd` exists in the current directory, bare keywords (`back`, `fwd`, `b`, `f`) still mean history navigation. To `cd` into a folder with a reserved name, use a trailing slash: `sd back/`. The `sd -` shortcut is always unambiguous since `-` cannot be a valid folder name. The dispatcher rule: if the argument has a path separator (`/` or `\`) or ends with `/`, treat it as a directory path; otherwise check against reserved navigation keywords first.

#### B. Default to `show` when no subcommand is given

```matlab
sd book       % equivalent to sd book show
sd hist       % equivalent to sd hist show
sd files      % equivalent to sd files show
```

Implementation: in each `nargin == 1` branch, check if the single argument matches a module name and dispatch to its `show` handler.

#### C. Implicit `go` / `open` — use an entity name directly

```matlab
sd book myproj      % equivalent to sd book go myproj
sd hist 5           % equivalent to sd hist go 5
sd files conf       % equivalent to sd files open conf
```

Logic: if the second argument to `book`/`hist`/`files` is not a recognized subcommand (`show`, `add`, `$add`, `remove`, `clear`, `export`, `load`, `go`, `open`), treat it as a name/index to navigate to. Reserved subcommand names can't be used as bookmark/alias names — this is standard practice (git has the same constraint).

This eliminates the need for `go` as a subcommand everywhere, while keeping it as an optional explicit form for clarity.

### Tier 2 — Consistency improvements (medium impact)

#### D. Unify the "jump to" verb

After Tier 1, `go` becomes optional everywhere. But for the explicit form, standardize on one verb across all modules:

```matlab
% All three mean "take me to the thing":
sd book go myproj       % keep (already exists)
sd hist go 5            % keep (already exists)
sd files go conf        % new alias for 'open' when used with sd files
```

`open` remains as an alias for files since it's more descriptive for that context, but `go` works everywhere.

#### E. Replace `$add` with a `--rel` flag (or `rel` keyword)

```matlab
% Current (keep for backward compat):
sd book $add myproj
sd files $add myfile.m conf

% New (more discoverable):
sd book add myproj --rel
sd files add myfile.m conf --rel
```

In MATLAB's command syntax, `--rel` arrives as the string `"--rel"`. Parse it as an option. This is more discoverable and could later support other relative bases (`--rel=userpath`).

#### F. Add `rm` as alias for `remove`

```matlab
sd book rm myproj     % same as sd book remove myproj
sd files rm conf      % same as sd files remove conf
```

Minor convenience, but matches shell conventions users already know.

#### G. Add `export`/`load` to history for symmetry

```matlab
sd hist export        % save history to history.mat
sd hist load          % load history from history.mat
```

### Tier 3 — Capability improvements (lower priority)

#### H. Allow `files add` with a full path

```matlab
sd files add C:\path\to\file.m conf     % works with absolute path
sd files add ../other/file.m conf       % works with relative path
```

Currently the code does `exist(varargin{3}, "file") == 2` then prepends `pwd`. Instead, check if the argument is already an absolute path or resolve it relative to pwd.

#### I. Optional alias defaults to filename stem

```matlab
sd files add myfile.m           % alias defaults to "myfile"
sd files add myfile.m custom    % alias explicitly set to "custom"
```

Reduces the mandatory argument count from 4 to 3 for the common case.

#### J. Search/filter for history and bookmarks

```matlab
sd hist find <pattern>          % filter history entries by pattern
sd book find <pattern>          % filter bookmarks by name pattern
```

Especially important as history grows toward the 1000-entry cap.

---

## New API Surface (complete reference)

```
sd                          help
sd <folder>                 change directory
sd back | sd b | sd -       go back in history
sd fwd  | sd f              go forward in history

sd book                     show bookmarks
sd book <name>              jump to bookmark
sd book add <name> [--rel]  add bookmark
sd book rm <name>           remove bookmark
sd book export              export to .mat
sd book load                load from .mat
sd book clear               clear all
sd book find <pattern>      search bookmarks

sd hist                     show history
sd hist <index>             jump to history entry
sd hist clear               clear history
sd hist export              export to .mat
sd hist load                load from .mat
sd hist find <pattern>      search history

sd files                    show file shortcuts
sd files <alias>            open file in editor
sd files add <file> [alias] [--rel]   add file shortcut
sd files rm <alias>         remove shortcut
sd files export             export to .mat
sd files load               load from .mat
sd files clear              clear all
```

All existing commands (`sd go back`, `sd book go <name>`, `sd book $add`, `sd book remove`, etc.) remain as aliases so nothing breaks.

---

## Implementation Approach

The `nargin`-based if/elseif chain in `sd.m` is already near its complexity limit. To support these changes cleanly:

1. Refactor the dispatcher in `sd.m` to first resolve aliases (e.g., `sd back` -> `sd go back`, `sd book` -> `sd book show`, detect implicit go/open), then dispatch on the normalized form. This keeps the core logic unchanged while the alias layer handles ergonomics.

2. Update `updateFunctionSignatures.m` to add the new command shapes to the `mutuallyExclusiveGroup` for tab-completion.

3. Update the `helpText()` function to show the short forms prominently and the long forms as alternatives.
