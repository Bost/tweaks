;;; tweaks-lisp.el --- Lisp editing, CIDER commands, and Scheme highlighting  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 - 2026 Rostislav Svoboda

;;; Commentary:
;; Lisp editing, CIDER commands, and Scheme highlighting.

;;; Code:

(require 'tweaks-editing)
;;; TODO byte-compilation warnings (? bc autoloading / lazy loading ? ):
;;; the function ‘cider-load-file’ is not known to be defined.
;;; the function ‘cider--infer-ports’ is not known to be defined.
;;; the function ‘cider-switch-to-repl-buffer’ is not known to be defined.
(require 'cider-repl) ;; cider-repl-tab, etc.
(require 'yasnippet)
(require 'hideshow)

(defun tw-racket-repl-clear ()
  (interactive)
  (let ((inhibit-read-only t))
    ;; (erase-buffer)
    (delete-region (point-min) (- (point-max) 2))))

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
(defun tw-load-clojure-mode (file)
  (if (load-file file)
      (if (string= major-mode "clojure-mode")
          (progn
            (clojure-mode)
            (message "File loaded & clojure-mode set: %s" file))
        (message "File loaded: %s" file))
    (message "File loading failed: %s" file)))

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

(defun tw-current-line-empty-p ()
  (save-excursion
    (beginning-of-line)
    (looking-at-p "[[:space:]]*$")))

;; TODO Implement using the `spacemacs/toggle'
(defun tw-toggle-reader-comment-fst-sexp-on-line (sexp-comment)
  "If line starts with a line comment, toggle the comment.
Otherwise toggle the reader comment."
  (if (and (tw-current-line-empty-p) (tw-end-of-file-p))
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

(defun tw-ins-left-paren ()
  "Simulate key press" (interactive) (execute-kbd-macro (kbd "(")))
(defun tw-ins-right-paren ()
  "Simulate key press" (interactive) (execute-kbd-macro (kbd ")")))

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
    "testsymb"
    "testsymb-trace"
    "def"
    "def\*"
    "def-public"
    "def\*-public"
    )
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
    "url\?"
    "plist\?"
    "plist-get"
    "plist-set"
    "plist-set!"

    "get-keywords"
    "plist-keys"
    "plist-vals"
    "get-keyworded-vals"
    "get-non-keyworded-vals"
    "keyworded-plist\?"


    "some"
    "every\?"
    "not-any\?"
    "not-every\?"
    "some-true\?"
    "every-true\?"
    "has-duplicates\?"

    "writeable-usb-mounted\?"
    "sha1-string"
    "string-checksum"
    "timestamp"
    "sha1-file"
    "inc"
    "str-join"

    "map-indexed"
    "padding-string"
    "nonempty-dotted-list\?"
    "flat-list-cond"

    "directory-exists\?" "symbolic-link\?" "true\?"
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
    "split-on-whitespace"
    "pr-str"
    "pr-str-with-quote"
    "ensure-list"
    "keyword->string"
    "s\+"
    "s-"
    "sx"
    "module-name-for-logging"
    "pretty-print->string"
    "pretty-print-with-comments->string"
    "unspecified-or-empty-or-false?"
    "split-string"
    "smart-split-string"
    "string-split-whitespace"
    ;; "install-recursively" ; procedure is neither public nor exported
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
      ;; Make sure the `transient-mark-mode' is on so that the `comment-dwin'
      ;; calls `comment-region'
      (unless transient-mark-mode
        (transient-mark-mode 1))
      (comment-dwim nil))))

(provide 'tweaks-lisp)

;;; tweaks-lisp.el ends here
