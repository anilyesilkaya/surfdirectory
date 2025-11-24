# SurfDir — Smart Directory Navigation for MATLAB 🏄‍♂️

`SurfDir (sd)` is a MATLAB command-window utility that supercharges your directory workflows.  
It keeps a history of visited folders, allows bookmarking frequently used paths, and provides lightning-fast jumps to your development hotspots — all without leaving MATLAB.

Think of it as **`cd` on steroids for developers.**

---

## 🚀 Features

✔️ Jump to previously visited directories  
✔️ Bookmark your most used paths  
✔️ Named shortcuts for project-critical folders  
✔️ Fuzzy search for paths  
✔️ Auto-expand relative + home paths  
✔️ Works in any MATLAB session without startup overhead

---

## 🔧 Installation

1. Clone the repository:
```bash
git clone https://github.com/ayesilkaya/surfdir-matlab.git
```
2. Add the folder to your MATLAB path:
```matlab
addpath(genpath('/path/to/surfdir-matlab'));
savepath;
```
