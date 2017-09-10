;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Set up the types
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; the sort for "words" in the DFAs' languages
(declare-sort W)

;; the sort of automatons
(declare-sort A)

;; the sort of PIDs. Instead of using Integers
(declare-sort PID)

;; the sort of values stored in the concurrent data structure being analyzed
(declare-sort V)

;; encode events
(declare-sort E)

;; encode 'characters' if words 'w'
(declare-datatypes () ((C (mk-char (event E) (init? bool) (proc PID) (val V)))))

;; V has a minimal/'zero'/'false' value
(declare-const bottom V)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DFA theory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; taking an automaton 'a' and a word 'w', returns true if w is in L(a)
(declare-fun member? (W A) bool)

;; create new word from old word 'w' and character 'c'
(declare-fun cons (C W) W)

;; concatinate two words
(declare-fun catenate (W W) W)

;; service predicates
(define-fun catenation2? ((w!1 W) (w!2 W) (final!1 W)) bool
  (= final!1 (catenate w!1 w!2)))

(define-fun catenation3? ((w!1 W) (w!2 W) (w!3 W) (final!1 W)) bool
  (catenation2? (catenate w!1 w!2) w!3 final!1))

(define-fun catenation4? ((w!1 W) (w!2 W) (w!3 W) (w!4 W) (final!1 W)) bool
  (catenation3? (catenate w!1 w!2) w!3 w!4 final!1))

(define-fun catenation5? ((w!1 W) (w!2 W) (w!3 W) (w!4 W) (w!5 W) (final!1 W)) bool
  (catenation4? (catenate w!1 w!2) w!3 w!4 w!5 final!1))

;; is a character 'c' in a word 'w'
(define-fun has-char? ((w!1 W) (c!1 C)) bool
  (exists ((w1 W) (w2 W))
	  (catenation2? w1 (cons c!1 w2) w!1)))

;; is a word 'w1' a sub-word of another word 'w2'
(define-fun subword? ((w!1 W) (w!2 W)) bool
  (exists ((w1 W) (w2 W))
	  (catenation3? w1 w!1 w2 w!2)))

;; definition of concatination
(assert (forall ((w1 W) (w2 W) (w3 W) (w4 W))
		(=> (and (subword? w2 w1) (subword? w3 w1)
			 (=> (subword? w4 w1)
			     (or (= w2 w4) (= w3 w4))))
		    (or (= w1 (catenate w2 w3)) (= w1 (catenate w3 w2))))))

;; the empty word...
(declare-const epsilon W)

;; ... is indeed empty!
(assert (forall ((c C))
		(not (has-char? epsilon c))))

;; epsilon is the neutral operand of catenation
(assert (forall ((w W))
		(or (= w epsilon)
		    (and (= w (catenate w epsilon))
			 (= w (catenate epsilon w))))))

;; epsilon is always a subword
(assert (forall ((w W))
		(or (= w epsilon)
		    (subword? epsilon w))))

;; words are sequences of characters
;; (assert (forall ((w1 W))
;; 		(or (= w1 epsilon)
;; 		    (exists ((c C) (w2 W))
;; 			    (= w1 (cons c w2))))))

;; (assert (forall ((w1 W) (w2 W) (c C))
;; 		(=> (= w1 (cons c w2))
;; 		    (has-char? w1 c))))

;; minimal automaton
(define-fun minimal-automaton ((a!1 A)) bool
  (forall ((a A) (w W))
	  (=> (and (member? w a!1) (member? w a))
	      (or (= a a!1)
		  (exists ((w W)) (and (member? w a) (not (member? w a!1))))))))

(check-sat)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; The problem being analyzed:
;;; Stack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; define event types
(declare-const pushE E)
(declare-const popE E)

(assert (forall ((e E)) (or (= e pushE) (= e popE))))
(assert (not (= pushE popE)))

;; ;; values other than bottom are unique on the stack
;; (assert (forall ((c1 C) (c2 C))
;; 		(=> (= (val c1) (val c2))
;; 		    (or (= c1 c2)
;; 			(= bottom (val c1))
;; 			(=> (= (event c1) (event c2))
;; 			    (not (= (init? c1) (init? c2))))))))

;; ;; push events cannot have the value 'bottom' defined above
;; (assert (forall ((c C))
;; 		(=> (= pushE (event c))
;; 		    (not (= bottom (val c))))))

(check-sat)

;; ;;; anti-scenario automata defintions

;; ;; a1 accepts histories in which there is an empty pop of a non-empty stack
;; (declare-const a1 A)

;; (assert (forall ((w W))
;; 		(iff (member? w a1)
;; 		     (exists ((w1 W) (c1 C) (w2 W) (c2 C) (w3 W))
;; 			     (and (= pushE (event c1)) (not (init? c1))
;; 				  (= popE (event c2)) (not (init? c2)) (= bottom (val c2))
;; 				  (catenation3? w1 (cons c1 w2) (cons c2 w3) w)
;; 				  (forall ((c3 C))
;; 					 (=> (has-char? w2 c3)
;; 					     (not (and (= popE (event c3))
;; 						       (= (val c1) (val c3)))))))))))


				  
;; 		    ;; (exists ((w1 W) (c1 C) (w2 W) (c2 C) (w3 W) (c3 C))
;; 		    ;; 	    (and (has-char? w1 c1) (= pushE (event c1)) (not (init? c1))
;; 		    ;; 		 (has-char? w2 c2) (= popE (event c2)) (not (init? c2))
;; 		    ;; 		 (has-char? w3 c3) (= popE (event c3)) (not (init? c3))
;; 		    ;; 		 (= bottom (val c3))
;; 		    ;; 		 (catenation3? w1 w2 w3 w))))))

;; (check-sat)

;; ;; a2 accepts histories in which an unsuccessful dec has a previous matching inc
;; (declare-const a2 A)

;; (assert (forall ((w W))
;; 		(=> (member? w a2)
;; 		    (exists ((w1 W) (i E) (w2 W) (d E) (w3 W))
;; 			    (and (balanced? w1)
;; 				 (and (inc? i) (res? i))
;; 				 (balanced? w2)
;; 				 (and (dec? d) (not (successful? d)))
;; 				 (balanced? w3)
;; 				 (catenation3? w1 (cons i w2) (cons d w3) w))))))

;; ;; make sure there is a single automaton of each type
;; (assert (minimal-automaton a1))
;; (assert (minimal-automaton a2))


;; (check-sat)
;; (get-model)
