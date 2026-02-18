# SurfDirectory (sd)

> Enhanced `cd` for MATLAB with history, bookmarks, and file shortcuts.

SurfDirectory (`sd`) is a lightweight MATLAB utility that extends the built-in `cd` command with:

- 🔁 Navigation history (back / forward)  
- 🔖 Persistent bookmarks  
- 📂 File shortcuts  
- 💾 Preference-based storage (no external config required)  
- 📦 MATLAB function tab-completion support  

---

## ✨ Features

### 📁 Directory Navigation

```matlab
sd <folder>
```

Change directory and automatically log the visit in history.

---

### 🔄 Quick Navigation

```matlab
sd go matlabroot
sd go root
sd go back      % or: sd go b
sd go fwd       % or: sd go f
```

- Jump to `matlabroot`  
- Navigate backward / forward through visited folders  

---

### 🔖 Bookmarks

Bookmarks are stored persistently using MATLAB preferences.

#### Show bookmarks

```matlab
sd book show
```

#### Add bookmark (absolute path)

```matlab
sd book add <name>
```

#### Add bookmark (relative to matlabroot)

```matlab
sd book $add <name>
```

Relative bookmarks use a reserved token:

```
<$matlabroot$>
```

This makes them portable across MATLAB installations.

#### Jump to bookmark

```matlab
sd book go <name>
```

#### Remove bookmark

```matlab
sd book remove <name>
```

#### Export / Load

```matlab
sd book export
sd book load
```

#### Clear bookmarks

```matlab
sd book clear
```

---

### 📜 History

#### Show history

```matlab
sd hist show
```

Displays a table containing:

- item index  
- destination  
- source  
- last accessed timestamp  

#### Jump to history entry

```matlab
sd hist go <index>
```

#### Clear history

```matlab
sd hist clear
```

---

### 📂 File Shortcuts

Store frequently accessed files in the current directory.

#### Show files

```matlab
sd files show
```

#### Add file (absolute path)

```matlab
sd files add <filename>
```

#### Add file (relative to matlabroot)

```matlab
sd files $add <filename>
```

#### Open file

```matlab
sd files open <index>
```

#### Remove file

```matlab
sd files remove <index>
```

---

## 💾 Storage Model

SurfDirectory stores:

- bookmarks  
- history  
- file entries  

inside MATLAB preferences under:

```
Group: "surfdirectory"
```

No external configuration files are required (unless exporting bookmarks manually).

---

## 🧠 How It Works

- Every directory jump logs:
  - source  
  - destination  
  - timestamp  
- A cursor tracks the current history position.  
- Relative paths are resolved dynamically using:

```matlab
<$matlabroot$>
```

This prevents collisions with user-defined bookmarks.

---

## 📦 Installation

1. Place `sd.m` somewhere on your MATLAB path.  
2. (Optional) Run:

```matlab
updateFunctionSignatures
```

to enable improved tab completion.

---

## 🛠 Version

Current version:

```
v0.1
```

---

## 🚀 Future Ideas

- Recent files auto-detection  
- Bookmark grouping  
- JSON export instead of MAT file  
- Cross-machine sync  
- GUI dashboard  

---

## 📄 License

MIT License
Copyright (c) 2026 Anil Yesilkaya
