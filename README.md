# tweaks.el

Emacs utilities for Evil/Spacemacs, Clojure/CIDER, and Scheme development.

## Installation

### Spacemacs
```elisp
;; In dotspacemacs/user-config add:
(use-package tweaks
  :location (recipe :fetcher github :repo "Bost/tweaks"))

;; In dotspacemacs-additional-packages add:
(tweaks :location (recipe :fetcher github :repo "Bost/tweaks"))
```

### Vanilla Emacs
```elisp
(load "~/.emacs.d/tweaks/tweaks.el")  ; adjust to the cloned repo
```

## Libraries

Loading `tweaks` loads all five libraries. To load just one, add the clone to
`load-path` and require the feature you want.

| Feature          | Commands and helpers                                           |
|------------------|----------------------------------------------------------------|
| `tweaks-core`    | General utilities, Dired, Magit, shell and environment helpers |
| `tweaks-editing` | Text editing, clipboard, selections, and Evil search           |
| `tweaks-lisp`    | Lisp editing, Clojure/CIDER, and Scheme highlighting           |
| `tweaks-org`     | Org presentations and Babel                                    |
| `tweaks-windows` | Windows, buffers, frames, and themes                           |

`tweaks-lisp` loads `tweaks-editing` for shared insertion helpers.

## Key Functions

### CIDER/Clojure
- `tw-cider-save-and-load-current-buffer` - Save and load file into REPL
- `tw-cider-figwheel-repl` - Start Figwheel in CIDER
- `tw-clj-insert-*` - Insert common forms (let, fn, defn, etc.)
- `tw-clj-toggle-reader-comment-*` - Toggle reader comments

### Text & Navigation
- `tw-escape-quotes` / `tw-unescape-quotes` - Handle quote escaping
- `tw-search-region-or-symbol` - Project-wide search
- `tw-evil-select-pasted` - Select recently pasted text
- `tw-select-in-*` - Select text within delimiters

### Window Management
- `tw-window-toggle-layout` - Toggle vertical/horizontal layouts
- `tw-delete-window` - Smart window deletion
- `tw-zoom-all-frames-*` - Zoom all frames in/out

### Utilities
- `tw-search-or-browse` - Web search with Firefox
- `tw-shenanigans-on/off` - Toggle features for performance
- `tw-revert-buffer-no-confirm` - Revert without confirmation

## Notes

* Some CIDER functions load dynamically (byte-compile warnings expected)
* Scheme highlighting requires `(add-hook 'scheme-mode-hook 'tw-scheme-additional-keywords)`

## License
GPLv3+, Copyright (C) 2020 - 2025 Rostislav Svoboda
