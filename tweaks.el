;;; tweaks.el --- Various tweaks                    -*- lexical-binding: t; -*-

;; Copyright (C) 2020 - 2025 Rostislav Svoboda

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

;;; TODO byte-compilation warnings (? bc autoloading / lazy loading ? ):
;;; the function ‘cider-load-file’ is not known to be defined.
;;; the function ‘cider--infer-ports’ is not known to be defined.
;;; the function ‘cider-switch-to-repl-buffer’ is not known to be defined.
(require 'cider-repl) ;; cider-repl-tab, etc.

(require 'copy-sexp)
(require 'dired)
(require 'drag-stuff)
(require 'evil)
(require 'jump-last)
(require 'kill-buffers)
(require 'magit)
(require 'ob-core)
(require 'yasnippet)

;;; TODO byte-compilation warnings (? bc autoloading / lazy loading ? ):
;;; the function ‘zoom-all-frames-out’ is not known to be defined.
;;; the function ‘zoom-all-frames-in’ is not known to be defined.
;;;
;;; TODO this doesn't work. Is it bc #'zoom-all-frames-in is autoloaded?
;;; (unless (functionp #'zoom-all-frames-in)
;;;   (require 'zoom-frm))
(require 'zoom-frm) ;; zoom-all-frames-in, zoom-all-frames-out

(defun tw-escape-quotes (Begin End)
  "Add slash before double quote in current line or selection.
Double quote is codepoint 34.
See also: `xah-unescape-quotes'
URL `http://xahlee.info/emacs/emacs/elisp_escape_quotes.html'
Version: 2017-01-11"
  (interactive
   (if (region-active-p)
       (list (region-beginning) (region-end))
     (list (line-beginning-position) (line-end-position))))
  (save-excursion
    (save-restriction
      (narrow-to-region Begin End)
      (goto-char (point-min))
      (while (search-forward "\"" nil t)
        (replace-match "\\\"" t t)))))

(defun tw-unescape-quotes (Begin End)
  "Replace  「\\\"」 by 「\"」 in current line or selection.
See also: `xah-escape-quotes'

URL `http://xahlee.info/emacs/emacs/elisp_escape_quotes.html'
Version: 2017-01-11"
  (interactive
   (if (region-active-p)
       (list (region-beginning) (region-end))
     (list (line-beginning-position) (line-end-position))))
  (save-excursion
    (save-restriction
      (narrow-to-region Begin End)
      (goto-char (point-min))
      (while (search-forward "\\\"" nil t)
        (replace-match "\"" t t)))))

(defun tw-shell-which (command)
  "Execute the `\\='which\\=' COMMAND` in the current shell."
  (funcall
   (-compose
    ;; TODO implement fallback to bash if fish not found
    #'string-trim-right
    #'shell-command-to-string
    (lambda (strings) (string-join strings " "))
    (-partial #'list "which"))
   command))

(defun tw-what-face (position)
  "Show face at POSITION."
  ;; see also C-u C-x =
  (interactive "d")
  ;; (clojure-mode)
  (let ((face (or (get-char-property (point) 'read-face-name)
                  (get-char-property (point) 'face))))
    (if face (message "Face: %s" face) (message "No face at %d" position))))

;;; hlt-highlight-region needs (require 'highlight), otherwise it throws an
;;; error: "hlt-highlight-region undefined".
;; (defun tw-hilight-duplicate-lines ()
;;   (interactive)
;;   (let ((count 0)
;;         line-re)
;;     (save-excursion
;;       (goto-char (point-min))
;;       (while (not (eobp))
;;         (setq count 0
;;               line-re (concat "^" (regexp-quote
;;                                    (buffer-substring-no-properties
;;                                     (line-beginning-position)
;;                                     (line-end-position)))
;;                               "$"))
;;         (save-excursion
;;           (goto-char (point-min))
;;           (while (not (eobp))
;;             (if (not (re-search-forward line-re nil t))
;;                 (goto-char (point-max))
;;               (setq count (1+ count))
;;               (unless (< count 2)
;;                 (hlt-highlight-region (line-beginning-position)
;;                                       (line-end-position)
;;                                       'font-lock-warning-face)
;;                 (forward-line 1)))))
;;         (forward-line 1)))))

(defun tw-buffer-mode (buffer-or-string)
  "Returns the major mode associated with a buffer.
Thanks to https://stackoverflow.com/a/2238589
Example: (tw-buffer-mode (current-buffer))"
  (with-current-buffer buffer-or-string
    major-mode))

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

(defun tw-evil-insert ()
  "Switch to evil insert mode."
  ;; (interactive)
  (if (not (evil-insert-state-p))
      (evil-insert 0)))

(defun tw-buffer-selection-show ()
  "Make a menu of buffers so you can manipulate buffers or the buffer list."
  (interactive)
  (bs-show nil)
  (tw-evil-insert))

(defun tw-select-inner (vi-str)
  "Select inner part of a string surrounded by bracket / quotation chars."
  (evil-normal-state)
  (execute-kbd-macro vi-str))

;; use named functions for meaningful shortcuts in the listing
;; M-x which-key-show-top-level / SPC h k
(defun tw-select-in-ang-bracket () (interactive) (tw-select-inner "vi<"))
(defun tw-select-in-sqr-bracket () (interactive) (tw-select-inner "vi["))
(defun tw-select-in-rnd-bracket () (interactive) (tw-select-inner "vi("))
(defun tw-select-in-crl-bracket () (interactive) (tw-select-inner "vi{"))
(defun tw-select-in-string () (interactive) (tw-select-inner "vi\""))

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

(defun tw-disable-y-or-n-p (orig-fun &rest args)
  (cl-letf (((symbol-function 'y-or-n-p) (lambda (_) t)))
    (apply orig-fun args)))

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

(defun tw-whitespace-mode-toggle ()
  (interactive)
  (whitespace-mode 'toggle)
  (spacemacs/toggle-fill-column-indicator))

;; Spacemacs search: SPC s
;; search only in certain file-types:
;; 1. ag --list-file-types
;; 2. search only in .el files: TextToFind -G\.el$
;; (global-set-key (kbd "<f3>") 'helm-ag)

(defun tw-search-region-or-symbol (&optional arg)
  "Search for selected text in the project. Even in visual state.
See `spacemacs/helm-project-smart-do-search-region-or-symbol'"
  (interactive "p")
  (ignore arg)
  (let (;; TODO optionaly reselect last selected text
        ;; (was-normal-state-p (evil-normal-state-p))
        (was-visual-state-p (evil-visual-state-p)))
    (if was-visual-state-p
        ;; select text as if done from the insert state
        (let ((sel-text (buffer-substring-no-properties (region-beginning)
                                                        (region-end)))
              (mark-pos (mark))
              (point-pos (point)))
          (evil-exit-visual-state) ;; (evil-exit-visual-and-repeat)
          ;; can't be executed in the let-block. WTF???
          (if (< mark-pos point-pos)
              (exchange-point-and-mark)) ;; moving back
          (set-mark (point))
          (right-char (length sel-text))))
    (spacemacs/helm-project-smart-do-search-region-or-symbol)
    ;; (message "was-visual-state-p: %s" was-visual-state-p)
    ))

(defun tw-evil-paste-after-from-0 ()
  ;; TODO evaluate: paste copied text multiple times
  (interactive)
  (let ((evil-this-register ?0))
    (call-interactively 'evil-paste-after)))

(defun tw-evil-select-pasted ()
  "See also https://emacs.stackexchange.com/a/21093"
  (interactive)
  (let ((start-marker (evil-get-marker ?\[))
        (end-marker (evil-get-marker ?\])))
    (evil-visual-select start-marker end-marker))
  ;; moves mark - not great
  ;; (evil-goto-mark ?\[)
  ;; (evil-visual-char)
  ;; (evil-goto-mark ?\])
  ;; (message "tw-evil-select-pasted - does the same as the macro under: SPC g p")
  )

(defun tw-yank-and-select ()
  (interactive)
  ;; (let ((point-begin (point)))
  ;;   (clipboard-yank)
  ;;   (yank)
  ;;   (evil-visual-make-selection)
  ;;   (evil-visual-select point-begin (- (point) 1))
  ;;   (tw-evil-select-pasted))
  (yank)
  (tw-evil-select-pasted))

(defun tw-shenanigans-on ()
  "Switch on most of the graphical goodies. Inverse of
`tw-shenanigans-off'."
  (interactive)
  ;; fontification is only deferred while there is input pending
  (setq jit-lock-defer-time 0)
  (spacemacs/toggle-line-numbers-on)
  (buffer-enable-undo)
  (font-lock-mode 1)
  (diff-hl-mode 1)
  (message "Shenanigans enabled"))

(defun tw-shenanigans-off ()
  "Switch on most of the graphical goodies. Useful when editing
large files. Inverse of `tw-shenanigans-on'."
  (interactive)
  (spacemacs/toggle-line-numbers-off)
  (buffer-disable-undo)
  (font-lock-mode -1)
  ;; fontification is not deferred.
  (setq jit-lock-defer-time nil)
  (diff-hl-mode -1)
  (message "Shenanigans disabled"))

(defun tw-insert-str (s &optional n-chars-back)
  (interactive "p")
  (insert s)
  (left-char n-chars-back)
  (tw-evil-insert))

(defun tw-insert-group-parens ()
  (interactive)
  (let* ((msg "\\(.*\\)"))
    (tw-insert-str msg 2)))

(defun tw-delete-next-sexp (&optional arg)
  "Delete the sexp (balanced expression) following point w/o
yanking it. See `kill-sexp'."
  (interactive "p")
  (ignore arg)
  (let ((beg (point)))
    (forward-sexp 1)
    (let ((end (point)))
      (delete-region beg end))))

(defun tw-delete-prev-sexp (&optional arg)
  "Delete the sexp (balanced expression) following point w/o
yanking it. See `kill-sexp'."
  (interactive "p")
  (ignore arg)
  (let ((beg (point)))
    (forward-sexp -1)
    (let ((end (point)))
      (delete-region end beg)))) ;; beg & end are swapped

(defun tw-hs-clojure-hide-namespace-and-folds ()
  "Hide the first (ns ...) expression in the file, and also all
the (^:fold ...) expressions."
  (interactive)
  (hs-life-goes-on
   (save-excursion
     (goto-char (point-min))
     (when (ignore-errors (re-search-forward "^(ns "))
       (hs-hide-block))

     (while (ignore-errors (re-search-forward "\\^:fold"))
       (hs-hide-block)
       (forward-line)))))

;; deving on clojure-mode; WARNING: (getenv "dev") is undefined
(defun load-clojure-mode (file)
  (if (load-file file)
      (if (string= major-mode "clojure-mode")
          (progn
            (clojure-mode)
            (message "File loaded & clojure-mode set: %s" file))
        (message "File loaded: %s" file))
    (message "File loading failed: %s" file)))

(defun tw-switch-to-previous-buffer ()
  "Switch to previously open buffer.
Repeated invocations toggle between the two most recently open buffers."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) 1)))

(defun tw-cider-figwheel-repl ()
  "Start figwheel"
  (interactive)
  (save-some-buffers)
  (with-current-buffer (cider-current-repl)
    (goto-char (point-max))
    (insert "(require 'figwheel-sidecar.repl-api)
;; start-figwheel can be repeatedly called (is idempotent)
(figwheel-sidecar.repl-api/start-figwheel!)
(figwheel-sidecar.repl-api/cljs-repl)")
    (cider-repl-return)
    ;; TODO (rename-buffer "*figwheel-cider*")
    (tw-evil-insert)))

(defun tw-switch-to-repl-start-figwheel ()
  "Switch to cider repl & start figwheel"
  (interactive)
  (cider-switch-to-repl-buffer)
  (tw-cider-figwheel-repl))

(defun tw-cider-switch-to-repl-buffer ()
  "Connect (if not connected yet) and switch to cider repl buffer.
TODO redefine / parameterize for the corona_cases in the
.dir-locals.el so that the `(cider-connect-clj)'
or `(cider-jack-in-clj nil)' or any other command is specified as
a parameter."
  (interactive)
  (unless (cider-connected-p)
    ;; See https://github.com/dakra/dmacs/blob/master/init.org#cider
    (let* ((host "localhost")
           (ssh-hosts `((,host))))
      ;; pattern matching
      (pcase (cider--infer-ports host ssh-hosts)
        (`((,directory ,port) . ,_)
         (if (string= "corona_cases" directory)
             (cider-connect-clj `(:host ,host :port ,port))
           (cider-connect-clj)))))
    ;; TODO wait until the repl gets started
    )
  (cider-switch-to-repl-buffer))

(defun tw-copy-to-clipboard ()
  "Copy selection to x-clipboard or clipboard."
  (interactive)
  (if (display-graphic-p)
      (progn
        (call-interactively 'clipboard-kill-ring-save)
        (message "%s %s"
                 "The DISPLAY is graphic."
                 "Region yanked to the x-clipboard!"))
    (if (region-active-p)
        (progn
          (shell-command-on-region (region-beginning)
                                   (region-end) "xsel -i -b")
          (deactivate-mark)
          (message "%s %s"
                   "The DISPLAY not is graphic."
                   "Region yanked to the clipboard!"))
      (message "%s %s"
               "The DISPLAY not is graphic and no region active."
               "Can't yank to the clipboard!"))))

(defun tw-paste-from-clipboard ()
  "Paste from the x-clipboard."
  (interactive)
  (if (display-graphic-p)
      (progn
        ;; (clipboard-yank)
        (yank)
        (message "The DISPLAY is graphic."))
    (insert (shell-command-to-string "xsel -o -b"))))

(defun tw-fabricate-subst-cmd (&optional args)
  "Place prepared subst command to the echo area. Must be declared with
`&optional args'. Otherwise it wont work.
E.g.:
     :%s#\\=\\<\\=\\>##gc     - places the point between `\<' and `\>'
     :%s#fox#fox#gc   - places the point after the first `x'"
  (interactive "p")
  (ignore args)
  (sp-copy-sexp)
  (evil-normal-state)
  (let* (;; Example 1.:
         ;; (sexp-str "%s#\\<\\>##gc")
         ;; (offset 6)
         ;;
         ;; Example 2.:
         (search-regex (format "%s" (car kill-ring)))
         (replace-regex (format "%s" (car kill-ring)))
         (sexp-str (format "%%s#\\<\\(%s\\)\\>#%s#gc" search-regex replace-regex))
         ;; 4 means: jump to the 2nd slash
         (offset (+ (length search-regex) 9)))
    ;; (cons .. offset) moves the point
    (evil-ex (cons sexp-str offset))))

(defun tw-search-namespace (&optional args)
  (interactive "p")
  (ignore args)
  (sp-copy-sexp)
  ;; (message "%s" kill-ring)
  (evil-normal-state)
  (let* ((sexp-str (format "%s\\/" (car kill-ring))))
    ;; (evil-ex-search-forward)
    ;; (insert sexp-str)
    ;; (evil-ex-search-full-pattern sexp-str 1 'forward)
    (evil-ex-start-word-search t 'forward 0 sexp-str)
    ;; (evil-ex-search-start-session)
    ;; (exit-minibuffer)
    ))

(global-set-key (kbd "<s-f9>") 'tw-search-namespace)

(defmacro tw-interactive-lambda (&rest body)
  "Thanks to https://emacs.stackexchange.com/a/10198/36619"
  (let ((x (macroexp-parse-body body)))
    `(lambda () ,@(car x) (interactive)
       ,@(cdr x))))

(defalias 'tw-il 'tw-interactive-lambda)

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

(setq tw-iedit-mode nil)
;; (defvar tw-iedit-mode nil) ;; TRY defvar

(defun tw-iedit-mode-toggle ()
  "Match only occurrences in current function and the comment right above it."
  (interactive)
  ;; TODO when C-g pressed and (= tw-iedit-mode t) then (setq tw-iedit-mode nil)
  (if tw-iedit-mode
      (progn
        (evil-iedit-state/quit-iedit-mode)
        (setq tw-iedit-mode nil))
    (progn
      ;; 0 means: only occurrences in current ...
      (evil-iedit-state/iedit-mode 0)
      ;; (evil-iedit-state/iedit-mode) ;; M-H iedit-restrict-function
      (setq tw-iedit-mode t))))

;; (defun tw-eval-current-defun1 (arg)
;;   "Doesn't work if there's a \"\" or () at the end of the function"
;;   (interactive "P")
;;   (let* ((point-pos (point)))
;;     (while (and (not (tw-is-defun))
;;                 (not (= (point) (point-min))))
;;       (sp-backward-symbol))
;;     (if t ;; (not (= point-pos (point)))
;;         (let* ((before-up (point)))
;;           (sp-up-sexp)
;;           (if (= before-up (point))
;;               (sp-forward-sexp))))
;;     ;; eval-sexp-fu-flash-mode is buggy
;;     (eval-last-sexp arg)
;;     (goto-char point-pos)))

(defun tw-eval-current-defun2 (arg)
  (interactive "P")
  (let* ((point-pos (point)))
    ;; (end-of-line)
    (search-backward (format "defun") nil t)
    (if t ;; (not (= point-pos (point)))
        (let* ((before-up (point)))
          (sp-up-sexp)
          (if (= before-up (point))
              (sp-forward-sexp))))
    (eval-last-sexp arg)
    ;; (message (format "search-backward"))
    (goto-char point-pos)))

(defun tw-eval-current-defun (arg)
  "Evaluate the current i.e. inner defun.
E.g. in the (def un a () (def un b () (def un c ()))) this
function allows selective evaluation \\='c\\=' or \\='b\\=' or
\\='a\\=' according to the point possition in contrast to
`eval-defun' which always evaluates just \\='a\\=' no matter
where the point is.
TODO still buggy - when not in a defun it evaluates preceding defun"
  (interactive "P")
  (let* ((point-pos (point)))
    (evil-insert-state nil)
    (goto-char (+ point-pos (length (concat "(def" "un"))))
    ;; separate the bracket from the string enables self-eval this function
    (search-backward (concat "(def" "un") nil t)
    (sp-forward-sexp)
    (eval-last-sexp arg)
    (goto-char point-pos)))

(defun tw-elisp-insert-message ()
  "See `lv-message' for semi-permanent hints, not interfering
with the Echo Area."
  (interactive)
  (tw-insert-str "(message \"%s\" )" 1))

(defun tw-elisp-insert-defun ()
  (interactive)
  (yas-expand-snippet (yas-lookup-snippet "defun")))

(defun tw-elisp-insert-lambda ()
  (interactive)
  ;; (yas-expand-snippet (yas-lookup-snippet "lambda"))
  (tw-insert-str "lambda " 0))

(defun tw-cider-save-and-load-current-buffer ()
  "TODO call `cider-repl-set-ns' only if `cider-load-file' succeeded"
  (interactive)
  (when (buffer-modified-p)
    (save-buffer))
  ;; Set the ns in the first step...
  (cider-repl-set-ns (cider-current-ns))
  ;; ... so if there's an error in the buffer being loaded then the repl is
  ;; ready to be used for the problem analysis.
  (cider-load-file (buffer-file-name))
  ;; (cider-switch-to-relevant-repl-buffer nil)
  )

(defun tw-cider-reload-ns-from-file ()
  "TODO get the filename from (cider-current-ns) and reload it"
  (interactive)
  (message "[%s] cider-current-ns %s"
           'tw-cider-reload-ns-from-file
           (cider-current-ns))
  ;; (tw-cider-switch-to-repl-buffer)
  ;; (tw-cider-save-and-load-current-buffer)
  )

(defun tw-clj-insert-debugd ()
  (interactive)
  (let* ((msg (if (equal major-mode 'clojurescript-mode)
                  "(.log js/console \"\")"
                "(debugf \"\")"
                ;; "(println \"\")"
                )))
    (tw-insert-str msg 2)))

(defun tw-scheme-insert-log ()
  (interactive)
  (let* ((msg "(format #t \"\\n\")"))
    (tw-insert-str msg 4)))

(defun tw-racket-insert-log ()
  (interactive)
  (tw-insert-str "(printf \"\\n\")" 4))

(defun tw-scheme-insert-let* ()
  (interactive)
  (tw-insert-str "(let* [])" 2))

(defun tw-clj-insert-remove-fn ()
  (interactive)
  (tw-insert-str "(remove (fn []))" 3))

(defun tw-clj-insert-filter-fn ()
  (interactive)
  (tw-insert-str "(filter (fn []))" 3))

(defun tw-clj-insert-type ()
  (interactive)
  (tw-insert-str "(type )" 1))

(defun tw-clj-insert-map-fn ()
  (interactive)
  (tw-insert-str "(map (fn []))" 3))

(defun tw-clj-insert-let ()
  (interactive)
  ;; (cljr-introduce-let) ; TODO see docu for cljr-introduce-let
  (tw-insert-str "(let [])" 2))

(defun tw-elisp-insert-let ()
  (interactive)
  (tw-insert-str "(let (()))" 3))

(defun tw-clj-insert-for ()
  (interactive)
  (tw-insert-str "(for [])" 2))

(defun tw-insert-clojuredocs ()
  (interactive)
  (tw-insert-str "clojuredocs"))

(defun tw-clj-insert-comp ()
  (interactive)
  (tw-insert-str "((comp ))" 2))

(defun tw-insert-partial ()
  (interactive)
  (tw-insert-str "partial " 1))

(defun tw-racket-insert-fn ()
  (interactive)
  (tw-insert-str "(lambda ())" 2))

(defun tw-clj-insert-fn ()
  (interactive)
  (tw-insert-str "(fn [])" 2))

(defun tw-clj-insert-def ()
  (interactive)
  (tw-insert-str "(def )" 1))

(defun tw-clj-insert-defn ()
  (interactive)
  (tw-insert-str "(defn [])" 3))

(defun tw-clj-insert-doseq ()
  (interactive)
  (tw-insert-str "(doseq [])" 2))

(defun tw-clj-insert-do ()
  (interactive)
  (tw-insert-str "(do)" 1))

(defun tw-point-max-p () (= (point) (point-max)))
(defalias 'tw-end-of-file-p 'tw-point-max-p)

(defun current-line-empty-p ()
  (save-excursion
    (beginning-of-line)
    (looking-at-p "[[:space:]]*$")))

;; TODO Implement using the `spacemacs/toggle'
(defun tw-toggle-reader-comment-fst-sexp-on-line (sexp-comment)
  "If line starts with a line comment, toggle the comment.
Otherwise toggle the reader comment."
  (if (and (current-line-empty-p) (tw-end-of-file-p))
      (progn
        (message "Point at the end-of-file. No toggle-comment done."))
    (let* ((point-pos1 (point)))
      ;; Switch to insert state at beginning of current line.
      ;; 0 means: don't insert any line
      (evil-insert-line 0)
      (let* ((point-pos2 (point))
             (is-comment-only (comment-only-p point-pos2
                                              (save-excursion
                                                (move-end-of-line 1)
                                                (point)))))
;;; `t' causes to always execute the then-branch, i.e. comment empty lines with
;;; sexp comment
        (if (or t (eq major-mode 'scheme-mode))
            (let* ((sexp-comment-len (length sexp-comment))
                   (line-start (buffer-substring-no-properties
                                point-pos2 (+ point-pos2 sexp-comment-len))))
              (if (string= sexp-comment line-start)
                  (progn
                    (delete-char sexp-comment-len)
                    (goto-char (- point-pos1 sexp-comment-len)))
                (progn
                  (insert sexp-comment)
                  (goto-char (+ point-pos1 sexp-comment-len)))))
          (if is-comment-only
              ;; (evilnc-comment-or-uncomment-lines 1)
              (spacemacs/comment-or-uncomment-lines 1)
            (let* ((sexp-comment-len (length sexp-comment))
                   (line-start (buffer-substring-no-properties
                                point-pos2 (+ point-pos2 sexp-comment-len))))
              (if (string= sexp-comment line-start)
                  (progn
                    (delete-char sexp-comment-len)
                    (goto-char (- point-pos1 sexp-comment-len)))
                (progn
                  (insert sexp-comment)
                  (goto-char (+ point-pos1 sexp-comment-len)))))))))))

(defun tw-racket-toggle-reader-comment-fst-sexp-on-line ()
  (interactive)
  (tw-toggle-reader-comment-fst-sexp-on-line "#;"))

(defun tw-clj-toggle-reader-comment-fst-sexp-on-line (&optional arg)
  "When invoked with prefix <C u 2> it toggles two forms - for key-value pair"
  (interactive "p")
  (tw-toggle-reader-comment-fst-sexp-on-line
   (if (eq 2 arg)
       "#_#_"
     "#_")))

(defun tw-elisp-toggle-reader-comment-current-sexp (&optional arg)
  "emacs-lisp doesn't have a syntax for sexp-comment.
TODO finish the implementation"
  (interactive "p")
  ;; (mark-sexp)
  (spacemacs/comment-or-uncomment-lines arg))

(defun tw-racket-toggle-reader-comment-current-sexp ()
  (interactive)
  (newline-and-indent)
  (tw-racket-toggle-reader-comment-fst-sexp-on-line))

(defun tw-clj-toggle-reader-comment-current-sexp ()
  (interactive)
  (newline-and-indent)
  (tw-clj-toggle-reader-comment-fst-sexp-on-line))

(defun tw-helm-mini ()
  ;; (define-key helm-map (kbd "s-a") nil)
  ;; (unbind-key (kbd "s-a") helm-map)
  (when (boundp 'helm-map)
    (define-key helm-map (kbd "s-a") 'helm-next-line)
    (define-key helm-map (kbd "s-]") 'helm-next-line)))

(defun tw-find-ai-scrbl ()
  "Edit the `$dev/notes/notes/ai.scrbl', in the current window."
  (interactive)
  (find-file-existing (format "%s/notes/notes/ai.scrbl" (getenv "dev"))))

(defun tw-find-dotf-spacemacs ()
  "Edit the Spacemacs init.el, in the current window."
  (interactive)
  (find-file-existing
   (format "%s/.emacs.d.distros/spacemacs/develop/cfg/init.el"
           (getenv "dotf"))))

(defun tw-find-dotf-spacemacs-guix ()
  "Edit the Guix version of Spacemacs init.el, in the current window."
  (interactive)
  (find-file-existing
   (format "%s/.emacs.d.distros/spacemacs/guix/cfg/init.el"
           (getenv "dotf"))))

(defun tw-find-home-config.scm ()
  "Edit the `$dotf/.../home-config-<hostname>.scm', in the current window."
  (interactive)
  (find-file-existing
   (format "%s/guix/home/home-config-%s.scm" (getenv "dotf") (system-name))))

(defun tw-find-syst-config.scm ()
  "Edit the `$dotf/.../<hostname>.scm', in the current window."
  (interactive)
  (find-file-existing
   (format "%s/guix/systems/%s.scm" (getenv "dotf") (system-name))))

(defun tw-find-spguimacs-packages.scm ()
  "Edit the `$dotf/.../spguimacs-packages.scm', in the current window."
  (interactive)
  (find-file-existing
   (format "%s/guix/home/cfg/spguimacs-packages.scm" (getenv "dotf"))))

(defun tw-cider-clear-compilation-highlights ()
  (interactive)
  (cider-clear-compilation-highlights t))

(defun tw-repl-insert-cmd (s)
  (cider-switch-to-repl-buffer)
  (insert s))

(defun tw-stop-synths-metronoms ()
  (interactive)
  (tw-repl-insert-cmd "(stop)")
  (cider-repl-return))

(defun tw-magit-status ()
  (interactive)
  (tw-save-all-buffers)
  (magit-status-setup-buffer))

(defun tw-cider-insert-and-format (form)
  (interactive)
  (tw-repl-insert-cmd (concat (mapconcat 'identity form "\n")))
  (evil-normal-state)
  (evil-jump-item)
  (dolist (_ (cdr form))
    (evil-next-visual-line)
    (cider-repl-tab))
  (evil-append-line 0))

(defun tw-cider-unmap-this-ns ()
  (interactive)
  (tw-cider-insert-and-format
   `(
     ;; "(map #(ns-unmap *ns* %) (keys (ns-interns *ns*)))"
     "(->> [*ns*]"
     "     (map (fn [nspace]"
     "              (->> (keys (ns-interns nspace))"
     "                   (map (fn [symb] (ns-unmap nspace symb)))))))"
     )))

(defun tw-cider-browse-this-ns ()
  (interactive)
  (tw-cider-insert-and-format
   `(
     "(->> [*ns*]"
     "     (map (fn [nspace]"
     "              (->> (keys (ns-interns nspace))"
     "                   ))))"
     )))

(defun tw-cider-browse-all-ns (namespace)
  "E.g.:
(tw-cider-browse-all-ns \"jim.jones\")

Evil substitute / replace command:
  \\='<,\\='>s/\(.*\)/\"\\1\"/
  "
  (interactive)
  (let* ((nspace (list (concat "\"" namespace "\""))))
    (tw-cider-insert-and-format
     `(
       "(let [ns-prefix " ,@nspace "]"
       "  (->> (all-ns)"
       "       (filter (fn [nspace] (.startsWith (str nspace) ns-prefix)))"
       "       #_(take 1)"
       "       (map (fn [nspace]"
       "                (assoc {} nspace"
       "                (->> (ns-interns nspace)"
       "                     (keys)"
       "                     #_(map (fn [symb] (ns-unmap nspace symb)))))))))"
       ))))

(defun tw-cider-unmap-all-ns (namespace)
  "Substitute / replace:
\\='<,\\='>s/\(.*\)/\"\\1\"/
"
  (interactive)
  (let* ((nspace (list (concat "\"" namespace "\""))))
    (tw-cider-insert-and-format
     `(
       "(let [ns-prefix " ,@nspace "]"
       "  (->> (all-ns)"
       "       (filter (fn [nspace] (.startsWith (str nspace) ns-prefix)))"
       "       #_(take 1)"
       "       (map (fn [nspace]"
       "                (->> (ns-interns nspace)"
       "                     (keys)"
       "                     (map (fn [symb] (ns-unmap nspace symb))))))))"
       ))))

(defun tw-save-all-buffers ()
  "Thanks to https://stackoverflow.com/a/30468232"
  (interactive)
  (save-some-buffers
   'no-confirm
   (lambda ()
     (cond
      ((and buffer-file-name (equal buffer-file-name abbrev-file-name)))
      ((and buffer-file-name (eq major-mode 'clojure-mode)))
      ((and buffer-file-name (eq major-mode 'latex-mode)))
      ((and buffer-file-name (eq major-mode 'markdown-mode)))
      ((and buffer-file-name (eq major-mode 'emacs-lisp-mode)))
      ((and buffer-file-name (derived-mode-p 'org-mode)))))))

(defun all-major-mode-variants (symb-name)
  ;; The `symbol-name' returns a string. Convert it to symbol
  (let ((s-sym (intern symb-name)))
    (if (get s-sym 'derived-mode-parent) s-sym)))

;; TODO have a look at the `fundamental-mode'
;; (setq last-edit-tracked-modes-list
;;       (append '(text-mode prog-mode)
;;               (remove nil
;;                       (mapcar (lambda (mode)
;;                                 (if (provided-mode-derived-p
;;                                      mode 'prog-mode 'text-mode)
;;                                     mode))
;;                               (remove nil
;;                                       (mapcar 'all-major-mode-variants
;;                                               (loop for x being the symbols
;;                                                     if (fboundp x)
;;                                                     collect
;;                                                     (symbol-name x))))))))

;; for all derivatives of 'prog-mode 'text-mode :
;; https://emacs.stackexchange.com/questions/21406/find-all-modes-derived-from-a-mode

;; 1. list all symbols
;; 2. check that a given symbol a mode-symbol

;; add the 'tw-save-last-edited-buffer to the hooks of the given mode

;; (dolist (mode (buffer-list))
;;   (message "%s; relevant %s"
;;            mode
;;            (if (provided-mode-derived-p (tw-buffer-major-mode mode)
;;                                         'prog-mode 'text-mode)
;;                ;; (add-hook 'after-change-functions 'feng-buffer-change-hook)
;;                (add-hook (get-hook (tw-buffer-major-mode mode))
;;                          'tw-save-last-edited-buffer))))

;; https://github.com/bbatsov/projectile/issues/442#issuecomment-59659969
;; (require 'dash)
(defun set-local-keymap (&rest bindings)
  "For project-specific keybindings"
  (dolist (binding (-partition-in-steps 2 2 bindings))
    (lexical-let* ((key (car binding))
                   (cmd (cadr binding))
                   (is-interactive (interactive-form cmd))
                   (local-map (or (current-local-map) (make-keymap))))
      (define-key local-map key
                  (lambda ()
                    (interactive)
                    (if is-interactive
                        (call-interactively cmd)
                      (eval cmd)))))))

;; From https://www.emacswiki.org/emacs/DiredOmitMode
(defun tw-dired-dotfiles-toggle ()
  "Show/hide dot-files"
  (interactive)
  (when (equal major-mode 'dired-mode)
    ;; if currently showing
    (if (or (not (boundp 'dired-dotfiles-show-p))
            (and (boundp 'dired-dotfiles-show-p) dired-dotfiles-show-p))
        (progn
          (set (make-local-variable 'dired-dotfiles-show-p) nil)
          (message "h")
          (dired-mark-files-regexp "^\\\.")
          (dired-do-kill-lines))
      (progn (revert-buffer) ; otherwise just revert to re-show
             (set (make-local-variable 'dired-dotfiles-show-p) t)))))

(defun tw-dired-do-delete ()
  (interactive)
  (let ((old-val dired-deletion-confirmer))
    ;; (message "[%s] old-val: %s" 'tw-dired-do-delete old-val)
    (setq dired-deletion-confirmer '(lambda (_) t))
    (dired-do-delete)
    (setq dired-deletion-confirmer old-val)))

(defun tw-delete-window ()
  (interactive)
  (if (funcall (-compose (-partial #'equal 1)
                         #'length
                         #'delete-dups
                         (-partial #'mapcar (-compose #'buffer-name
                                                      #'window-buffer)))
               (window-list))
      (spacemacs/alternate-buffer)
    ;; By default selected window is deleted. No need for
    ;; `(delete-window (selected-window))'
    (delete-window)))

(defun tw-delete-other-windows ()
  (interactive)
  ;; See definitions of `treemacs'
  (pcase (treemacs-current-visibility)
    ('visible (delete-window (treemacs-get-local-window)))
    ;; ('exists  (treemacs-select-window))
    ;; ('none    (treemacs--init))
    )
  (delete-other-windows))

(defun tw-ins-left-paren ()
  "Simulate key press" (interactive) (execute-kbd-macro (kbd "(")))
(defun tw-ins-right-paren ()
  "Simulate key press" (interactive) (execute-kbd-macro (kbd ")")))

;; (defun matches-a-buffer-name? (name)
;;   "Return non-nil if NAME matches the name of an existing buffer."
;;   (try-completion name (mapcar #'buffer-name (buffer-list))))

(defun buffer-exists-p (bufname)
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
       ((buffer-exists-p default-buffer)
        (progn
          (message "##### (buffer-exists-p %s): t" default-buffer)
          ;; (display-buffer default-buffer)
          (pop-to-buffer default-buffer)))

       (t
        (message "##### else: (buffer-exists-p %s): nil " default-buffer)
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

(defun tw-dired-sort ()
  "Sort dired dir listing in different ways.
Prompt for a choice.
URL `http://xahlee.info/emacs/emacs/dired_sort.html'
Version: 2018-12-23 2022-04-07"
  (interactive)
  (let (xsortBy xarg)
    (setq xsortBy (completing-read "Sort by:" '( "date" "size" "name" )))
    (cond
     ((equal xsortBy "name") (setq xarg "-Al "))
     ((equal xsortBy "date") (setq xarg "-Al -t"))
     ((equal xsortBy "size") (setq xarg "-Al -S"))
     ((equal xsortBy "dir") (setq xarg "-Al --group-directories-first"))
     (t (error "logic error 09535" )))
    (dired-sort-other xarg )))

;; It's better not to redefine or advise `revert-buffer'. There are plenty of
;; Lisp calls to revert-buffer, and you don't want to affect their behavior. You
;; probably want to change the behavior only for interactive calls.
(defun tw-revert-buffer-no-confirm ()
  "Revert buffer without confirmation."
  (interactive) (revert-buffer t t))

;; ### BEG adjust-point-pos-after-search
;; See:
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Basic-Windows.html#Window%20Group
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Coordinates-and-Windows.html

(defun tw-adjust-point-pos-before-search (&optional COUNT)
  (interactive)
  (evil-scroll-line-to-center COUNT)
  ;; (setq tw-line-before (line-number-at-pos))
  )

;; TODO very long files might overflow the number-var
(defun tw-adjust-point-pos-after-search (&optional COUNT)
  (interactive)
  (evil-scroll-line-to-center COUNT)
  ;; (let* ((bef tw-line-before)
  ;;        (aft (line-number-at-pos))
  ;;        (height (window-height))
  ;;        (diff (abs (- aft bef)))
  ;;        (scroll (> diff (- height 8)))) ; 8 is margin
  ;;   ;; (format-message "bef: %d aft: %d height: %d diff: %d center: %s"
  ;;   ;;                 bef aft height diff (> diff height))
  ;;   (message "bef: %d aft: %d diff %d scroll: %s" bef aft diff scroll)
  ;;   (if scroll
  ;;       (evil-scroll-line-to-center nil))
  ;;   )
  )

;; pos-curr
;; pos-next - position of next search result
;; (abs (- pos-next pos-curr))
;; (window-size) ;; count of lines in current window
;; (window-end)
;; (window-top-line)
;; (point)
;; if too far then G and recenter
;; (line-number-at-pos (match-beginning 0))
;; (line-number-at-pos (match-end 0))

;; ### END adjust-point-pos-after-search

(defun tw-org-babel-demarcate-block-fish (&optional arg)
  "Wrap or split the code in the region or on the point.
When called from inside of a code block the current block is
split.  When called from outside of a code block a new code block
is created.  In both cases if the region is demarcated and if the
region is not active then the point is demarcated.

When called within blank lines after a code block, create a new code
block of the same language with the previous."
  (interactive "P")
  (let* ((info (org-babel-get-src-block-info 'no-eval))
         (start (org-babel-where-is-src-block-head))
         ;; `start' will be nil when within space lines after src block.
         (block (and start (match-string 0)))
         (headers (and start (match-string 4)))
         (stars (concat (make-string (or (org-current-level) 1) ?*) " "))
         (upper-case-p (and block
                            (let (case-fold-search)
                              (string-match-p "#\\+BEGIN_SRC" block)))))
    (if (and info start) ;; At src block, but not within blank lines after it.
        (mapc
         (lambda (place)
           (save-excursion
             (goto-char place)
             (let ((lang (nth 0 info))
                   (indent (make-string (org-current-text-indentation) ?\s)))
               (when (string-match "^[[:space:]]*$"
                                   (buffer-substring (line-beginning-position)
                                                     (line-end-position)))
                 (delete-region (line-beginning-position) (line-end-position)))
               (insert (concat
                        (if (looking-at "^") "" "\n")
                        indent (if upper-case-p "#+END_SRC\n" "#+end_src\n")
                        (if arg stars indent) "\n"
                        indent (if upper-case-p "#+BEGIN_SRC " "#+begin_src ")
                        lang
                        (if (> (length headers) 1)
                            (concat " " headers) headers)
                        (if (looking-at "[\n\r]")
                            ""
                          (concat "\n" (make-string (current-column) ? )))))))
           (move-end-of-line 2))
         (sort (if (org-region-active-p) (list (mark) (point)) (list (point))) #'>))
      (let ((start (point))
            (lang "fish")
            (body (delete-and-extract-region
                   (if (org-region-active-p) (mark) (point)) (point))))
        (insert (concat (if (looking-at "^") "" "\n")
                        (if arg (concat stars "\n") "")
                        (if upper-case-p "#+BEGIN_SRC " "#+begin_src ")
                        lang "\n" body
                        (if (or (= (length body) 0)
                                (string-suffix-p "\r" body)
                                (string-suffix-p "\n" body))
                            ""
                          "\n")
                        (if upper-case-p "#+END_SRC\n" "#+end_src\n")))
        (goto-char start)
        (move-end-of-line 1)))))

(defun tw-org-babel-demarcate-block-fish-with-results (&optional arg)
  (interactive)
  (let ((current-buffer-name (buffer-name)))
    (when (and (string= "*scratch*" current-buffer-name)
               (not (eq 'org-mode major-mode)))
      (with-current-buffer current-buffer-name
        (org-mode))))
  (tw-org-babel-demarcate-block-fish arg)
  (org-babel-insert-header-arg "results" "replace output"))

;; The url is from the `search-engine-alist' in Spacemacs
;;   layers/+web-services/search-engine/packages.el
(setq tw-search-url "https://duckduckgo.com/?q=%s")

(defun tw-search-or-browse (&optional args)
  "'&optional args' must be declared otherwise the key binding doesn't work.
Selected text has higher priority than URL. A YouTube URL is
immediately opened by `browse-url-firefox', anything else is put
on prompt with the `tw-search-url' prefix and handled by
`browse-url-firefox'."
  (interactive "p")
  (ignore args)
  (funcall
   (-compose
    #'browse-url-firefox
    ;; (lambda (p) (message "[tw-search-or-browse] url: %s" p) p)
    )
   (cond
    ((or (region-active-p) (evil-visual-state-p))
     ;; Select text as if done from the insert state.
     (format tw-search-url
             (read-string "[firefox] search region: "
                          (buffer-substring-no-properties (region-beginning)
                                                          (region-end)))))

    ((let ((url-string (thing-at-point 'url)))
       (or
        (string-prefix-p "https://youtu.be" url-string)
        (string-prefix-p "https://www.youtube" url-string)))
     (thing-at-point 'url))

    ;; test http://bla.com
    ((string-prefix-p "http" (thing-at-point 'url))
     (thing-at-point 'url))

    (t
     (format tw-search-url
             (read-string "[firefox] search thing: "
                          (thing-at-point 'symbol)))))))

(defmacro tw-def-evar (elisp-var def-val evar-name)
  "Define an Emacs variable from environment with defaults. Warn if
differences were encountered."
  `(let* ((evar-val (or (getenv ,evar-name) ,def-val)))
     (setq ,elisp-var (or (getenv ,evar-name) ,def-val))
     (unless (string= ,elisp-var ,def-val)
       (message "WARN def-val %s and evar %s=%s differ"
                ,def-val ,evar-name evar-val))))

(defun tw-range (&optional start end step)
  "Should behave like `range' in Clojure.

Generate a list of numbers from START to END, incrementing by
STEP. If END is nil, then START defaults to 0 and END is taken
from the first argument. STEP defaults to 1."
  (unless end
    (setq end start
          start 0))
  (unless step
    (setq step 1))
  (let ((range-list '())
        (i start))
    (while (if (> step 0)
               (< i end)
             (> i end))
      (push i range-list)
      (setq i (+ i step)))
    (nreverse range-list)))

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

;; (defun tw-scheme-additional-keywords ()
;;   "Highlight custom Scheme macros like `if-let` as keywords."
;;   (font-lock-add-keywords
;;    nil
;;    '(("\\<\\(if-not\\|if-let\\|when-let\\|unless\\|unless-let\\)\\>"
;;       1 font-lock-keyword-face))))

;; (defface tw-scheme-user-macro-face
;;   '((t :foreground "white"
;;        :background "DarkOrange"
;;        :weight bold
;;        :underline t
;;        :slant italic))
;;   "Custom face for user-defined Scheme macros.")

;; (defface tw-scheme-user-macro-face
;;   '((t :inherit font-lock-keyword-face

;;        ;; :underline t
;;        ;; :underline (:style line)
;;        ;; :underline (:color "SkyBlue" :style line)

;;        :slant italic ; Curvy, stylized forms (often different shapes)
;;        ;; :slant oblique ; pseudo-italics, same glyphs as normal, just slanted

;;        ;; :weight bold

;;        ;; :foreground "DeepSkyBlue1"
;;        ;; :foreground "chartreuse"
;;        ;; :foreground "orange"
;;        ;; :foreground "brown"

;;        ;; :background "color" doesn't work here
;;        ))
;;   "Face for user-defined Scheme macros.")

(defface tw-scheme-user-macro-face
  '((t :inherit font-lock-keyword-face
       ;; :slant italic
       :weight bold
       ;; :foreground "SlateGray1"
       ))
  "Face for user-defined utility Scheme procedures.")

(defvar tw-scheme-macros
  '("if-let" "if-not" "evaluating-module" "module-evaluated"
    "testsymb" "testsymb-trace" "def\*" "def-public")
  "Keywords representing user-defined macros for highlighting.")

(defface tw-scheme-user-util-face
  '((t ;; :inherit hl-line
     :weight bold
     ))
  "Face for user-defined utility Scheme procedures.")

(defvar tw-scheme-utils
  '("comp" "partial" "juxt" "str" "boolean" "empty\?" "member\?" "has-suffix\?"
    "ends-with\?" "has-substring\?" "drop-right" "drop-left" "flatten"
    "dbg" "dbg-exec" "error-command-failed" "contains--gx-dry-run\?"
    "exec-or-dry-run" "exec-system\*" "exec-system\*-new"
    "exec-or-dry-run-new" "exec-with-error-to-string" "exec" "exec-background"
    "exec-foreground" "exec-system"
    "cmd->string" "pipe-return" "pipe-bind" "guix-shell-return"
    "guix-shell-bind" "guix-shell-dry-run-bind" "mdelete-file" "mcopy-file"
    "string-in\?" "remove-element" "remove-all-elements" "mktmpfile"
    "url\?" "plist-get" "directory-exists\?" "symbolic-link\?" "true\?"
    "false\?" "syntax->list" "drop-last" "drop-last-smart"
    "butlast" "butlast-smart" "take-smart" "drop-smart" "take-last"
    "take-last-smart" "cartesian" "interleave" "combine"
    "read-all" "read-all-sexprs" "read-all-syntax" "read-all-strings"
    "analyze-pids-flag-variable" "analyze-pids-call/cc" "compute-cmd"
    "build" "package-output-paths" "path" "cnt"
    "url\?"
    "compose-commands-guix-shell"
    "compose-commands-guix-shell-dry-run"
    "compose-shell-commands"
    "dbg-packages-to-install"
    "smart-first"
    "smart-last"
    "smart-second"
    "smart-third"
    "smart-fourth"
    "smart-fifth"
    "smart-take"
    "smart-drop"
    )
  "Keywords representing user-defined utility procedures for highlighting.")

(defun tw-scheme-additional-keywords ()
  (font-lock-add-keywords
   nil
   ;; `((,(regexp-opt tw-scheme-keywords 'words) . font-lock-keyword-face))
   `((,(regexp-opt tw-scheme-utils 'words) . 'tw-scheme-user-util-face))
   )
  (font-lock-add-keywords
   nil
   ;; `((,(regexp-opt tw-scheme-keywords 'words) . font-lock-keyword-face))
   `((,(regexp-opt tw-scheme-macros 'words) . ' tw-scheme-user-macro-face))
   ))

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

(defun tw-shell-readlink (file)
  "Execute the `readlink FILE` command in the current shell."
  (funcall
   (-compose
    ;; TODO implement fallback to bash if fish not found
    #'string-trim-right
    #'shell-command-to-string
    (lambda (strings) (string-join strings " "))
    (-partial #'list "readlink"))
   file))

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
  (when-let ((theme (car custom-enabled-themes)))
    (symbol-name theme)))

(defun tw-reload-current-theme ()
  (interactive)
  (let ((current-theme (car custom-enabled-themes)))
    (tw-reset-all-faces)
    ;; t - theme is safe
    (load-theme current-theme t)))

(defun tw-setup-lisp-comments ()
  "Set up multi-line comment style for Lisp code."
  (setq-local comment-style 'multi-line)
  (setq-local comment-continue ";;"))

;; Wrapper function for automatic mode detection
(defun tw-setup-lisp-comments-maybe ()
  "Set up Lisp comments if in a Lisp-like mode."
  (when (derived-mode-p
         'lisp-mode
         'emacs-lisp-mode
         'scheme-mode
         'clojure-mode
         'racket-mode
         )
    (tw-setup-lisp-comments)))

(defun tw-non-ws-before-point-p ()
  "Return non-nil if there are non-whitespace chars before point on the
same line."
  (save-excursion
    (re-search-backward "\\S-" (line-beginning-position) t)))

(defun tw-non-ws-after-point-p ()
  "Return non-nil if there are non-whitespace chars after point on the same
line."
  (save-excursion
    (re-search-forward "\\S-" (line-end-position) t)))

(defun tw-toggle-comment-sexp-lines ()
  "Comment or uncomment the current sexp, using multi-line comment style.
See also:
https://github.com/abo-abo/lispy
https://github.com/remyferre/comment-dwim-2
https://github.com/noctuid/lispyville
lisp/newcomment.el in the Emacs source code"
  (interactive)
  (let ((bounds (sp-get-comment-bounds)))
    (if bounds
        ;; Already in comment → uncomment
        (uncomment-region (car bounds) (cdr bounds))
      ;; Not in comment → comment the sexp
      (when (tw-non-ws-before-point-p)
        (sp-backward-sexp)
        (sp-forward-sexp)
        ;; Insert newline only when there is something after the current sexp
        (when (tw-non-ws-after-point-p)
          (sp-newline)))
      ;; `if' accepts multiple forms in the `else' branch
      (mark-sexp)
      (comment-dwim nil))))

(provide 'tweaks)

;;; tweaks.el ends here
