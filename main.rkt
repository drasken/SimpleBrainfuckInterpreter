#lang racket

(require racket/cmdline)

;; Data structure to encapsulate the interpreter state
(struct bf-state (tape  ; array that hold "world" data
		  [pc #:mutable]  ; program counter index
		  [ac #:mutable]  ; array pointer
		  jump-table))  ; pre-parsed table for jump instructions

;; Pre-parse function to create the jump table for [ and ] char
;; Since each nested [ correspond  to another ]
;; or another layer of nester brackets. I'll use a list like a "stack"
;; to save each found opening bracket and corresponding closing one.
;; This will help to find discrepancies in source code too. 
(define (make-jump-table code-string)
  (let loop ([i 0]  ; Index counter
             [stack '()]  ; Stack to save index of found [ char
             [jmp-tbl (hash)])
    (cond [(= i (string-length code-string)) ;; Base Case: reached the end of the source code
	   (cond [(null? stack) jmp-tbl]  ; All stack was processed, return the hash table
		 [else (error 'pre-parser "Syntax Error: Unmatched '[' at index ~a" (car stack))])]
	  [else  ; Recursive Step: read and process the character at the current index.
	   ;; In this step, only 3 possible cases are of interest:
	   ;; [ char, ] char, everything else
	   (let ([char (string-ref code-string i)])  ; read the character
             (cond
              ;; Found an opening bracket: Push its index onto the stack
              [(char=? char #\[) (loop (add1 i) (cons i stack) jmp-tbl)]
              ;; Found a closing bracket: Pop the stack to find the match
              [(char=? char #\])
	       ;; Before looping, error check for empty stack
               (cond [(null? stack) (error 'pre-parser "Syntax Error: Unmatched ']' at index ~a" i)]
		     [else (let ([open-idx (car stack)])  ; get the matchine bracket from stack
			     ;; Store both key-value pairs in the jump table 
			     (loop (add1 i) (cdr stack) (hash-set* jmp-tbl open-idx i i open-idx)))])]       
              ;; Ignore all other characters, now just parsing for brackets
              [else (loop (add1 i) stack jmp-tbl)]))])))


;; Core function to implement execution logic for each of the 8 Brainfuck commands
(define (run-interpreter source-code)
  (define tape-length 30000) ; [cite: 2, 13]
  (define state (bf-state (make-vector tape-length 0) 0 0 (make-jump-table source-code)))
  
  (let loop ()
    (when (< (bf-state-pc state) (string-length source-code))
      (let* ([instruction (string-ref source-code (bf-state-pc state))]
             [tape (bf-state-tape state)]
             [ac (bf-state-ac state)]
             [current-val (vector-ref tape ac)])        
        (case instruction
          [(#\+) (vector-set! tape ac (modulo (add1 current-val) 256))] ;[cite: 28]
          [(#\-) (vector-set! tape ac (modulo (sub1 current-val) 256))] ;[cite: 28]
          [(#\>) (if (< ac (sub1 tape-length))
                     (set-bf-state-ac! state (add1 ac))
                     (error "Pointer Overflow"))] ;[cite: 32]
          [(#\<) (if (> ac 0)
                     (set-bf-state-ac! state (sub1 ac))
                     (error "Pointer Underflow"))] ;[cite: 32]
          [(#\.) (display (integer->char current-val)) (flush-output)] ;[cite: 29, 30]
          [(#\,) (let ([in (read-char)])
                   (vector-set! tape ac (if (eof-object? in) 0 (char->integer in))))] ;[cite: 31]
          [(#\[) (when (zero? current-val)
                   (set-bf-state-pc! state (hash-ref (bf-state-jump-table state) (bf-state-pc state))))] ;[cite: 33]
          [(#\]) (unless (zero? current-val)
                   (set-bf-state-pc! state (hash-ref (bf-state-jump-table state) (bf-state-pc state))))] ;[cite: 33, 34]
          [else (void)]) ; Ignore non-BF characters [cite: 52]
        
        (set-bf-state-pc! state (add1 (bf-state-pc state))) ;[cite: 10]
        (loop)))))

;; Entry point for script or binary execution [cite: 7, 11]
(module+ main
  (command-line
   #:args (filename)
   (if (file-exists? filename)
       (run-interpreter (file->string filename))
       (printf "Error: File ~a does not exist.\n" filename))))
