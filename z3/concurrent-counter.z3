(set-option :produce-unsat-cores true)

;; a sort for events
(declare-sort E)

;; <_I is a PO on the "atomic" intervals E
(declare-fun <I (E E) Bool)

;; <_I is anti-reflexive
(assert (forall ((e E)) (not (<I e e))))

;; <_I is a strict partial order on intervals (Russel & Wienner)
(assert (forall ((a E) (b E) (c E) (d E))
		(=> (and (<I a b) (<I c d) (not (<I c b)))
		    (<I a d))))


;; a sort for event boundaries
(declare-sort B)

;; predicates to identify elements of B
;; as either interval start (invoke) or
;; end (return) boundaries
(declare-fun invoke? (B) Bool)
(declare-fun return? (B) Bool)

;; mapping functions to get the start (invoke)
;; or end (return) bounraries of a given interval
(declare-fun invoke (E) B)
(declare-fun return (E) B)

;; mapping function from a boundary to its interval
(declare-fun interval (B) E)

;; <_B is a total order on the boundaries
(declare-fun <B (B B) Bool)

;; <_B is anti-reflexive
(assert (forall ((b B)) (not (<B b b))))

;; <_B is transitive
(assert (forall ((b1 B) (b2 B) (b3 B))
		(=> (and (<B b1 b2) (<B b2 b3))
		    (<B b1 b3))))

;; <_B is a total (linear) order
(assert (forall ((b1 B) (b2 B))
		(=> (not (= b1 b2))
		    (or (<B b1 b2) (<B b2 b1)))))

;; each boundary is either a start or end boundary, not both
(assert (forall ((b B))
		(xor (invoke? b) (return? b))))

;; make sure invoke and invoke? are consistent
(assert (forall ((b B))
		(iff (invoke? b)
		     (exists ((e E))
			(= b (invoke e))))))


;; make sure return and return? are consistent
(assert (forall ((b B))
		(iff (return? b)
		     (exists ((e E))
			(= b (return e))))))

;; invoke() and return() map an event to 
;; interval boundaries, which are correctly ordered
(assert (forall ((e E))
		(exists ((b1 B) (b2 B))
			(and (= b1 (invoke e))
			     (= b2 (return e))
			     (<B b1 b2)))))

;; intervals cannot map to a shared boundary
(assert (forall ((e1 E) (e2 E))
		(=> (not (= e1 e2))
		    (and (not (= (invoke e1) (invoke e2)))
			 (not (= (return e1) (return e2)))))))

;; each boundary maps to some interval
(assert (forall ((b B))
		(exists ((e E))
			(= (interval b) e))))

(assert (forall ((b B))
		(=> (invoke? b)
		    (= b (invoke (interval b))))))

(assert (forall ((b B))
		(=> (return? b)
		    (= b (return (interval b))))))

;; no two different invoke or return boundaries
;; map to the same interval
(assert (forall ((b1 B) (b2 B))
		(=> (= (interval b1) (interval b2))
		    (or (= b1 b2)
			(and
			 (not (and (invoke? b1) (invoke? b2)))
			 (not (and (return? b1) (return? b2))))))))

;; only two boundaries per interval
(assert (forall ((b1 B) (b2 B) (b3 B))
		(=> (and (not (= b1 b2)) (not (= b2 b3)) (not (= b3 b1))
			(= (interval b1) (interval b2)))
		   (not (= (interval b3) (interval b1))))))

;; <_I and <_B are consistent
(assert (forall ((e1 E) (e2 E))
		(iff (<I e1 e2)
		   (and (<B (return e1) (invoke e2))))))

;; ensure consistency of basic framework
(check-sat)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; counter-specific declarations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; event-type predicates
(declare-fun inc? (E) Bool)
(declare-fun dec? (E) Bool)

(assert (forall ((e E))
		(xor (inc? e) (dec? e))))

(declare-const first-inc B)
(assert (and (invoke? first-inc) (inc? (interval first-inc))))
(assert (forall ((b B))
		(=> (and (invoke? b) (inc? (interval b)))
		    (or (= first-inc b) (<B first-inc b)))))

(declare-const first-dec B)
(assert (and (return? first-dec) (dec? (interval first-dec))))
(assert (forall ((b B))
		(=> (and (return? b) (dec? (interval b)))
		    (or (= first-dec b) (<B first-dec b)))))

(declare-fun next (B B) Bool)

(assert (forall ((b B)) (not (next b b))))

(assert (forall ((b1 B) (b2 B) (b3 B))
		(=> (and (not (= b1 b3)) (not (= b2 b3)) (next b1 b2))
		    (not (next b1 b3)))))

(assert (forall ((b1 B) (b2 B) (b3 B))
		(=> (and (invoke? b1) (invoke? b2) (invoke? b3)
			 (not (= b1 b3)) (not (= b2 b3))
			 (inc? (interval b1)) (inc? (interval b2))
			 (inc? (interval b3))
			 (<B b1 b2)
			 (or (<B b3 b1) (<B b2 b3)))
		    (next b1 b2))))

(assert (forall ((b1 B) (b2 B) (b3 B))
		(=> (and (return? b1) (return? b2) (return? b3)
			 (not (= b1 b3)) (not (= b2 b3))
			 (dec? (interval b1)) (dec? (interval b2))
			 (dec? (interval b3))
			 (<B b1 b2)
			 (or (<B b3 b1) (<B b2 b3)))
		    (next b1 b2))))

;; Matching. Map return() of dec() to invoke() of Inc()
(declare-fun M (B B) Bool)

;; Match the first dec() with the first inc()
(assert (M first-dec first-inc))

(assert (forall ((b1 B) (b2 B))
		(=> (and (return? b1) (dec? (interval b1)) (M b1 b2))
		    (inc? (interval b2)))))

(assert (forall ((b1 B) (b2 B) (b3 B) (b4 B))
		(=> (and
		     (M b1 b2)
		     (not (= b1 b3)) (not (= b2 b4))
		     (return? b3) (invoke? b4)
		     (next b1 b3) (next b2 b4))
		    (M b3 b4))))

;; anti scenarios
(assert (forall ((e1 E) (e2 E))
		(=> (and (dec? e1) (inc? e2)
			(M (return e1) (invoke e2)))
		   (not (<I e1 e2)))))

;; specification of a counter using a partial order <_S
(declare-fun <S (E E) Bool)

(assert (forall ((e1 E) (e2 E))
		(= (<S e1 e2)
		   (or (<I e1 e2)
		       (and (dec? e2) (M (return e2) (invoke e1)))))))


;; ensure consistency of counter info
(check-sat)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; correctness proof
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; limit the number of concurrent processes
(declare-fun pid (E) Int)

;; there are only 2 processes and every event must occur
;; in exactly one of them
(assert (forall ((e E))
		(xor (= 0 (pid e)) (= 1 (pid e)))))

;; events that occur in the same process must be ordered
(assert (forall ((e1 E) (e2 E))
		(=> (and (not (= e1 e2)) (= (pid e1) (pid e2)))
		    (or (<I e1 e2) (<I e2 e1)))))

;; ensure consistency of process count info
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
            (exists ((e1 E) (e2 E)) (and (<S b e1) (<S e1 e2) (<S e2 e)))

            ;; Path of length <4 from b to e
            (exists ((e1 E)) (and (or (= b e1) (<S b e1)) (or (= e1 e) (<S e1 e))))))))

(check-sat)
;;(get-model)
(pop)

(push)

;; No cycle of length <= 4
(assert 
  (exists ((e1 E) (e2 E) (e3 E) (e4 E))
          (and (or (<S e1 e2) (= e1 e2))
               (or (<S e2 e3) (= e2 e3))
               (or (<S e3 e4) (= e3 e4))
               (<S e4 e1))))  

(check-sat)
(get-model)
(pop)
