;; UIOP (shipped with ASDF) gives portable access to command line args and files.
;; EVAL-WHEN makes it available also at compile time, when UIOP: symbols are read
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "asdf"))

(defpackage :bf-interpreter
  (:nicknames :bf)
  (:use :cl)
  (:export #:main #:some-public-fn))
(in-package :bf-interpreter)


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
  (let ((stack '())  ; Temp stack to save index of found [ char
	(res  (make-hash-table)))  ; Hash table to return as jump table
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


(defun run-interpreter (source-code)
  "Core function to implement execution logic for each of the 8 Brainfuck commands"
  (let ((state (make-bf-state  ; Local instance of the interpreter state
                :tape (make-array *tape-length* :element-type '(unsigned-byte 8) :initial-element 0)
                :pc 0
                :ac 0
                :jump-table (make-jump-table source-code))))
    ;; No recursion here, using loop to be more idiomatic as in CL
    (loop while (< (bf-state-pc state) (length source-code)) do
      (let* ((instruction (char source-code (bf-state-pc state)))
             (tape (bf-state-tape state))
             (ac (bf-state-ac state))
             (current-val (aref tape ac)))
        (case instruction
          ;; Inc/dec current cell, MOD (not REM) to keep the value in [0, 255]
          (#\+ (setf (aref tape ac) (mod (1+ current-val) 256)))
          (#\- (setf (aref tape ac) (mod (1- current-val) 256)))

          ;; Movement instructions
          (#\> (if (< ac (1- *tape-length*))
                   (incf (bf-state-ac state))
                   (error "Pointer Overflow")))
          (#\< (if (> ac 0)
                   (decf (bf-state-ac state))
                   (error "Pointer Underflow")))

          ;; Print/Read instructions, on EOF READ-CHAR returns the eof-value NIL
          (#\. (write-char (code-char current-val)) (finish-output))
          (#\, (let ((in (read-char *standard-input* nil nil)))
                 (setf (aref tape ac) (if in (char-code in) 0))))

          ;; Jump instructions, move pc to the matching bracket
          (#\[ (when (zerop current-val)
                 (setf (bf-state-pc state)
                       (gethash (bf-state-pc state) (bf-state-jump-table state)))))
          (#\] (unless (zerop current-val)
                 (setf (bf-state-pc state)
                       (gethash (bf-state-pc state) (bf-state-jump-table state))))))
        ;; No OTHERWISE clause: non-BF characters are simply ignored

        (incf (bf-state-pc state))))))


(defun main (&optional (args (uiop:command-line-arguments)))
  "Entry point for script execution, ARGS defaults to the command line arguments"
  (if (/= (length args) 1)
      (format *error-output* "Usage: bf-interpreter <file.bf>~%")
      (let ((filename (first args)))
        (if (uiop:file-exists-p filename)
            ;; Report interpreter errors (unmatched brackets, pointer overflow)
            ;; as a message instead of dropping into the debugger
            (handler-case (run-interpreter (uiop:read-file-string filename))
              (error (e) (format *error-output* "Error: ~a~%" e)))
            (format *error-output* "Error: File ~a does not exist.~%" filename)))))

