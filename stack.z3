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
          (=> (and (pre a b) (pre c d) (not(pre c b))) (pre a d))))

;; push is comparable in pre
(assert (forall ((p1 E) (p2 E))
        (=> (and (psh p1) (psh p2))
            (or (= p1 p2) (pre p1 p2) (pre p2 p1)))))

;; pop is comparable in pre
(assert (forall ((p1 E) (p2 E))
        (=> (and (pp p1) (pp p2))
            (or (= p1 p2) (pre p1 p2) (pre p2 p1)))))

;; track the index of push events
;; pop events receive the index of their matching push event
(declare-fun idx (E) Int)

;; Int -> Nat
;; push cannot be 0
(assert (forall ((e E))
                (ite (psh e)
                     (> (idx e) 0)
                     (>= (idx e) 0))))

;; uniqueness
(assert (forall ((e1 E) (e2 E))
                (=> (and (psh e1) (psh e2))
                    (xor (= e1 e2) (not (= (idx e1) (idx e2)))))))

(assert (forall ((e1 E))
                (=> (and (pp e1) (> (idx e1) 0))
                    (exists ((e2 E))
                            (and (psh e2) (= (idx e1) (idx e2)))))))

;; monotonicity
;; (allow popping empty stack)
(assert (forall ((e1 E) (e2 E))
                (=> (pre e1 e2)
                    (or (< (idx e1) (idx e2))
                        (and (pp e2) (= (idx e2) 0))))))
(check-sat)

(declare-fun PRE (E E) bool)

(assert 
  (forall ((e1 E) (e2 E)) 
          (= (PRE e1 e2) 
             (or (pre e1 e2)
                 (and (psh e1) (pp e2) (= (idx e1) (idx e2)))
                 (and (pp e1) (psh e2) (= (idx e2) 0))))))

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
(get-model)
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
(pop)
