
(in-package :user)

(eval-when (compile eval load)
  (require :regexp2)
  (require :shell)
  (use-package :excl.shell))

(defun cleanup-dir (dir)
  ;; n: => n:\
  ;; n:\src\ => n:\src
  ;; \\foo\bar => \\foo\bar\
  
  ;; convert forward slashes to back slashes
  (setq dir (namestring (pathname dir)))
  
  (if* (=~ "^[A-Za-z]:$" dir)
     then (+= dir "\\")
   elseif (=~ "([A-Za-z]:.+)\\\\$" dir)
     then $1
   elseif (=~ "(\\\\\\\\[^\\\\]+\\\\[^\\\\]+)$" dir)
     then (+= $1 "\\")
     else dir))

#+ignore
(defun cleanup-dir (dir)
  ;; Change all forward slashes to backslashes.  
  (setf dir (substitute #\\ #\/ dir))
  
  (multiple-value-bind (matched dummy remainder)
      (match-re "^[a-z]:(.*)" dir :case-fold t)
    (declare (ignore dummy))
    (if (not matched)
	(error "~A is not a valid directory specification." dir))
    (cond
     ((string= remainder "")
      (concatenate 'string dir "\\"))
     ((string= remainder "\\")
      dir)
     ((char= (schar dir (1- (length dir))) #\\)
      ;; strip trailing backslash
      (subseq dir 0 (1- (length dir))))
     (t ;; already in canonical form
      dir))))
      
#+ignore
(defun test-cleanup-dir ()
  (let (val)
    (dolist (x (list (cons "n:\\" "n:")
		     (cons "n:\\" "n:/")
		     (cons "n:\\" "n:\\")
		     (cons "n:\\src" "n:/src")
		     (cons "n:\\src" "n:\\src")
		     (cons "n:\\src" "n:\\src\\")
		     (cons "n:\\src" "n:/src/")))
      (when (not (string= (car x)
			  (setq val (cleanup-dir (cdr x)))))
	(error "(cleanup-dir ~s): expected ~s, got ~s."
	       (cdr x)
	       (car x)
	       val)))))
