(require 'chatu-common)
(require 'f)

(defun chatu-xournal--find-executable ()
  "Find the xournal executable on PATH, or else return an error."
  (cond
   ((eq system-type 'darwin)
    "/Applications/Xournal++.app/Contents/MacOS/xournalpp")
   (t (condition-case nil
          (file-truename (executable-find "xournalpp"))
        (wrong-type-argument
         (message "Cannot find the xournalpp executable on the PATH.")))))
  )
(defcustom chatu-xournal-executable-func #'chatu-xournal--find-executable
  "The function to find the xournal executable."
  :group 'chatu
  :type 'function)

(defvar xournal-path (shell-quote-argument (funcall chatu-xournal-executable-func)))
(defvar chatu-xournal-template-path nil "Content of empty xournal file.")

(defun chatu-xournal-script (keyword-plist)
  "Get conversion script.
KEYWORD-PLIST contains parameters from the chatu line."
  (let* ((input-path
          (f-expand (chatu-common-with-extension
                     (plist-get keyword-plist :input-path) "xopp")))
         (image-output-path (f-expand (plist-get keyword-plist :output-path)))
         (page (plist-get keyword-plist :page))
         (output-dir (f-dirname image-output-path))
         (output-ext (or (plist-get keyword-plist :out-ext) "png"))
         (tmp "tmp")
         (tmp-in (f-join output-dir (format "%s.%s" tmp output-ext)))
         (tmp-out (f-join output-dir (format "%s-%s.%s" tmp page output-ext) ))
         )
    (chatu-xournal-ensure-file input-path)    
    (format "%s %s -i %s && convert -trim -strip -colors 64 -scale 20%% -alpha background -type optimize %s %s"
            xournal-path
            (shell-quote-argument input-path)
            (shell-quote-argument tmp-in)
            (shell-quote-argument tmp-out)
            (shell-quote-argument image-output-path)
            )
    ))

(defun chatu-xournal-ensure-file (path)
  "DOCSTRING"
  (interactive)
  (unless (f-exists? path)
    (f-mkdir-full-path (file-name-directory path))
    (f-copy chatu-xournal-template-path path)
    ))

(defun chatu-xournal-open (keyword-plist)
  "Open .xournal file.
KEYWORD-PLIST contains parameters from the chatu line."
  (interactive)
  (let* ((path (plist-get keyword-plist :input-path))
         (path (f-expand (chatu-common-with-extension path "xopp")))
         (page (or (plist-get keyword-plist :page) 1)))
    (chatu-xournal-ensure-file path)    
    (cond
     ((eq system-type 'darwin)
      (start-process "" nil "open" "-a" xournal-path path "-n" page))
     (t (start-process "" nil xournal-path path "-n" page)))
    ))

(provide 'chatu-xournal)



