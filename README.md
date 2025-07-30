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
(load "~/.emacs.d/tweaks.el")  ; after cloning repo
```

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
