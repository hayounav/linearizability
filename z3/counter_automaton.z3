;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Set up the types
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
(declare-datatypes () ((C (mk-char (event E) (proc PID) (val V)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DFA theory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; taking an automaton 'a' and a word 'w', returns true if w is in L(a)
(declare-fun member? (W A) bool)

;; is a character 'c' in a word 'w'
(declare-fun has-char? (W C) bool)

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

;; is a word 'w1' a sub-word of another word 'w2'
(declare-fun subword? (W W) bool)

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

;; words are sequences of characters
(assert (forall ((w1 W))
		(exists ((c C) (w2 W))
			(or (= epsilon w2)
			    (= w1 (cons c w2))))))

(check-sat)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; The problem being analyzed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; define event types
(declare-const inc-init)
(declare-const inc-return)
(declare-const dec-init)
(declare-const dec-return)

(assert (forall ((e E)) (or (= e inc-init) (= e inc-return) (= e dec-init) (= e dec-return))))

;; identify event types
(declare-fun inc-init? (C) bool)
(declare-fun dec-init? (C) bool)
(declare-fun inc-return? (C) bool)
(declare-fun dec-return? (C) bool)
(declare-fun successful? (C) bool)

(assert (forall ((c C))
		(=> (successful? c) (dec-return? c))))

;; (define-fun balanced? ((w!1 W)) bool
;;   (or (= epsilon w!1)
;;       (forall ((w1 W) (w2 W))
;; 	      (exists ((w3 W) (i E) (d E))
;; 		      (=> (catenation3? w1 w2 w3 w!1)
;; 			  (and (inc? i) (dec? d)
;; 			       (= w2 (cons i (cons d epsilon)))))))))


;; ;; event PID getter
;; (declare-fun event-pid (E) PID)

;; ;; minimal automaton
;; (define-fun minimal-automaton ((a!1 A)) bool
;;   (forall ((a A) (w W))
;; 	  (=> (and (member? w a!1) (member? w a))
;; 	       (or (= a a!1)
;; 		   (exists ((w W)) (and (member? w a) (not (member? w a!1))))))))

;; ;;; anti-scenario automata defintions

;; ;; a1 accepts histories in which there is a successful dec without a previous matching inc
;; (declare-const a1 A)

;; (assert (forall ((w W))
;; 		(=> (member? w a1)
;; 		    (exists ((w1 W) (d E) (w2 W))
;; 			    (and (balanced? w1)
;; 				 (balanced? w2)
;; 				 (and (dec? d) (successful? d))
;; 				 (catenation2? w1 (cons d w2) w))))))

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
