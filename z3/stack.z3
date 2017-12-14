;; a sort for events
(declare-sort E)

;; push event
(declare-fun psh (E) bool)

;; pop event
(declare-fun pp (E) bool)

;; < is pre
(declare-fun pre (E E) Bool)
 
;; every event is either an update event or a scan event
(assert 
  (forall ((e E))
          (xor (psh e) (pp e))))
 
;; pre is Antisimetric
(assert 
  (forall ((e E)) (not (pre e e))))
 
;; pre is Transitive  
(assert 
 (forall ((e1 E) (e2 E) (e3 E))
         (=> (and (pre e1 e2) (pre e2 e3)) (pre e1 e3))))
 
;; Extra condition (to simulate intervals = Russel & Wienner)
(assert 
  (forall ((a E) (b E) (c E) (d E))
          (=> (and (pre a b) (pre c d) (not (pre c b))) (pre a d))))

;; a sort for process IDs
(declare-sort P)

;; two processes in this scenario
(declare-const A P)
(declare-const B P)

;; predicate to associate events with processes
(declare-fun in-pid? (E P) bool)

;; all events are associated with a process
(assert (forall ((e E))
		(xor (in-pid? e A) (in-pid? e B))))

;; events in the same process are ordered
(assert (forall ((e1 E) (e2 E) (p P))
		(=> (and (not (= e1 e2)) (in-pid? e1 p) (in-pid? e2 p))
		    (xor (pre e1 e2) (pre e2 e1)))))

;; track the index of push events
;; pop events receive the index of their matching push event
(declare-fun val (E) Int)

;; Int -> Nat
;; push cannot be 0
(assert (forall ((e E))
                (ite (psh e)
                     (> (val e) 0)
                     (>= (val e) 0))))

;; uniqueness of push values
(assert (forall ((e1 E) (e2 E))
                (=> (and (psh e1) (psh e2))
                    (iff (= e1 e2) (= (val e1) (val e2))))))

;; each pop returns a value which has been pushed
(assert (forall ((e1 E))
                (=> (and (pp e1) (> (val e1) 0))
                    (exists ((e2 E))
                            (and (psh e2) (= (val e1) (val e2)))))))

;;; ------------------------------------------------
;;; anti-scenarios
;;; ------------------------------------------------

;; algorithm does not perform pop before matching push
(assert (forall ((e1 E) (e2 E))
		(=> (and (psh e1) (pp e2) (= (val e1) (val e2)))
		    (not (pre e2 e1)))))

;; ;; algorithm does not pop empty from a non-empty stack
;; (assert (forall ((e1 E) (e2 E) (e3 E))
;; 		(=> (and (psh e1) (pp e2) (pp e3)
;; 			 (pre e1 e2) (pre e2 e3)
;; 			 (= (val e1) (val e3)))
;; 		    (not (= 0 (val e2))))))

;; ;; algorithm pops in LIFO
;; (assert (forall ((e1 E) (e2 E))
;; 		(=> (and (pp e1) (pp e2) (pre e1 e2))
;; 		    (exists ((p2 E) (p1 E))
;; 			    (and (psh p2) (psh p1)
;; 				 (= (val p2) (val e2))
;; 				 (= (val p1) (val e1))
;; 				 (pre p2 p1))))))

(check-sat)

(declare-fun PRE (E E) bool)

(assert 
  (forall ((e1 E) (e2 E)) 
          (= (PRE e1 e2) 
             (or (pre e1 e2) ; e1 pre e2 --> e1 PRE e2
                 (and (psh e1) (pp e2) (= (val e1) (val e2))) ; push(x) PRE pop(x)
		 (and (pp e1) (pp e2) ; push(x) pre push(y) /\ push(y) pre pop(x) --> pop(y) PRE pop(x)
		       (exists ((p2 E) (p1 E))
		  	      (and (psh p2) (psh p1)
		  		   (= (val e1) (val p1)) (= (val e2) (val p2))
		  		   (pre p2 p1)
				   (pre p1 e2)
				   )))
		 (and (pp e1) (pp e2) (= 0 (val e2)) ; push(x) pre pop(empty) --> pop(x) PRE pop(empty)
		      (exists ((p E))
		 	      (and (psh p) (= (val e1) (val p)) (pre p e2))))
		 (and (pp e1) (= e1 e2) (not (= 0 (val e1))) ; pop(x) PRE pop(x) if x was not pushed
		      (forall ((p E))
		 	      (=> (psh p) (not (= (val e1) (val p))))))
		 ))))

(check-sat)
;;; ------------------------------------------------
;;; This section is supposed to prove linearizability.
;;; It should always remain the same, regardless of the problem formulation
;;; ------------------------------------------------

(push)
(assert (not 
    (forall ((b E) (e E)) 
        (=> 
            ;; Path of length 4 from b to e
            (exists ((e1 E) (e2 E)) (and (PRE b e1) (PRE e1 e2) (PRE e2 e)))

            ;; Path of length <4 from b to e
            (exists ((e1 E)) (and (or (= b e1) (PRE b e1)) (or (= e1 e) (PRE e1 e))))))))

(check-sat)
;;(get-model)
(pop)

(push)

;; No cycle of length <= 4
(assert 
  (exists ((e1 E) (e2 E) (e3 E) (e4 E))
          (and (or (PRE e1 e2) (= e1 e2))
               (or (PRE e2 e3) (= e2 e3))
               (or (PRE e3 e4) (= e3 e4))
               (PRE e4 e1))))  

(check-sat)
(get-model)
(pop)

