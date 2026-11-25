;;; tweaks-windows.el --- Window, frame, and buffer commands  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 - 2026 Rostislav Svoboda

;;; Commentary:
;; Window, frame, and buffer commands.

;;; Code:

(require 'cl-lib)
(require 'evil)
;;; TODO byte-compilation warnings (? bc autoloading / lazy loading ? ):
;;; the function ‘zoom-all-frames-out’ is not known to be defined.
;;; the function ‘zoom-all-frames-in’ is not known to be defined.
;;;
;;; TODO this doesn't work. Is it bc #'zoom-all-frames-in is autoloaded?
;;; (unless (functionp #'zoom-all-frames-in)
;;;   (require 'zoom-frm))
(require 'zoom-frm) ;; zoom-all-frames-in, zoom-all-frames-out

(defun tw-load-layout ()
  (interactive)
  (persp-load-state-from-file (concat sp-layouts-dir "/persp-auto-save")))

(defun tw-other-window ()
  "Straight jump to the next window: SPC 0, SPC 1, etc."
  (interactive)
  (other-window 1)
  ;; (tw-flash-active-buffer)
  (beacon-blink))

(defun tw-split-other-window-and (f)
  (funcall f)
  (recenter-top-bottom))

(defun tw-split-other-window-below ()
  (interactive)
  (tw-split-other-window-and #'split-window-below))

(defun tw-split-window-right-and-focus (&optional size)
  (interactive)
  (ignore size)
  ;; (split-window-right-and-focus)
  (tw-split-other-window-and #'split-window-right-and-focus)
  ;; (tw-split-other-window-and #'split-window-right)
  )

(defun tw-ediff-buffers-left-right (&optional arg)
  "ediff buffers in the left and right panel"
  (interactive "p")
  (ignore arg)
  ;; make the current buffer to be the lef buffer thus prevent ediff swapping
  ;; left and right buffers; `windmove-left' signals an error if no window is at
  ;; the desired location(, unless <not my case>)
  (condition-case nil
      (windmove-left)
    (error nil))
  (ediff-buffers (buffer-name) ;; current buffer is the buffer-a
                 (buffer-name (other-window 1))))

(defun tw-zoom-all-frames (zoom-function)
  (unless (functionp zoom-function)
    (require 'zoom-frm))
  (funcall zoom-function)
  (message "%s" zoom-function))

(defun tw-zoom-all-frames-in ()
  (interactive)
  (tw-zoom-all-frames #'zoom-all-frames-in))

(defun tw-zoom-all-frames-out ()
  (interactive)
  (tw-zoom-all-frames #'zoom-all-frames-out))

(defun tw-switch-to-previous-buffer ()
  "Switch to previously open buffer.
Repeated invocations toggle between the two most recently open buffers."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) 1)))

(defun tw-flash-active-buffer ()
  "Blip background color of the active buffer."
  (interactive)
  (run-at-time "200 millisec" nil
               (lambda (remap-cookie)
                 (face-remap-remove-relative remap-cookie))
               (face-remap-add-relative
                ;; 'hl-line ;; doesn't work on the "@@-lines" in magit buffers
                'default
                'flash-active-buffer-face)))

(defun tw-delete-window ()
  (interactive)
  (delete-window)
  ;; (if (funcall (-compose (-partial #'equal 1)
  ;;                        #'length
  ;;                        (-lambda (buffers)
  ;;                          (cl-remove-duplicates buffers :test #'eq))
  ;;                        (-partial #'mapcar #'window-buffer))
  ;;              (window-list nil 'no-minibuf))
  ;;     (spacemacs/alternate-buffer)
  ;;   (delete-window))
  )

(defun tw-delete-other-windows ()
  (interactive)
  ;; See definitions of `treemacs'
  (pcase (treemacs-current-visibility)
    ('visible (delete-window (treemacs-get-local-window)))
    ;; ('exists  (treemacs-select-window))
    ;; ('none    (treemacs--init))
    )
  (delete-other-windows))

;; (defun matches-a-buffer-name? (name)
;;   "Return non-nil if NAME matches the name of an existing buffer."
;;   (try-completion name (mapcar #'buffer-name (buffer-list))))

(defun tw-buffer-exists-p (bufname)
  ;; See also: (lambda (window) (buffer-name (window-buffer window)))
  ;; (and ... t) turns the returned value to 't' or 'nil'
  (and (member bufname (mapcar #'buffer-name (buffer-list)))
       t))

(defun tw-toggle-shell-pop-some-term (term-type &optional ARG)
  "TERM-TYPE is \\='term\\=' or \\='multiterm\\='.
 ARG is used in `spacemacs/shell-pop-multiterm' and
 `spacemacs/shell-pop-term'.
Consider:
1. defining SHELL_PATH environment variable
2. setting:
  (setq shell-pop-term-shell SHELL_PATH)
  (setq multi-term-program SHELL_PATH)"
  (if (not (cl-find term-type '(multiterm term)))
      ;; (error "Unknown term-type: %s. Expecting 'term or 'multiterm" term-type)
      (message "Unknown term-type. Expecting 'term or 'multiterm")
    (let* ((index 0)
           (default-buffer
            ;; "*Default-multiterm-0*"
            (format "*Default-%s-%s*" term-type index)))
      (cond
       ;; If inside a terminal buffer then close / delete it.
       ;; 'term-mode' works apparently also for multiterm
       ((equal 'term-mode major-mode)
        (tw-delete-window))

       ;; can't use (let ...) inside cond
       ((tw-buffer-exists-p default-buffer)
        (progn
          (message "##### (tw-buffer-exists-p %s): t" default-buffer)
          ;; (display-buffer default-buffer)
          (pop-to-buffer default-buffer)))

       (t
        (message "##### else: (tw-buffer-exists-p %s): nil " default-buffer)
        ;; `spacemacs/shell-pop-term' and `spacemacs/shell-pop-multiterm'
        ;; are defined in layers/+tools/shell/packages.el
        (cond
         ((equal term-type 'multiterm) (spacemacs/shell-pop-multiterm ARG))
         ((equal term-type 'term)      (spacemacs/shell-pop-term ARG)))))
      (balance-windows-area))))

(defun tw-toggle-shell-pop-term (&optional ARG)
  (interactive)
  (tw-toggle-shell-pop-some-term 'term ARG))

(defun tw-toggle-shell-pop-multiterm (&optional ARG)
  (interactive)
  (tw-toggle-shell-pop-some-term 'multiterm ARG))

(defun tw-window-rearrange-layout (split-fn)
  "Rearrange the current window configuration using SPLIT-FN to split windows.
SPLIT-FN should be a function like `split-window-below` for vertical layouts or
`split-window-right` for horizontal layouts."
  (let ((bufs (mapcar #'window-buffer (window-list))))
    (delete-other-windows)
    (set-window-buffer (selected-window) (car bufs))
    (dolist (buf (cdr bufs))
      (funcall split-fn)
      (other-window 1)
      (set-window-buffer (selected-window) buf))
    ;; balance the window sizes
    (balance-windows)))

(defun tw-window-vertical-layout ()
  "Rearrange the current window configuration into a vertical (top-to-bottom)
layout."
  (interactive)
  (tw-window-rearrange-layout #'split-window-below))

(defun tw-horizontal-layout ()
  "Rearrange the current window configuration into a horizontal (side-by-side)
layout."
  (interactive)
  (tw-window-rearrange-layout #'split-window-right))

(defun tw-window-toggle-layout ()
  "Toggle between vertical (top-to-bottom) and horizontal (side-by-side) window
layouts. If all windows share the same left coordinate (indicating a vertical
layout), switch to horizontal. Otherwise, switch to vertical."
  (interactive)
  (let ((first-edges (window-edges (car (window-list))))
        (vertical-layout t))
    (dolist (win (window-list))
      (when (/= (nth 0 (window-edges win)) (nth 0 first-edges))
        (setq vertical-layout nil)))
    (if vertical-layout
        (tw-horizontal-layout)
      (tw-window-vertical-layout))))

(defun tw-evil-find-file-at-point-with-line-other-window ()
  "Like `evil-find-file-at-point-with-line`, but open in another window.
Supports filenames with spaces, parentheses, and optional :LINE suffix.

TODO:
/tmp/file.pdf       ; matching
/tmp/file (1).pdf   ; not matching
/tmp/file  (1).pdf  ; matching

(global-set-key (kbd \"C-c C-v\")
                #'tw-evil-find-file-at-point-with-line-other-window)"
  (interactive)
  ;; (split-window-right-and-focus)
  (popwin:popup-buffer (current-buffer)
                       ;; :noselect t
                       :width 0.5 :position 'right)
  (evil-find-file-at-point-with-line))

(defun tw-frame-color-parameters ()
  "Return all color-related frame parameters."
  (dolist (frame (frame-list))
    (dolist (param '(background-color
                     foreground-color
                     cursor-color
                     mouse-color
                     background-mode))
      (message "param %s : %s"
               param
               (frame-parameter nil param)))))

(defun tw-reset-all-faces ()
  "Completely reset all faces to Emacs defaults."
  (interactive)
  (mapc (lambda (theme)
          (ignore-errors
            (disable-theme theme)))
        (custom-available-themes))

  (dolist (face (face-list))
    (set-face-attribute face nil
                        :foreground 'unspecified
                        :background 'unspecified
                        :family     'unspecified
                        :slant      'unspecified
                        :weight     'unspecified
                        :height     'unspecified
                        :underline  'unspecified
                        :box        'unspecified
                        :inherit    'unspecified))

  (modify-all-frames-parameters
   '((background-color . "white")
     (foreground-color . "black")
     (cursor-color . "black")
     (mouse-color . "black")
     (background-mode . light)))

  (setq custom-enabled-themes nil)
  (setq frame-background-mode nil)
  (enable-theme 'user)

  (redraw-display))

(defun tw-get-current-theme-name ()
  "Get the name of the current theme as a string, or nil if none."
  (when-let* ((theme (car custom-enabled-themes)))
    (symbol-name theme)))

(defun tw-reload-current-theme ()
  (interactive)
  (let ((current-theme (car custom-enabled-themes)))
    (tw-reset-all-faces)
    ;; t - theme is safe
    (load-theme current-theme t)))

(provide 'tweaks-windows)

;;; tweaks-windows.el ends here
