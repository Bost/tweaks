;;; tweaks-core.el --- General Emacs utilities  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 - 2026 Rostislav Svoboda

;;; Commentary:
;; General Emacs utilities.

;;; Code:

(require 'cl-lib)
(require 'dash)
(require 'subr-x)
(require 'dired)
(require 'evil)
(require 'magit)

(defvar my-spell-checking-max-buffer-size (* 512 1024)
  "Buffer size in bytes at which automatic spellchecking is skipped.")

(defun tw-enable-spell-checking-for-small-buffer ()
  "Enable automatic spellchecking only below the buffer size limit."
  (when (save-restriction
          (widen)
          (< (1- (position-bytes (point-max)))
             my-spell-checking-max-buffer-size))
    (if (derived-mode-p 'prog-mode)
        (flyspell-prog-mode)
      (flyspell-mode 1))))

(defun tw-koboldcpp ()
  "Setup gptel. koboldcpp is a fork of llama.cpp."
  (interactive)
  (setq
   gptel-model 'test
   gptel-backend
   (gptel-make-openai "koboldcpp"     ; Any name
                      :stream t       ; Stream responses
                      :protocol "http"
                      :host "edge:5001"
                      :models '(test) ; Any names, doesn't matter for Llama
                      )))

(defvar my-env-secrets-file
  (expand-file-name "~/.env-secrets.gpg")
  "Encrypted Bash-style environment file.")

(defun tw-load-env-secrets ()
  "Decrypt `my-env-secrets-file`, let Bash source it, and import env vars."
  (interactive)
  (let ((decrypted-buffer (generate-new-buffer " *my-env-secrets-decrypted*"))
        (env-buffer (generate-new-buffer " *my-env-secrets-env*")))
    (unwind-protect
        (progn
          ;; Decrypt the file into a temporary Emacs buffer.
          (with-current-buffer decrypted-buffer
            (let ((status
                   (call-process
                    "gpg"
                    nil
                    decrypted-buffer
                    nil
                    "--quiet"
                    "--for-your-eyes-only"
                    "--decrypt"
                    my-env-secrets-file)))
              (unless (eq status 0)
                (error "Failed to decrypt %s" my-env-secrets-file))))

          ;; Let Bash parse the decrypted file.
          ;;
          ;; Bash has no long option for `-c`.
          ;; `-c` means: execute the following string as Bash code.
          ;;
          ;; `--noprofile` means: do not read Bash profile files.
          ;; `--norc` means: do not read ~/.bashrc.
          ;;
          ;; `env --null` prints environment entries separated by NUL bytes.
          (with-current-buffer decrypted-buffer
            (let ((status
                   (call-process-region
                    (point-min)
                    (point-max)
                    "bash"
                    nil
                    env-buffer
                    nil
                    "--noprofile"
                    "--norc"
                    "-c"
                    "source /dev/stdin >/dev/null && env --null")))
              (unless (eq status 0)
                (error "Failed to source decrypted env file with Bash"))))

          ;; Import Bash's resulting environment into Emacs.
          (with-current-buffer env-buffer
            (dolist (entry (split-string (buffer-string) "\0" t))
              (when (string-match "\\`\\([^=]+\\)=\\(.*\\)\\'" entry)
                (setenv (match-string 1 entry)
                        (match-string 2 entry))))))

      ;; Ensure decrypted secrets do not remain in buffers.
      (kill-buffer decrypted-buffer)
      (kill-buffer env-buffer))))

(defun tw-getenv-required (variable)
  "Return environment VARIABLE or signal a helpful error."
  (or (getenv variable)
      (user-error "Missing required environment variable: %s" variable)))

(defun tw-getenv-secret (variable)
  "Load encrypted env secrets, then return required environment VARIABLE."
  (tw-load-env-secrets)
  (tw-getenv-required variable))

(defun tw-erc-libera-server ()
  "Return the ERC server specification for Libera.Chat."
  (tw-load-env-secrets)
  (let ((nick (tw-getenv-required "IRC_USER"))
        (password (tw-getenv-required "IRC_PASSWD")))
    `("irc.libera.chat"
      :port 6697
      :ssl t
      :nick ,nick
      :user ,nick
      :password ,password)))

(defun tw-load-gptel-key ()
  "Load OPENAI_KEY from encrypted env file and assign it to `gptel-api-key`."
  (interactive)
  (tw-load-env-secrets)
  (setq gptel-api-key (tw-getenv-secret "OPENAI_KEY"))
  (message "gptel-api-key loaded"))

(defun tw-shell-path ()
  ;; (tw-shell-which "fish")
  (getenv "SHELL")
  )

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

(defun tw-disable-y-or-n-p (orig-fun &rest args)
  (cl-letf (((symbol-function 'y-or-n-p) (lambda (_) t)))
    (apply orig-fun args)))

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

(defmacro tw-interactive-lambda (&rest body)
  "Thanks to https://emacs.stackexchange.com/a/10198/36619"
  (let ((x (macroexp-parse-body body)))
    `(lambda () ,@(car x) (interactive)
       ,@(cdr x))))

(defalias 'tw-il 'tw-interactive-lambda)

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

(defun tw-find-dotf-spacemacs (branch)
  (find-file-existing
   (format "%s/.emacs.d.distros/spacemacs/%s/cfg/init.el"
           (getenv "dotf")
           branch
           )))

(defun tw-find-dotf-spacemacs-develop ()
  "Edit the Spacemacs init.el from the develop-brach, in the current window."
  (interactive)
  (tw-find-dotf-spacemacs "develop"))

(defun tw-find-dotf-spacemacs-guix ()
  "Edit the Spacemacs init.el from the guix-brach, in the current window."
  (interactive)
  (tw-find-dotf-spacemacs "guix"))

(defun tw-find-dotf-spacemacs-spgx ()
  "Edit the Spacemacs init.el from the spgx-brach, in the current window."
  (interactive)
  (tw-find-dotf-spacemacs "spgx"))

(defun tw-find-home-config.scm ()
  "Edit the `$dotf/.../home-<hostname>.scm', in the current window."
  (interactive)
  (find-file-existing
   (format "%s/guix/home/home-%s.scm" (getenv "dotf") (system-name))))

(defun tw-find-syst-config.scm ()
  "Edit the `$dotf/.../syst-<hostname>.scm', in the current window."
  (interactive)
  (find-file-existing
   (format "%s/guix/systems/syst-%s.scm" (getenv "dotf") (system-name))))

(defun tw-find-spguimacs-packages.scm ()
  "Edit the `$dotf/.../spguimacs-packages.scm', in the current window."
  (interactive)
  (find-file-existing
   (format "%s/guix/home/cfg/spguimacs-packages.scm" (getenv "dotf"))))

(defun tw-magit-status ()
  (interactive)
  (tw-save-all-buffers)
  (magit-status-setup-buffer))

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
(defun set-local-keymap (&rest bindings)
  "For project-specific keybindings"
  (dolist (binding (-partition-in-steps 2 2 bindings))
    (let* ((key (car binding))
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

(provide 'tweaks-core)

;;; tweaks-core.el ends here
