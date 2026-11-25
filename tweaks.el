;;; tweaks.el --- Various tweaks                    -*- lexical-binding: t; -*-

;; Copyright (C) 2020 - 2026 Rostislav Svoboda

;; Authors: Rostislav Svoboda <Rostislav.Svoboda@gmail.com>
;; Version: 0.1
;; Package-Requires: ((emacs "28.1") (copy-sexp "0.1") (drag-stuff "0.1") (jump-last "0.1") (kill-buffers "0.1"))
;; Keywords: convenience
;; URL: https://github.com/Bost/tweaks

;;; Commentary:
;; Various tweaks.

;;; Installation:
;; In `dotspacemacs/user-config' add:
;;   (use-package tweaks)
;; In `dotspacemacs-additional-packages' add:
;;   (tweaks :location
;;           (recipe :fetcher github :repo "Bost/tweaks"))
;; or after cloning repo:
;;   (tweaks :location "<path/to/the/cloned-repo>")

;;; Code:

;; Load the companion packages used by the Spacemacs configuration.
(require 'drag-stuff)
(require 'jump-last)
(require 'kill-buffers)

;; Also find the modules when this file is loaded by absolute path.
(let ((load-path (cons (file-name-directory (or load-file-name buffer-file-name))
                       load-path)))
  (require 'tweaks-editing)
  (require 'tweaks-core)
  (require 'tweaks-lisp)
  (require 'tweaks-org)
  (require 'tweaks-windows))

(provide 'tweaks)

;;; tweaks.el ends here
