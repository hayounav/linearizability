;;(set-option :produce-unsat-cores true)

;; a sort for operations
(declare-sort O)

;; <_O is a PO on operations
(declare-fun <O (O O) Bool)

;; ;; <_O is anti-reflexive
;; (assert (forall ((o O)) (not (<O o o))))

;; ;; <_O is a strict partial order on intervals (Russel & Wienner)
;; (assert (forall ((a O) (b O) (c O) (d O))
;; 		(=> (and (<O a b) (<O c d) (not (<O c b)))
;; 		    (<O a d))))


;; a sort for actions
(declare-sort A)

;; predicates to identify elements of A
;; as either interval start (invoke) or
;; end (return) actions
(declare-fun invoke? (A) Bool)
(declare-fun return? (A) Bool)

;; mapping functions to get the start (invoke)
;; or end (return) actions of a given interval
(declare-fun invoke (O) A)
(declare-fun return (O) A)

;; mapping function from a boundary to its interval
(declare-fun interval (A) O)

;; <_A is a total order on actions
(declare-fun <A (A A) Bool)

;; <_A is anti-reflexive
(assert (forall ((a A)) (not (<A a a))))

;; <_A is transitive
(assert (forall ((a1 A) (a2 A) (a3 A))
		(=> (and (<A a1 a2) (<A a2 a3))
		    (<A a1 a3))))

;; <_A is a total (linear) order
(assert (forall ((a1 A) (a2 A))
		(=> (not (= a1 a2))
		    (or (<A a1 a2) (<A a2 a1)))))

;; each boundary is either a start or end actoin, not both
(assert (forall ((a A))
		(xor (invoke? a) (return? a))))

;; make sure invoke and invoke? are consistent
(assert (forall ((a A))
		(iff (invoke? a)
		     (exists ((o O))
			(= a (invoke o))))))


;; make sure return and return? are consistent
(assert (forall ((a A))
		(iff (return? a)
		     (exists ((o O))
			(= a (return o))))))

;; invoke() and return() map an event to 
;; interval actions, which are correctly ordered
(assert (forall ((o O))
		(exists ((a1 A) (a2 A))
			(and (= a1 (invoke o))
			     (= a2 (return o))
			     (<A a1 a2)))))

;; intervals cannot map to a shared actoin
(assert (forall ((o1 O) (o2 O))
		(=> (not (= o1 o2))
		    (and (not (= (invoke o1) (invoke o2)))
			 (not (= (return o1) (return o2)))))))

;; each actoin maps to some interval
(assert (forall ((a A))
		(exists ((o O))
			(= (interval a) o))))

(assert (forall ((a A))
		(=> (invoke? a)
		    (= a (invoke (interval a))))))

(assert (forall ((a A))
		(=> (return? a)
		    (= a (return (interval a))))))

;; no two different invoke or return actions
;; map to the same interval
(assert (forall ((a1 A) (a2 A))
		(=> (= (interval a1) (interval a2))
		    (or (= a1 a2)
			(and
			 (not (and (invoke? a1) (invoke? a2)))
			 (not (and (return? a1) (return? a2))))))))

;; only two actions per interval
(assert (forall ((a1 A) (a2 A) (a3 A))
		(=> (and (not (= a1 a2)) (not (= a2 a3)) (not (= a3 a1))
			(= (interval a1) (interval a2)))
		   (not (= (interval a3) (interval a1))))))

;; <_O and <_A are consistent
(assert (forall ((o1 O) (o2 O))
		(iff (<O o1 o2)
		   (and (<A (return o1) (invoke o2))))))

;; ensure consistency of basic framework
(check-sat)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; counter-specific declarations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; operation-type predicates
(declare-fun inc? (O) Bool)
(declare-fun dec? (O) Bool)

(assert (forall ((o O))
		(xor (inc? o) (dec? o))))

(declare-const first-inc A)
(assert (and (invoke? first-inc) (inc? (interval first-inc))))
(assert (forall ((a A))
		(=> (and (invoke? a) (inc? (interval a)))
		    (or (= first-inc a) (<A first-inc a)))))

(declare-const first-dec A)
(assert (and (return? first-dec) (dec? (interval first-dec))))
(assert (forall ((a A))
		(=> (and (return? a) (dec? (interval a)))
		    (or (= first-dec a) (<A first-dec a)))))

(declare-fun next (A A) Bool)

(assert (forall ((a A)) (not (next a a))))

(assert (forall ((a1 A) (a2 A) (a3 A))
		(=> (and (not (= a1 a3)) (not (= a2 a3)) (next a1 a2))
		    (not (next a1 a3)))))

(assert (forall ((a1 A) (a2 A) (a3 A))
		(=> (and (invoke? a1) (invoke? a2) (invoke? a3)
			 (not (= a1 a3)) (not (= a2 a3))
			 (inc? (interval a1)) (inc? (interval a2))
			 (inc? (interval a3))
			 (<A a1 a2)
			 (or (<A a3 a1) (<A a2 a3)))
		    (next a1 a2))))

(assert (forall ((a1 A) (a2 A) (a3 A))
		(=> (and (return? a1) (return? a2) (return? a3)
			 (not (= a1 a3)) (not (= a2 a3))
			 (dec? (interval a1)) (dec? (interval a2))
			 (dec? (interval a3))
			 (<A a1 a2)
			 (or (<A a3 a1) (<A a2 a3)))
		    (next a1 a2))))

;; Matching. Map return() of dec() to invoke() of Inc()
(declare-fun M (A A) Bool)

;; Match the first dec() with the first inc()
(assert (M first-dec first-inc))

(assert (forall ((a1 A) (a2 A))
		(=> (and (return? a1) (dec? (interval a1)) (M a1 a2))
		    (inc? (interval a2)))))

(assert (forall ((a1 A) (a2 A) (a3 A) (a4 A))
		(=> (and
		     (M a1 a2)
		     (not (= a1 a3)) (not (= a2 a4))
		     (return? a3) (invoke? a4)
		     (next a1 a3) (next a2 a4))
		    (M a3 a4))))

;; anti scenarios
(assert (forall ((o1 O) (o2 O))
		(=> (and (dec? o1) (inc? o2)
			(M (return o1) (invoke o2)))
		   (not (<O o1 o2)))))

;; specification of a counter using a partial order <_S
(declare-fun <S (O O) Bool)

(assert (forall ((o1 O) (o2 O))
		(= (<S o1 o2)
		   (or (<O o1 o2)
		       (and (dec? o2) (M (return o2) (invoke o1)))))))


;; ensure consistency of counter info
(check-sat)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; correctness proof
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; limit the number of concurrent processes
(declare-fun pid (O) Int)

;; there are only 2 processes and every event must occur
;; in exactly one of them
(assert (forall ((o O))
		(xor (= 0 (pid o)) (= 1 (pid o)))))

;; events that occur in the same process must be ordered
(assert (forall ((o1 O) (o2 O))
		(=> (and (not (= o1 o2)) (= (pid o1) (pid o2)))
		    (or (<O o1 o2) (<O o2 o1)))))

;; ensure consistency of process count info
(check-sat)
;;; ------------------------------------------------
;;; This section is supposed to prove linearizability.
;;; It should always remain the same, regardless of the problem formulation
;;; ------------------------------------------------

(push)
(assert (not 
    (forall ((b O) (e O)) 
        (=> 
            ;; Path of length 4 from b to e
            (exists ((o1 O) (o2 O)) (and (<S b o1) (<S o1 o2) (<S o2 e)))

            ;; Path of length <4 from b to e
            (exists ((o1 O)) (and (or (= b o1) (<S b o1)) (or (= o1 e) (<S o1 e))))))))

(check-sat)
;;(get-model)
(pop)

(push)

;; No cycle of length <= 4
(assert 
  (exists ((o1 O) (o2 O) (o3 O) (o4 O))
          (and (or (<S o1 o2) (= o1 o2))
               (or (<S o2 o3) (= o2 o3))
               (or (<S o3 o4) (= o3 o4))
               (<S o4 o1))))  

(check-sat)
(get-model)
(pop)
