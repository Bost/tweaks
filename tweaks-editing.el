;;; tweaks-editing.el --- Text editing, selection, and clipboard commands  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 - 2026 Rostislav Svoboda

;;; Commentary:
;; Text editing, selection, and clipboard commands.

;;; Code:

(require 'evil)
(require 'copy-sexp)

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

(defun tw-primary-selection-value ()
  "Read PRIMARY for the default interprogram paste."
  (let ((select-enable-primary t)
        (select-enable-clipboard nil))
    (gui-selection-value)))

(defun tw-paste-from-xsel-clipboard ()
  "Yank text from CLIPBOARD, the selection read by `xsel --clipboard'."
  (interactive)
  ;; Read CLIPBOARD even when Emacs owns it after a copy.
  (let ((gui-last-cut-in-clipboard nil)
        (select-enable-primary nil)
        (interprogram-paste-function
         (lambda ()
           (or (gui-selection-value)
               (user-error "CLIPBOARD has no text")))))
    (clipboard-yank)))

(defun tw-evil-mark-yanked-text (command &rest args)
  "Record the bounds left by a yank before Evil adjusts point."
  (let ((tick (buffer-chars-modified-tick)))
    (prog1 (apply command args)
      (let ((other-end (mark t)))
        (when (and evil-local-mode other-end
                   (/= tick (buffer-chars-modified-tick))
                   (/= (point) other-end))
          (evil-set-marker ?\[ (min (point) other-end))
          (evil-set-marker ?\] (1- (max (point) other-end))))))))

(dolist (command '(yank yank-pop clipboard-yank mouse-yank-primary))
  (advice-add command :around #'tw-evil-mark-yanked-text))

(defun tw-evil-select-pasted ()
  "Visually select the text between Evil's change marks."
  (interactive)
  ;; Evil's change marks include the final character.
  (let ((beg (evil-get-marker ?\[))
        (end (evil-get-marker ?\])))
    (unless (and (integerp beg) (integerp end)
                 (<= (point-min) beg end (point-max))
                 (< beg (point-max)))
      (user-error "No pasted text to select"))
    (evil-visual-select beg (min (1+ end) (point-max)) 'inclusive)))

(defun tw-yank-and-select ()
  "Yank text and select it in Evil Visual state."
  (interactive)
  (yank)
  (tw-evil-select-pasted))

(defun tw-insert-str (s &optional n-chars-back)
  (interactive "p")
  (insert s)
  (left-char n-chars-back)
  (tw-evil-insert))

(defun tw-insert-group-parens ()
  (interactive)
  (let* ((msg "\\(.*\\)"))
    (tw-insert-str msg 2)))

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

(provide 'tweaks-editing)

;;; tweaks-editing.el ends here
