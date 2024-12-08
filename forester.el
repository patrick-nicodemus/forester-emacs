(defgroup forester-fonts
  nil ; No initial customization
  "Customization options for the Forester markup language"
  :group 'faces
)

(defface forester-title
  '((t :inherit 'bold))
  "Forester title font. Bold for now."
  :group 'forester-fonts
  )

(defface forester-inline-math
  '((t :foreground "#DFAF8F"))
  "Forester inline math, same color as AuCTeX's color for LaTeX inline."
  :group 'forester-fonts
  )

(defvar forester-ts-font-lock-rules
  '(
    :language forester
    :feature title
    ;; :override t
    ;; There's an outer wrapper here which is semantically meaningless,
    ;; it's just a quotation operator.
    (((title (_)@forester-title)))

    :language forester
    :feature inline-math
    ;; :override t
    ( (inline_math "#" "{" (_)@forester-inline-math "}") )
    )
  )

(defvar forester-ts-indent-rules
  '((forester
     ((parent-is "source_file") parent 0)
     ((node-is "command") grand-parent 2)
     ((node-is "text") (nth-sibling 1) 1)
     ((node-is "inline_math") (nth-sibling 1) 1)
     ((node-is "}") (nth-sibling 0) -1)
     (no-node parent 1)
     (catch-all parent 0)
     )))

(defun forester-ts-setup ()
  "Setup treesit for forester-ts-mode."
  ;; Our tree-sitter setup goes here.

  ;; This handles font locking
  (setq-local treesit-font-lock-settings
               (apply #'treesit-font-lock-rules
                      forester-ts-font-lock-rules))

  (setq-local treesit-font-lock-feature-list
	      '((inline-math title) () ()))

  ;; This handles indentation
  (setq-local treesit-simple-indent-rules forester-ts-indent-rules)

   ;; ... everything else we talk about go here also ...

  ;; End with this
  (treesit-major-mode-setup))

(defun forester-new (prefix)
  "Call forester new with dest = the file associated to the
   current buffer, and the given prefix."
  (interactive "sPrefix: ")
  (let ((root-dir
	 (progn
	   (setq-local dd (file-name-directory (buffer-file-name)))
	   ;; dd ends in a backslash.
	   (while (and dd (not (member "forest.toml" (directory-files dd))))
	     (setq dd (file-name-parent-directory (file-name-directory dd))))
	   dd)))
    (cond (root-dir (cd root-dir))
	  (t (error nil)))
  (let ((new-buffer (generate-new-buffer "*forester-new-output*")))
    (let ((exit-status
	   (call-process "forester" nil new-buffer nil "new"
			 (concat "--prefix=" prefix)
			 (concat "--dest=" (file-name-directory (buffer-file-name)))
			 "./forest.toml"
			 )))
      (let ((buffer-contents
	     (replace-regexp-in-string "\n" ""
	       (with-current-buffer new-buffer (buffer-string)))))
	(cond
	 ((eq exit-status 0)
	  (progn
	    (insert "\\transclude{}")
	    (backward-char)
	    (insert (file-name-base buffer-contents))
	    (forward-char)
	    (find-file-other-window buffer-contents))
	  (kill-buffer new-buffer)
	  )
	 (t (with-help-window new-buffer buffer-contents))))))
  ))

(define-derived-mode forester-mode text-mode "Forester"
  "Major mode for editing Forester trees.

   TODO: Write a build shortcut.

   Do \\[describe-variable] forester- SPC to see available variables.   
   Do \\[describe-key] on key bindings to discover what they do:

   \\{forester-mode-map}"
  (make-local-variable 'forester-toml-dir)

  ;; First, we'll define the desired level of indentation.
  (setq-local font-lock-defaults nil)
  (when (treesit-ready-p 'forester)
    (treesit-parser-create 'forester)
    (forester-ts-setup))
  )

(add-to-list 'auto-mode-alist '("\\.tree\\'" . forester-mode))
