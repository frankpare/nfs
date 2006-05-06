;; -*- mode: common-lisp -*-
;;
;; Copyright (C) 2001 Franz Inc, Berkeley, CA.  All rights reserved.
;; Copyright (C) 2002-2005 Franz Inc, Oakland, CA.  All rights reserved.
;;
;; This code is free software; you can redistribute it and/or
;; modify it under the terms of the version 2.1 of
;; the GNU Lesser General Public License as published by 
;; the Free Software Foundation, as clarified by the Franz
;; preamble to the LGPL found in
;; http://opensource.franz.com/preamble.html.
;;
;; This code is distributed in the hope that it will be useful,
;; but without any warranty; without even the implied warranty of
;; merchantability or fitness for a particular purpose.  See the GNU
;; Lesser General Public License for more details.
;;
;; Version 2.1 of the GNU Lesser General Public License can be
;; found at http://opensource.franz.com/license.html.
;; If it is not present, you can access it from
;; http://www.gnu.org/copyleft/lesser.txt (until superseded by a newer
;; version) or write to the Free Software Foundation, Inc., 59 Temple
;; Place, Suite 330, Boston, MA  02111-1307  USA
;;
;; $Id: nlm.cl,v 1.12 2006/05/06 19:42:16 dancy Exp $

(in-package :user)

;; This file implements the Network Lock Monitor (NLM) protocol. 

;; Ref: http://www.opengroup.org/onlinepubs/009629799/chap9.htm

(defparameter *nlm-gate* (mp:make-gate nil))
(defparameter *nlm-debug* nil)
(defparameter *nlm-retry-interval* 2) ;; seconds
(defparameter *nlm-grant-notify-interval* 30) ;; seconds

;; XXX - We do not do grace period stuff because when our NFS 
;; server restarts, all filehandles are invalid, so there would be
;; no way for a client to reclaim a lock anyway.

;;; Start autogenerated code 

(defun xdr-netobj (xdr &optional vec)
  (ecase (xdr-direction xdr)
    (:build 
     (xdr-opaque-variable xdr :vec vec))
    (:extract
     (xdr-opaque-variable xdr))))

;; enum nlm-stats
(eval-when (compile load eval)
 (defconstant *lck-granted* 0)
 (defconstant *lck-denied* 1)
 (defconstant *lck-denied-nolocks* 2)
 (defconstant *lck-blocked* 3)
 (defconstant *lck-denied-grace-period* 4))

(defun xdr-nlm-stats (xdr &optional int)
 (xdr-int xdr int))

(defxdrstruct nlm-stat ((nlm-stats stat)))

(defxdrstruct nlm-res ((netobj cookie)
                          (nlm-stat stat)))


(defxdrstruct nlm4-res ((netobj cookie)
                          (nlm-stat stat)))

(defxdrstruct nlm-holder ((bool exclusive)
                          (int svid)
                          (netobj oh)
                          (unsigned l-offset)
                          (unsigned l-len)))

(defxdrunion nlm-testrply (nlm-stats stat)
 (
  (#.*lck-denied* nlm-holder holder)
  (:default void)
 ))

(defxdrunion nlm4-testrply (nlm4-stats stat)
 (
  (#.*lck-denied* nlm4-holder holder)
  (:default void)
 ))

(defxdrstruct nlm-testres ((netobj cookie)
                          (nlm-testrply test-stat)))

(defxdrstruct nlm4-testres ((netobj cookie)
                          (nlm4-testrply test-stat)))

(defxdrstruct nlm-lock ((string caller-name)
                          (fhandle2 fh)
                          (netobj oh)
                          (int svid) 
                          (unsigned l-offset) 
                          (unsigned l-len)))

(defxdrstruct nlm-lockargs ((netobj cookie)
                          (bool block)
                          (bool exclusive)
                          (nlm-lock alock)
                          (bool reclaim)
                          (int state)))

(defxdrstruct nlm-cancargs ((netobj cookie)
                          (bool block)
                          (bool exclusive)
                          (nlm-lock alock)))


(defxdrstruct nlm4-cancargs ((netobj cookie)
                          (bool block)
                          (bool exclusive)
                          (nlm4-lock alock)))


(defxdrstruct nlm-testargs ((netobj cookie)
                          (bool exclusive)
                          (nlm-lock alock)))

(defxdrstruct nlm4-testargs ((netobj cookie)
                          (bool exclusive)
                          (nlm4-lock alock)))

(defxdrstruct nlm-unlockargs ((netobj cookie)
                          (nlm-lock alock)))

(defxdrstruct nlm4-unlockargs ((netobj cookie)
                          (nlm4-lock alock)))

;; enum fsh-mode
(eval-when (compile load eval)
 (defconstant *fsm-dn* 0)
 (defconstant *fsm-dr* 1)
 (defconstant *fsm-dw* 2)
 (defconstant *fsm-drw* 3))

(defun xdr-fsh-mode (xdr &optional int)
 (xdr-int xdr int))

;; enum fsh-access
(eval-when (compile load eval)
 (defconstant *fsa-none* 0)
 (defconstant *fsa-r* 1)
 (defconstant *fsa-w* 2)
 (defconstant *fsa-rw* 3))

(defun xdr-fsh-access (xdr &optional int)
 (xdr-int xdr int))

(defxdrstruct nlm-share ((string caller-name)
                          (fhandle2 fh)
                          (netobj oh)
                          (fsh-mode mode)
                          (fsh-access access)))

(defxdrstruct nlm-shareargs ((netobj cookie)
                          (nlm-share share)
                          (bool reclaim)))

(defxdrstruct nlm-shareres ((netobj cookie)
                          (nlm-stats stat)
                          (int sequence)))

(defxdrstruct nlm-notify ((string name)
                          (long state)))

(defxdrstruct nlm4-notify ((string name)
                          (long state)))

;; enum nlm4-stats
(eval-when (compile load eval)
 (defconstant *nlm4-granted* 0)
 (defconstant *nlm4-denied* 1)
 (defconstant *nlm4-denied-nolocks* 2)
 (defconstant *nlm4-blocked* 3)
 (defconstant *nlm4-denied-grace-period* 4)
 (defconstant *nlm4-deadlck* 5)
 (defconstant *nlm4-rofs* 6)
 (defconstant *nlm4-stale-fh* 7)
 (defconstant *nlm4-fbig* 8)
 (defconstant *nlm4-failed* 9))

(defun xdr-nlm4-stats (xdr &optional int)
 (xdr-int xdr int))

(defxdrstruct nlm4-holder ((bool exclusive)
                          (int32 svid)
                          (netobj oh)
                          (uint64 l-offset)
                          (uint64 l-len)))

(defxdrstruct nlm4-lock ((string caller-name)
                          (fhandle3 fh)
                          (netobj oh)
                          (int32 svid)
                          (uint64 l-offset)
                          (uint64 l-len)))

#+ignore
(defxdrstruct nlm4-share ((string caller-name)
                          (fhandle3 fh)
                          (netobj oh)
                          (fsh4-mode mode)
                          (fsh4-access access)))

(defxdrstruct nlm4-lockargs ((netobj cookie)
                          (bool block)
                          (bool exclusive)
                          (nlm4-lock alock)
                          (bool reclaim)
                          (int state)))

(eval-when (compile load eval)
 (defconstant *nlm-prog* 100021)
 (defconstant *nlm-versx* 3)
 (defconstant *nlm-null* 0)
 (defconstant *nlm-test* 1)
 (defconstant *nlm-lock* 2)
 (defconstant *nlm-cancel* 3)
 (defconstant *nlm-unlock* 4)
 (defconstant *nlm-granted* 5)
 (defconstant *nlm-test-msg* 6)
 (defconstant *nlm-lock-msg* 7)
 (defconstant *nlm-cancel-msg* 8)
 (defconstant *nlm-unlock-msg* 9)
 (defconstant *nlm-granted-msg* 10)
 (defconstant *nlm-test-res* 11)
 (defconstant *nlm-lock-res* 12)
 (defconstant *nlm-cancel-res* 13)
 (defconstant *nlm-unlock-res* 14)
 (defconstant *nlm-granted-res* 15)
 (defconstant *nlm-share* 20)
 (defconstant *nlm-unshare* 21)
 (defconstant *nlm-nm-lock* 22)
 (defconstant *nlm-free-all* 23)
 (defconstant *nlm4-vers* 4)
 (defconstant *nlmproc4-null* 0)
 (defconstant *nlmproc4-test* 1)
 (defconstant *nlmproc4-lock* 2)
 (defconstant *nlmproc4-cancel* 3)
 (defconstant *nlmproc4-unlock* 4)
 (defconstant *nlmproc4-granted* 5)
 (defconstant *nlmproc4-test-msg* 6)
 (defconstant *nlmproc4-lock-msg* 7)
 (defconstant *nlmproc4-cancel-msg* 8)
 (defconstant *nlmproc4-unlock-msg* 9)
 (defconstant *nlmproc4-granted-msg* 10)
 (defconstant *nlmproc4-test-res* 11)
 (defconstant *nlmproc4-lock-res* 12)
 (defconstant *nlmproc4-cancel-res* 13)
 (defconstant *nlmproc4-unlock-res* 14)
 (defconstant *nlmproc4-granted-res* 15)
 (defconstant *nlmproc4-share* 20)
 (defconstant *nlmproc4-unshare* 21)
 (defconstant *nlmproc4-nm-lock* 22)
 (defconstant *nlmproc4-free-all* 23)
)

(def-rpc-program (nlm #.*nlm-prog*)
  (
   ((1 #.*nlm-versx*)
     (#.*nlm-null* nlm-null void void)
     (#.*nlm-test* nlm-test nlm-testargs nlm-testres)
     (#.*nlm-lock* nlm-lock nlm-lockargs nlm-res)
     (#.*nlm-cancel* nlm-cancel nlm-cancargs nlm-res)
     (#.*nlm-unlock* nlm-unlock nlm-unlockargs nlm-res)
     ;;(#.*nlm-granted* nlm-granted nlm-testargs nlm-res)

     (#.*nlm-test-msg* nlm-test-msg nlm-testargs void)
     (#.*nlm-lock-msg* nlm-lock-msg nlm-lockargs void)
     (#.*nlm-cancel-msg* nlm-cancel-msg nlm-cancargs void)
     (#.*nlm-unlock-msg* nlm-unlock-msg nlm-unlockargs void)
     ;;(#.*nlm-granted-msg* nlm-granted-msg nlm-testargs void)
     ;;(#.*nlm-test-res* nlm-test-res nlm-testres void)
     ;;(#.*nlm-lock-res* nlm-lock-res nlm-res void)
     ;;(#.*nlm-cancel-res* nlm-cancel-res nlm-res void)
     ;;(#.*nlm-unlock-res* nlm-unlock-res nlm-res void)
     (#.*nlm-granted-res* nlm-granted-res nlm-res void)
     
     ;;(#.*nlm-share* nlm-share nlm-shareargs nlm-shareres)
     ;;(#.*nlm-unshare* nlm-unshare nlm-shareargs nlm-shareres)
     (#.*nlm-nm-lock* nlm-nm-lock nlm-lockargs nlm-res)
     (#.*nlm-free-all* nlm-free-all nlm-notify void)
     
     ;; extra, so that nsm can call us back when something has 
     ;; sent in a notify.
     (99 nlm-nsm-callback nsm-callback-status void)
     
   )
   (#.*nlm4-vers*
     (#.*nlmproc4-null* nlmproc4-null void void)
     (#.*nlmproc4-test* nlmproc4-test nlm4-testargs nlm4-testres)
     (#.*nlmproc4-lock* nlmproc4-lock nlm4-lockargs nlm4-res)
     (#.*nlmproc4-cancel* nlmproc4-cancel nlm4-cancargs nlm4-res)
     (#.*nlmproc4-unlock* nlmproc4-unlock nlm4-unlockargs nlm4-res)
     ;;(#.*nlmproc4-granted* nlmproc4-granted nlm4-testargs nlm4-res)

     (#.*nlmproc4-test-msg* nlmproc4-test-msg nlm4-testargs void)
     (#.*nlmproc4-lock-msg* nlmproc4-lock-msg nlm4-lockargs void)
     (#.*nlmproc4-cancel-msg* nlmproc4-cancel-msg nlm4-cancargs void)
     (#.*nlmproc4-unlock-msg* nlmproc4-unlock-msg nlm4-unlockargs void)
     ;;(#.*nlmproc4-granted-msg* nlmproc4-granted-msg nlm4-testargs void)
     ;;(#.*nlmproc4-test-res* nlmproc4-test-res nlm4-testres void)
     ;;(#.*nlmproc4-lock-res* nlmproc4-lock-res nlm4-res void)
     ;;(#.*nlmproc4-cancel-res* nlmproc4-cancel-res nlm4-res void)
     ;;(#.*nlmproc4-unlock-res* nlmproc4-unlock-res nlm4-res void)
     (#.*nlmproc4-granted-res* nlmproc4-granted-res nlm4-res void)
     
     ;;(#.*nlmproc4-share* nlmproc4-share nlm4-shareargs nlm4-shareres)
     ;;(#.*nlmproc4-unshare* nlmproc4-unshare nlm4-shareargs nlm4-shareres)
     (#.*nlmproc4-nm-lock* nlmproc4-nm-lock nlm4-lockargs nlm4-res)
     (#.*nlmproc4-free-all* nlmproc4-free-all nlm4-notify void)
   ))
  
  )

;; End auto-generated code.

(defun nlm-init ()
  (mp:process-run-function "nlm retry loop" #'nlm-lock-retry-loop)
  (mp:process-run-function "nlm notify loop" #'nlm-grant-notify-loop)
  (mp:open-gate *nlm-gate*))

;; Helpers

(defun nlm-status-to-string (status)
  (case status
    (#.*lck-granted* "GRANTED")
    (#.*lck-denied* "DENIED")
    (#.*lck-denied-nolocks* "DENIED_NOLOCKS")
    (#.*lck-blocked* "BLOCKED")
    (#.*lck-denied-grace-period* "DENIED_GRACE_PERIOD")
    (#.*nlm4-deadlck* "DEADLOCK")
    (#.*nlm4-rofs* "Read-only Filesystem")
    (#.*nlm4-stale-fh* "Stale filehandle")
    (#.*nlm4-fbig* "Offset or length too big")
    (#.*nlm4-failed* "FAILED")
    (t (format nil "~d" status))))

(defun nlm-log-status (status)
  (logit "==> ~a~%" (nlm-status-to-string status)))

(defmacro if-nlm-v4 (vers form1 &optional form2)
  (let ((v (gensym)))
    `(let ((,v ,vers))
       (if (= ,v 4) ,form1 ,form2))))


(defmacro nlm-vers-to-nfs-vers (vers)
  `(if-nlm-v4 ,vers 3 2))

(defstruct (nlm-lock-internal
	    (:print-object nlm-lock-internal-printer))
  peer-addr ;; For retry locks (To send GRANTED message)
  vers ;; so we can make the right kind of callback
  cookie ;; cookie from the original lock request
  exclusive
  caller-name
  fh
  oh
  svid
  offset
  len)

(defun nlm-lock-internal-printer (obj stream)
  (format stream "(V~a, caller: ~a, file: ~a, pid: ~a, offset: ~a, len: ~a)"
	  (nlm-lock-internal-vers obj)
	  (nlm-lock-internal-caller-name obj)
	  (let ((fh (nlm-lock-internal-fh obj)))
	    (if (fh-p fh)
		(fh-pathname fh)
	      fh))
	  (nlm-lock-internal-svid obj)
	  (nlm-lock-internal-offset obj)
	  (nlm-lock-internal-len obj)))

(defun nlm-internalize-lock (lock exclusive vers &key addr cookie)
  (make-nlm-lock-internal 
   :peer-addr addr
   :vers vers
   :cookie (if cookie (xdr-extract-vec cookie))
   :exclusive exclusive
   :caller-name (nlm-lock-caller-name lock)
   :fh (nlm-lock-fh lock)
   :oh (xdr-extract-vec (nlm-lock-oh lock))
   :svid (nlm-lock-svid lock)
   :offset (nlm-lock-l-offset lock)
   :len (nlm-lock-l-len lock)))

(defvar *nlm-state-lock* (mp:make-process-lock))
(defvar *nlm-locks* nil)
(defvar *nlm-retry-list* nil)
(defvar *nlm-notify-list* nil)

(defun nlm-lock-match-p (lock1 lock2)
  (and (eq (nlm-lock-internal-fh lock1) (nlm-lock-internal-fh lock2))
       (equalp (nlm-lock-internal-oh lock1) (nlm-lock-internal-oh lock2))
       (= (nlm-lock-internal-svid lock1) (nlm-lock-internal-svid lock2))
       (= (nlm-lock-internal-offset lock1) (nlm-lock-internal-offset lock2))
       (= (nlm-lock-internal-len lock1) (nlm-lock-internal-len lock2))))

(defun nlm-find-lock (lock list)
  (dolist (entry list)
    (if (nlm-lock-match-p lock entry)
	(return entry))))

(defun nlm-find-lock-by-cookie (cookie list)
  (dolist (entry list)
    (if (equalp (nlm-lock-internal-cookie entry) cookie)
	(return entry))))

;; Returns a list
(defun nlm-find-locks-by-addr (addr list)
  (let (res)
    (dolist (entry list)
      (if (= (nlm-lock-internal-peer-addr entry) addr)
	  (push entry res)))
    res))
      

(defun overlapped-p (start1 end1 start2 end2)
  ;; Easier to conclude what an overlap is not, so figure that out and
  ;; invert.
  (not
   (or 
    ;; Starts and ends below start1
    (and (< start2 start1) (<= end2 start1))
    ;; Starts >= end1
    (>= start2 end1))))

(defun nlm-find-overlapping-lock (fh offset length)
  (let ((start1 offset)
	(end1 (+ offset length)))
    (dolist (entry *nlm-locks*)
      (if (eq (nlm-lock-internal-fh entry) fh)
	  (let* ((start2 (nlm-lock-internal-offset entry))
		 (end2 (+ start2 (nlm-lock-internal-len entry))))
	    (if (overlapped-p start1 end1 start2 end2)
		(return entry)))))))

;; XXX 
;; Windows has no concept of locking from "here to the current/future
;; of end of file" like Unix does.  This what is meant with length is
;; 0.  We simulate it here by using a very large length.  On 32-bit
;; platforms, the third arg to _locking is 32-bits so there may be
;; problems with locking large files.  We may need to provide an
;; interface to LockFile() which supports 64-bit args (in two
;; 32-bit pieces).

;; returns t if lock was successful, nil otherwise
(defun nlm-do-lock-1 (f offset length)
  (file-position f offset)
  (if (= length 0)
      (setf length #x7fffffff))
  (handler-case (excl.osi:locking f #.*lk-nblck* length)
    (syscall-error (c)
      (if* (= (syscall-error-errno c) #.excl.osi:*eacces*)
	 then nil
	 else (error c)))
    (:no-error (&rest args)
      (declare (ignore args))
      t)))

(defun nlm-do-lock (lock)
  (with-nfs-open-file (f (nlm-lock-internal-fh lock)
			 (if* (nlm-lock-internal-exclusive lock) 
			    then :output 
			    else :input)
			 :of of)
    (when (nlm-do-lock-1 f 
			 (nlm-lock-internal-offset lock)
			 (nlm-lock-internal-len lock))
      (incf (openfile-refcount of))
      t)))
      
(defun nlm-do-unlock-1 (f offset length)
  (file-position f offset)
  (if (= length 0)
      (setf length #x7fffffff))
  (excl.osi:locking f #.*lk-unlck* length))

(defun nlm-do-unlock (lock)
  (with-nfs-open-file (f (nlm-lock-internal-fh lock) :any :of of)
    (nlm-do-unlock-1 f 
		     (nlm-lock-internal-offset lock)
		     (nlm-lock-internal-len lock))
    (decf (openfile-refcount of))))
  

(defun nlm-try-lock (lock)
  (let ((vers (nlm-lock-internal-vers lock)))
    ;; Sanity check beforehand.  
    (if* (or (> (nlm-lock-internal-offset lock) #x7fffffff)
	     (> (nlm-lock-internal-len lock) #x7fffffff))
       then (if-nlm-v4 vers #.*nlm4-fbig* #.*lck-denied-nolocks*)
       else (handler-case (nlm-do-lock lock)
	      (error (c)
		(logit "NLM: Unexpected error during lock call: ~a~%" c)
		(if-nlm-v4 vers #.*nlm4-failed* #.*lck-denied-nolocks*))
	      (:no-error (success)
		(if* success
		   then #.*lck-granted*
		   else #.*lck-denied*))))))

;; There is no testing operation using the _locking interface
;; so we have to lock and, if that was succesful, unlock.
(defun nlm-do-test-lock (lock)
  (let ((status (nlm-try-lock lock)))
    (when (= status #.*lck-granted*)
      (nlm-do-unlock lock))
    status))

;; A lock will either be on the retry list (meaning it hasn't been
;; granted yet) or on the notify list (lock has been granted but
;; the granted message hasn't been acknowledged yet).
(defun nlm-cancel-pending-retry (lock)
  (mp:with-process-lock (*nlm-state-lock*)
    (let (status)
      (let ((entry (nlm-find-lock lock *nlm-notify-list*)))
	(if* entry
	   then (if *nlm-debug*
		    (logit "NLM: Removing ~a from notify list.~%" entry))
		(setf *nlm-notify-list* (delete entry *nlm-notify-list*))
		(handler-case (nlm-do-unlock entry)
		  (error (c)
		    (logit "NLM: Unexpected error while unlocking ~a: ~a~%"
			   entry c)))))
      
      (let ((entry (nlm-find-lock lock *nlm-retry-list*)))
	(if* entry
	   then (if *nlm-debug*
		    (logit "NLM: Removing ~a from retry list.~%" entry))
		(setf *nlm-retry-list* (delete entry *nlm-retry-list*))
		(setf status #.*lck-granted*)
	   else (setf status #.*lck-denied-nolocks*)))
      
      (nlm-remove-monitoring (nlm-lock-internal-peer-addr lock))
      
      status)))
	      

;; HP/UX uses auth-null so we can't check against the username.
;; We just do host access checking.  
(defun nlm-access-ok (lock addr)
  (export-host-access-allowed-p (fh-export (nlm-lock-internal-fh lock)) addr))

;; Procedures

;; NULL

(defun nlmproc4-null (arg vers peer cbody)
  (nlm-null arg vers peer cbody))

(defun nlm-null (arg vers peer cbody)
  (declare (ignore arg cbody))
  (if *nlm-debug* 
      (logit "NLM~a: ~a: NULL~%" 
	     (if-nlm-v4 vers "4" "")
	     (socket:ipaddr-to-dotted (rpc-peer-addr peer)))))


;; LOCK

(defun nlmproc4-lock (arg vers peer cbody)
  (nlm-lock arg vers peer cbody))

(defun nlm-lock (arg vers peer cbody &key async (monitor t))
  (declare (ignore cbody))
  (let* ((exclusive (nlm-lockargs-exclusive arg))
	 (alock (nlm-lockargs-alock arg))
	 (cookie (nlm-lockargs-cookie arg))
	 (block (nlm-lockargs-block arg))
	 (reclaim (nlm-lockargs-reclaim arg))
	 (state (nlm-lockargs-state arg))
	 (lock (nlm-internalize-lock alock exclusive vers
				     :addr (rpc-peer-addr peer)
				     :cookie cookie))
	 (fh (nlm-lock-internal-fh lock))
	 (addr (rpc-peer-addr peer))
	 (status (if-nlm-v4 vers #.*nlm4-failed* #.*lck-denied-nolocks*)))
    
    (if *nlm-debug*
	(logit "~
NLM~a: ~a: LOCK~a (~a, block: ~a, excl: ~a, reclaim: ~a, state: ~a)~%"
	       (if-nlm-v4 vers "4" "")
	       (socket:ipaddr-to-dotted addr)
	       (if async "_MSG" "")
	       lock
	       block exclusive reclaim state))
    
    ;; XXX -- need proper synchronization to prevent concurrent
    ;; access to fhandles hash tables, and other relevant shared
    ;; structured.  openfile stuff has been modified but I still
    ;; need to check for stuff that calls close-open-file.

    (if (not monitor)
	(setf block nil))
    
    (if* (not (fh-p fh))
       then (if-nlm-v4 vers 
		       (setf status #.*nlm4-stale-fh*))
     elseif (not (nlm-access-ok lock addr))
       then (if *nlm-debug*
		(logit "==> Access denied by configuration.~%"))
	    (setf status #.*lck-denied*)
       else (mp:with-process-lock (*nlm-state-lock*)
	      (if* (nlm-find-lock lock *nlm-locks*)
		 then (setf status #.*lck-granted*)
		 else (nlm-cancel-pending-retry lock)
		      (setf status (nlm-try-lock lock))
		
		      (if* (= status #.*lck-granted*)
			 then (mp:with-process-lock (*nlm-state-lock*)
				(push lock *nlm-locks*))
			      (if monitor
				  (nlm-add-monitoring addr)))
		
		      (if* (and (= status #.*lck-denied*) block)
			 then (setf status #.*lck-blocked*)
			      (if *nlm-debug*
				  (logit "NLM: Adding ~a retry list.~%" lock))
			      (push lock *nlm-retry-list*)))))

    (if *nlm-debug*
	(nlm-log-status status))

    (make-nlm-res
     :cookie (nlm-lockargs-cookie arg)
     :stat (make-nlm-stat :stat status))))

;; UNLOCK

(defun nlmproc4-unlock (arg vers peer cbody)
  (nlm-unlock arg vers peer cbody))

(defun nlm-unlock (arg vers peer cbody &key async)
  (declare (ignore cbody))
  (let* ((lock (nlm-internalize-lock (nlm-unlockargs-alock arg) nil vers))
	 (fh (nlm-lock-internal-fh lock))
	 (addr (rpc-peer-addr peer))
	 ;; always say OK.  Doing otherwise makes linux log kernel
	 ;; messages.
	 (status #.*lck-granted*)) 
    (if *nlm-debug*
	(logit "~
NLM: ~a: UNLOCK~a~a ~a~%"
	       (socket:ipaddr-to-dotted addr)
	       (if-nlm-v4 vers "4" "")
	       (if async "_MSG" "")
	       lock))
    
    (if* (not (fh-p fh))
       then (if-nlm-v4 vers 
		       (setf status #.*nlm4-stale-fh*))
     elseif (not (nlm-access-ok lock addr))
       then (if *nlm-debug*
		(logit "==> Access denied by configuration.~%"))
	    (setf status #.*lck-denied*)
       else (mp:with-process-lock (*nlm-state-lock*)
	      (let ((entry (nlm-find-lock lock *nlm-locks*)))
		(if* entry
		   then (handler-case (nlm-do-unlock entry)
			  (error (c)
			    (logit "~
NLM: Unexpected error during UNLOCK call: ~a~%" c)
			    (setf status
			      (if-nlm-v4 vers 
					 #.*nlm4-failed*
					 #.*lck-denied-nolocks*)))
			  (:no-error (&rest args)
			    (declare (ignore args))
			    (setf status #.*lck-granted*)
			    (setf *nlm-locks* (delete entry *nlm-locks*))))
			(nlm-remove-monitoring addr)))))
  
    (if *nlm-debug*
	(nlm-log-status status))
    
    (make-nlm-res
     :cookie (nlm-unlockargs-cookie arg)
     :stat (make-nlm-stat :stat status))))

;; CANCEL

(defun nlmproc4-cancel (arg vers peer cbody)
  (nlm-cancel arg vers peer cbody))

(defun nlm-cancel (arg vers peer cbody &key async)
  (declare (ignore cbody))
  (let ((lock (nlm-internalize-lock (nlm-cancargs-alock arg) nil vers))
	(addr (rpc-peer-addr peer))
	(status #.*lck-granted*)) ;; always report success
    
    (if *nlm-debug*
	(logit "~
NLM: ~a: CANCEL~a~A (~a, block: ~a, excl: ~a)~%"
	       (socket:ipaddr-to-dotted addr)
	       (if-nlm-v4 vers "4" "")
	       (if async "_MSG" "")
	       lock
	       (nlm-cancargs-block arg)
	       (nlm-cancargs-exclusive arg)))

    (if* (nlm-access-ok lock addr)
       then (nlm-cancel-pending-retry lock)
       else (if *nlm-debug*
		(logit "==> Access denied by configuration.~%"))
	    (setf status #.*lck-denied*))
    
    (if *nlm-debug*
	(nlm-log-status status))
    
    (make-nlm-res
     :cookie (nlm-cancargs-cookie arg)
     :stat (make-nlm-stat :stat status))))

;; TEST

(defun nlmproc4-test (arg vers peer cbody)
  (nlm-test arg vers peer cbody))

(defun nlm-test (arg vers peer cbody &key async)
  (declare (ignore cbody))
  (let* ((exclusive (nlm-testargs-exclusive arg))
	 (lock (nlm-internalize-lock (nlm-testargs-alock arg) exclusive
				     vers))
	 (fh (nlm-lock-internal-fh lock))
	 (offset (nlm-lock-internal-offset lock))
	 (len (nlm-lock-internal-len lock))
	 (addr (rpc-peer-addr peer))
	 (status (if-nlm-v4 vers #.*nlm4-failed* #.*lck-denied-nolocks*))
	 holder)
  
    (if *nlm-debug*
	(logit "NLM: ~a: TEST~a~a ~a, Exclusive: ~a~%"
	       (socket:ipaddr-to-dotted addr)
	       (if-nlm-v4 vers "4" "")
	       (if async "_MSG" "")
	       lock
	       exclusive))

    (if* (not (fh-p fh))
       then (if-nlm-v4 vers 
		       (setf status #.*nlm4-stale-fh*))
     elseif (not (nlm-access-ok lock addr))
       then (if *nlm-debug*
		(logit "==> Access denied by configuration.~%"))
	    (setf status #.*lck-denied*)
       else (mp:with-process-lock (*nlm-state-lock*)
	      (setf status (nlm-do-test-lock lock))
	      (when (= status #.*lck-denied*)
		(setf holder (nlm-find-overlapping-lock fh offset len))
		(setf holder
		  (if* holder 
		     then (make-nlm-holder 
			   :exclusive (nlm-lock-internal-exclusive holder)
			   :svid (nlm-lock-internal-svid holder)
			   :oh (nlm-lock-internal-oh holder)
			   :l-offset (nlm-lock-internal-offset holder)
			   :l-len (nlm-lock-internal-len holder))
		     else ;; Make something up.  The lock must have been
			  ;; established by an external process (or the
			  ;; supplied file handle is stale)
			  (make-nlm-holder
			   :exclusive t
			   :svid 1
			   :oh (load-time-value 
				(make-array 0 
					    :element-type '(unsigned-byte 8)))
			   :l-offset 0
			   :l-len -1))))))
    
    (if *nlm-debug*
	(nlm-log-status status))
    
    (make-nlm-testres :cookie (nlm-testargs-cookie arg)
		      :test-stat (make-nlm-testrply 
				  :stat status
				  :holder holder))))

;; FREE ALL
(defun nlmproc4-free-all (arg vers peer cbody)
  (nlm-free-all arg vers peer cbody))

(defun nlm-free-all (arg vers peer cbody)
  (declare (ignore cbody))
  (let ((name (nlm-notify-name arg))
	(addr (rpc-peer-addr peer)))
    (if *nlm-debug*
	(logit "NLM~a: ~a: FREE ALL (~a)~%"
	       (if-nlm-v4 vers "4" "")
	       (socket:ipaddr-to-dotted addr)
	       name))
    
    (nlm-cleanup-common addr)))

;; NM (non-monitored) lock
(defun nlmproc4-nm-lock (arg vers peer cbody)
  (nlm-nm-lock arg vers peer cbody))

(defun nlm-nm-lock (arg vers peer cbody)
  (nlm-lock arg vers peer cbody :monitor nil))

;; Make asynchronous versions of the 4 main functions as well.

(defmacro defun-nlm-async (name)
  (let ((funcname 
	 (intern (concatenate 'string "nlm-" (symbol-name name) "-msg")))
	(func4name
	 (intern (concatenate 'string "nlmproc4-" (symbol-name name) "-msg")))
	(res-procnum
	 (intern (concatenate 'string "*nlm-" (symbol-name name) "-res*")))
	(encoder (if (eq name 'test) 'xdr-nlm-testres 'xdr-nlm-res))
	(encoder4 (if (eq name 'test) 'xdr-nlm4-testres 'xdr-nlm4-res))
	(realfunc 
	 (intern (concatenate 'string "nlm-" (symbol-name name)))))
    
    `(eval-when (compile load eval)
       (defun ,funcname (arg vers peer cbody)
	 (ignore-errors
	  (callrpc-1 (rpc-peer-addr peer) #.*nlm-prog* vers ,res-procnum :udp 
		   (if-nlm-v4 vers #',encoder4 #',encoder)
		   (,realfunc arg vers peer cbody :async t)
		   :no-reply t)))
       
       (defun ,func4name (arg vers peer cbody)
	 (,funcname arg vers peer cbody)))))

(defun-nlm-async test)
(defun-nlm-async lock)
(defun-nlm-async unlock)
(defun-nlm-async cancel)

;;; little daemons
 
(defun nlm-lock-retry-loop ()
  (loop
    (mp:with-process-lock (*nlm-state-lock*)
      (let (new-granted)
	(dolist (entry *nlm-retry-list*)
	  (when (= #.*lck-granted* (nlm-try-lock entry))
	    (if *nlm-debug*
		(logit "NLM: Deferred lock ~a granted.~%" entry))
	    (push entry new-granted)))
	
	(if new-granted
	    (dolist (entry new-granted)
	      (nlm-add-monitoring entry)
	      (nlm-send-granted-msg entry)
	      (setf *nlm-retry-list* (delete entry *nlm-retry-list*))))
	
	(setf *nlm-notify-list* (nconc *nlm-notify-list* new-granted))))
      
    (sleep *nlm-retry-interval*)))

(defun nlm-externalize-lock (lock)
  (make-nlm-lock 
   :caller-name (nlm-lock-internal-caller-name lock)
   :fh (nlm-lock-internal-fh lock)
   :oh (nlm-lock-internal-oh lock)
   :svid (nlm-lock-internal-svid lock)
   :l-offset (nlm-lock-internal-offset lock)
   :l-len (nlm-lock-internal-len lock)))

(defun nlm-send-granted-msg (entry)
  (let ((addr (nlm-lock-internal-peer-addr entry))
	(vers (nlm-lock-internal-vers entry)))
    (if *nlm-debug*
	(logit "NLM: Sending GRANTED~a_MSG to ~a~%" 
	       (if-nlm-v4 vers "4" "")
	       (socket:ipaddr-to-dotted addr)))
    
    (ignore-errors
     (callrpc-1 addr
	      #.*nlm-prog*  
	      vers
	      #.*nlm-granted-msg* ;; Same number in all versions.
	      :udp
	      (if-nlm-v4 vers #'xdr-nlm4-testargs #'xdr-nlm-testargs)
	      (make-nlm-testargs 
	       :cookie (nlm-lock-internal-cookie entry)
	       :exclusive (nlm-lock-internal-exclusive entry)
	       :alock (nlm-externalize-lock entry))
	      :no-reply t))))

(defun nlm-grant-notify-loop ()
  (loop
    (mp:with-process-lock (*nlm-state-lock*)
      (dolist (entry *nlm-notify-list*)
	(nlm-send-granted-msg entry)))
    
    (sleep *nlm-grant-notify-interval*)))

(defun nlmproc4-granted-res (arg vers peer cbody)
  (nlm-granted-res arg vers peer cbody))

;; This is the callback the client uses to ack the granted msg.
(defun nlm-granted-res (arg vers peer cbody)
  (declare (ignore cbody))
  (let ((status (nlm-stat-stat (nlm-res-stat arg)))
	(cookie (xdr-extract-vec (nlm-res-cookie arg))))
    (if *nlm-debug*
	(logit "NLM: ~a GRANTED~a_RES (Stat: ~a)~%" 
	       (socket:ipaddr-to-dotted (rpc-peer-addr peer))
	       (if-nlm-v4 vers "4" "")
	       (nlm-status-to-string status)))
    
    (mp:with-process-lock (*nlm-state-lock*)
      (let ((lock (nlm-find-lock-by-cookie cookie *nlm-notify-list*)))
	(if* (null lock)
	   then (if *nlm-debug* 
		    (if* (nlm-find-lock-by-cookie cookie *nlm-locks*)
		       then (logit "==> Duplicate (already received ack).~%")
		       else (logit "==> No matching lock found.~%")))
	   else (setf *nlm-notify-list* (delete lock *nlm-notify-list*))
		(if* (= status #.*lck-granted*)
		   then (if *nlm-debug*
			    (logit "==> ~a fully obtained.~%" lock))
			(push lock *nlm-locks*)
		   else (if *nlm-debug*
			    (logit "==> Client rejecting lock ~a~%" lock))
			;; unlock it.
			(handler-case (nlm-do-unlock lock)
			  (error (c)
			    (logit "~
NLM: Unexpected error while unlocking ~a: ~a~%" lock c)))))))))

;; Used by FREE ALL and by the nsm-callback.
(defun nlm-cleanup-common (addr)
  (mp:with-process-lock (*nlm-state-lock*)
    (let ((entries (nlm-find-locks-by-addr addr *nlm-locks*)))
      (dolist (entry entries)
	(if *nlm-debug*
	    (logit "NLM: Unlocking ~a~%" entry))
	(nlm-do-unlock entry)
	(setf *nlm-locks* (delete entry *nlm-locks*))))
    
    (let ((entries (nlm-find-locks-by-addr addr *nlm-notify-list*)))
      (dolist (entry entries)
	(if *nlm-debug*
	    (logit "NLM: Removing ~a from notify list.~%" entry))
	(setf *nlm-notify-list* (delete entry *nlm-notify-list*))))
    
    (let ((entries (nlm-find-locks-by-addr addr *nlm-retry-list*)))
      (dolist (entry entries)
	(if *nlm-debug*
	    (logit "NLM: Removing ~a from retry list.~%" entry))
	(setf *nlm-retry-list* (delete entry *nlm-retry-list*))))
    
    (nlm-remove-monitoring addr)))


;; A client restarted.  Release their locks.
;; arg is an nsm-callback-status
(defun nlm-nsm-callback (arg vers peer cbody)
  (declare (ignore cbody vers))
  (let ((host (nsm-callback-status-mon-name arg))
	(state (nsm-callback-status-state arg))
	(addr (rpc-peer-addr peer)))
    
    (if *nlm-debug*
	(logit "NLM: NSM reported new state for ~a: ~a~%" 
	       host state))
    
    (when (= addr #.(socket:dotted-to-ipaddr "127.0.0.1"))
      (nlm-cleanup-common (socket:dotted-to-ipaddr host)))))

(defvar *nlm-monitored-hosts* nil)

(defun nlm-addr-in-monitored-list (addr)
  (member addr *nlm-monitored-hosts* :test #'socket:ipaddr-equalp))

(defun nlm-add-monitoring (addr)
  (let ((dotted (socket:ipaddr-to-dotted addr)))
    (mp:with-process-lock (*nlm-state-lock*)
      (if* (nlm-addr-in-monitored-list addr)
	 then (if *nlm-debug*
		  (logit "NLM: ~a already set up for monitoring. (OK)~%"
			 dotted))
	 else (let ((priv #.(make-array 16 :element-type '(unsigned-byte 8)
					:initial-element 0)))
		(if *nlm-debug*
		    (logit "NLM: Calling NSM to add monitoring for ~a~%"
			   dotted))
		
		;; XXX make rpcgen generate nice defuns to encapsulate this
		;; nonsense.
		(handler-case
		    (callrpc-1 
		     #.(socket:dotted-to-ipaddr "127.0.0.1")
		     #.*sm-prog*
		     #.*sm-vers*
		     #.*sm-mon*
		     :udp
		     #'xdr-mon
		     (make-mon :mon-id 
			       (make-mon-id 
				:mon-name dotted
				:my-id (make-my-id 
					:my-name "127.0.0.1"
					:my-prog #.*nlm-prog*
					:my-vers 1 
					:my-proc 99))
			       :priv priv)
		     :outproc #'xdr-sm-stat-res)
		  (error (c)
		    (logit "~
NLM: Unexpected error while calling NSM MON: ~a~%" c))
		  (:no-error (res)
		    (let ((status (sm-stat-res-res-stat res))) ;; Cripes!
		      (if* (= status #.*stat-succ*)
			 then (if *nlm-debug*
				  (logit "NLM: ==> Success~%"))
			      (push addr *nlm-monitored-hosts*)
			 else (if *nlm-debug*
				  (logit "NLM: ==> Failed~%")))))))))))


(defun nlm-remove-monitoring (addr)
  (let ((dotted (socket:ipaddr-to-dotted addr)))
    (mp:with-process-lock (*nlm-state-lock*)
      (if* (not (nlm-addr-in-monitored-list addr))
	 then (if *nlm-debug*
		  (logit "NLM: nlm-remove-monitoring: ~a not on monitoring list. (OK)~%"
			 dotted))
	 else (when (and 
		     (null (nlm-find-locks-by-addr addr *nlm-locks*))
		     (null (nlm-find-locks-by-addr addr *nlm-retry-list*))
		     (null (nlm-find-locks-by-addr addr *nlm-notify-list*)))
		(if *nlm-debug*
		    (logit "NLM: Calling NSM to remove monitoring for ~a~%" 
			   dotted))
		
		(handler-case
		    (callrpc-1
		     #.(socket:dotted-to-ipaddr "127.0.0.1")
		     #.*sm-prog*
		     #.*sm-vers*
		     #.*sm-unmon*
		     :udp
		     #'xdr-mon-id
		     (make-mon-id 
		      :mon-name dotted
		      :my-id (make-my-id 
			      :my-name "127.0.0.1"
			      :my-prog #.*nlm-prog*
			      :my-vers 1 
			      :my-proc 99)))
		  (error (c)
		    (logit "~
NLM: Unexpected error while calling NSM UNMON: ~a~%" c))
		  (:no-error (res)
		    (declare (ignore res))
		    (if *nlm-debug*
			(logit "NLM: ==> Success~%"))))
		;; Remove from list even if the call didn't go through.
		(setf *nlm-monitored-hosts* 
		  (delete addr *nlm-monitored-hosts*
			  :test #'socket:ipaddr-equalp)))))))
