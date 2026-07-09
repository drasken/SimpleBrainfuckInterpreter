;;;; Guile port of bf-interpreter.rkt (used as the reference blueprint).
;;;; Run: guile bf-interpreter-guile.scm <file.bf>

(use-modules (srfi srfi-9)        ; define-record-type, for the mutable bf-state record
             (ice-9 textual-ports)  ; get-string-all, to slurp a whole source file at once
             (ice-9 format))      ; format, for ~a-style formatted messages

;;;; GLOBAL DATA DEFINITIONS

;; Data structure to encapsulate the interpreter state
(define-record-type bf-state
  (make-bf-state tape pc ac jump-table)
  bf-state?
  (tape bf-state-tape)                ; array that holds "world" data
  (pc bf-state-pc set-bf-state-pc!)   ; program counter index
  (ac bf-state-ac set-bf-state-ac!)   ; array pointer
  (jump-table bf-state-jump-table))   ; pre-parsed table for jump instructions


;; Global variable to save standard BF tape length per the original spec
;; change value here to affect the whole interpreter
(define tape-length 30000)


;;;; FUNCTIONS DEFINITIONS

;; Pre-parse function to create the jump table for [ and ] char
;; Since each nested [ corresponds to another ]
;; or another layer of nested brackets, I use a list like a "stack"
;; to save each found opening bracket and match it to its closing one.
;; This also surfaces bracket mismatches with a clean error.
;; Unlike the Racket original (which threads an immutable hash through
;; the recursion), Guile hash tables are mutable, so the table is
;; built in place with hash-set! as the scan proceeds.
(define (make-jump-table code-string)
  (let ((jmp-tbl (make-hash-table)))
    (let loop ((i 0)          ; Index counter
               (stack '()))   ; Stack to save index of found [ char
      (cond [(= i (string-length code-string)) ;; Base Case: reached the end of the source code
             (cond [(null? stack) jmp-tbl]  ; All stack was processed, return the hash table
                   [else (error "Syntax Error: Unmatched '[' at index" (car stack))])]
            [else  ; Recursive Step: read and process the character at the current index.
             (let ([char (string-ref code-string i)])  ; read the character
               (cond
                ;; Found an opening bracket: Push its index onto the stack
                [(char=? char #\[) (loop (1+ i) (cons i stack))]
                ;; Found a closing bracket: Pop the stack to find the match
                [(char=? char #\])
                 ;; Before looping, error check for empty stack
                 (cond [(null? stack) (error "Syntax Error: Unmatched ']' at index" i)]
                       [else (let ([open-idx (car stack)])  ; get the matching bracket from stack
                               ;; Store both key-value pairs in the jump table
                               (hash-set! jmp-tbl open-idx i)
                               (hash-set! jmp-tbl i open-idx)
                               (loop (1+ i) (cdr stack)))])]
                ;; Ignore all other characters, now just parsing for brackets
                [else (loop (1+ i) stack)]))]))))


;; Core function to implement execution logic for each of the 8 Brainfuck commands
(define (run-interpreter source-code)
  (define state (make-bf-state (make-vector tape-length 0) 0 0 (make-jump-table source-code)))
  (let loop ()
    ;; Check if continue loop or source code is ended
    (when (< (bf-state-pc state) (string-length source-code))
      (let* ([instruction (string-ref source-code (bf-state-pc state))]
             [tape (bf-state-tape state)]
             [ac (bf-state-ac state)]
             [current-val (vector-ref tape ac)])
        (case instruction
          ;; Inc/dec current cell
          [(#\+) (vector-set! tape ac (modulo (1+ current-val) 256))]
          [(#\-) (vector-set! tape ac (modulo (1- current-val) 256))]

          ;; Movement instructions
          [(#\>) (if (< ac (1- tape-length))
                     (set-bf-state-ac! state (1+ ac))
                     (error "Pointer Overflow"))]
          [(#\<) (if (> ac 0)
                     (set-bf-state-ac! state (1- ac))
                     (error "Pointer Underflow"))]

          ;; Print/Read instructions
          [(#\.) (display (integer->char current-val)) (force-output)]
          [(#\,) (let ([in (read-char)])
                   (vector-set! tape ac (if (eof-object? in) 0 (char->integer in))))]

          ;; Jump instructions
          [(#\[) (when (zero? current-val)
                   (set-bf-state-pc! state (hash-ref (bf-state-jump-table state) (bf-state-pc state))))]
          [(#\]) (unless (zero? current-val)
                   (set-bf-state-pc! state (hash-ref (bf-state-jump-table state) (bf-state-pc state))))]
          [else #f]) ; Ignore invalid BF characters

        (set-bf-state-pc! state (1+ (bf-state-pc state)))
        (loop)))))


;; Entry point for script execution
(define (main args)
  (if (null? args)
      (format #t "Usage: guile bf-interpreter-guile.scm <file.bf>~%")
      (let ([filename (car args)])
        (if (file-exists? filename)
            (run-interpreter (call-with-input-file filename get-string-all))
            (format #t "Error: ~a does not exist.~%" filename)))))

(main (cdr (command-line)))
