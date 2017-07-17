;; a sort for events
(declare-sort E)

;; a sort for proecss IDs
(declare-sort PID)

;; represents value getter
(declare-fun phi (E PID) Int)

;; the range of the val function is ℕ
(assert (forall ((e E) (i PID))
                (< 0 (phi e i))))

;; update event
(declare-fun update (E) Bool)

;; update-event generator
(declare-fun p-update (E PID) Bool)

(assert (forall ((e E))
                (iff (update e)
                     (exists ((i PID)) (p-update e i)))))

(assert (forall ((e E) (i PID) (j PID))
                (=> (and (p-update e i) (p-update e j))
                     (= i j))))


;; scan event
(declare-fun scan (E) Bool)

;; < is pre
(declare-fun pre (E E) Bool)
 
;; every event is either an update event or a scan event
(assert 
  (forall ((e E))
          (xor (update e) (scan e))))
 
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

;; update events from the same process are ordered
(assert (forall ((u1 E) (u2 E) (i PID))
                (=> (and (p-update u1 i) (p-update u2 i))
                    (or (pre u1 u2) (pre u2 u1) (= u1 u2)))))

;;; anti-scenarios

;; Uniqueness
(assert (forall ((u1 E) (u2 E) (k PID))
                (=> (and (p-update u1 k) (p-update u2 k))
                    (and (not (= (phi u1 k) (phi u2 k)))
                         (=> (pre u1 u2)
                             (< (phi u1 k) (phi u2 k)))))))

;; Integrity
(assert (forall ((s E) (k PID))
                (=> (scan s)
                    (exists ((u E))
                            (=> (p-update u k)
                                (= (phi s k) (phi u k)))))))

;; Proximity
(assert (forall ((s E) (u E) (k PID))
                (=> (and (scan s) (p-update u k))
                    (and (=> (pre s u) (< (phi s k) (phi u k)))
                         (=> (pre u s) (<= (phi u k) (phi s k)))))))

;; Read Precedence
(assert (forall ((s1 E) (s2 E))
                (=> (and (scan s1) (scan s2))
                    (=> (or (pre s1 s2)
                            (exists ((k PID)) (< (phi s1 k) (phi s2 k))))
                        (forall ((k PID))
                                (<= (phi s1 k) (phi s2 k)))))))

;; Write Precedence
(assert (forall ((s E) (u1 E) (u2 E) (j PID) (k PID))
                (=> (and (scan s) (p-update u1 j) (p-update u2 k) (pre u1 u2) (<= (phi u2 k) (phi s k)))
                    (<= (phi u1 j) (phi s j)))))

(declare-fun PRE (E E) bool)

;; This definition of PRE is the definition of F used in the proof of the "shrinking lemma"
;; by anderson in the Appendix of his paper "Composite Registers" from '89 (last revised on '92)
;; it seems overly large for the purposes of proving his "anti-scenarios"
;; we can probably leave out some of the terms
(assert 
  (forall ((e1 E) (e2 E)) 
          (= (PRE e1 e2) 
             (or (pre e1 e2)
                 (and (update e1) (scan e2) (exists ((i PID)) (<= (phi e1 i) (phi e2 i))))
                 (and (scan e1) (update e2) (exists ((i PID)) (< (phi e1 i) (phi e2 i))))
                 (and (scan e1) (scan e2) (exists ((i PID)) (< (phi e1 i) (phi e2 i))))
                 (and (update e1) (update e2) (exists ((s E)) (and (scan s) (PRE e1 s) (PRE s e2))))
                 (and (update e1) (update e2) (not (= e1 e2)) (exists ((v E) (w E) (i PID) (j PID))
                                                                      (and (update v) (update w)
                                                                           (<= (phi e1 i) (phi v i))
                                                                           (pre v w)
                                                                           (<= (phi w j) (phi e2 j)))))))))
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
