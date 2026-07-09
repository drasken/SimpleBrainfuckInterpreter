(defpackage :bf-interpreter
  (:nicknames :bf)
  (:use :cl)
  (:export #:main #:some-public-fn))
(in-package :my-project)


;; GLobal variables and structs
(defstruct bf-state
  "The struct that encapsulate the interpreter state"
  tape  ; array that hold "world" data
  pc  ; program counter index
  ac  ; array pointer
  jump-table)  ; pre-parsed table for jump instructions


(defparameter *tape-length* 30000)


;; Here package functions
(defun make-jump-table (source-code)
  "Pre-parse function to create the jump table for [ and ] chars"
  (let ((stack '())
	(res  (make-hash-table)))
    (loop for c across source-code
	  for i from 0 do
	  (cond 
	    ((char= c #\[) (push i stack))
	    ((char= c #\])
	     (when (null stack)
	       (error "Syntax Error: Unmatched ']' at index ~a" i))
	     (progn (setf (gethash i res) (car stack))
		    (setf (gethash (car stack) res) i)
		    (pop stack)))))
    (when stack
      (error "Syntax Error: Unmatched '[' at index ~a" (car stack)))
    res))


(defun run-interpreter ())


(defun main ())

