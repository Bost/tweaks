;;; tweaks-org.el --- Org presentation and Babel commands  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 - 2026 Rostislav Svoboda

;;; Commentary:
;; Org presentation and Babel commands.

;;; Code:

(require 'ob-core)

(defun tw-org-present-start ()
  ;; Center the presentation and wrap lines
  (visual-fill-column-mode 1)
  (visual-line-mode 1))

(defun tw-org-present-end ()
  ;; Stop centering the document
  (visual-fill-column-mode 0)
  (visual-line-mode 0))

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

(provide 'tweaks-org)

;;; tweaks-org.el ends here
