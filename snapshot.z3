;;; events:
;;; - scan
;;; - update
;;; 
;;; * scan returns a versioned view
;;; * update tracks a counter for each register to allow view versioning
;;; * registers contain values in some arbitrary domain

;; a sort for events
(declare-sort E)

;; a sort for register contents
(declare-sort V)

(declare-sort PID)

;; represents value getter
(declare-fun val (E PID) V)

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

;;; ------------------------------------------------
;;; Definition of the alpha function and the anti-scenarios
;;; ------------------------------------------------

;; alpha function represents the matching of update and scan events
(declare-fun alpha (E PID) E)

;; maps from scans to updates
(assert (forall ((s E) (i PID))
                (=> (scan s)
                    (p-update (alpha s i) i))))

;; values are consistent
(assert (forall ((s E) (i PID))
                (=> (scan s)
                    (= (val s i) (val (alpha s i) i)))))

;; correct precedence
(assert (forall ((s E) (i PID))
                (=> (scan s)
                    (not (pre s (alpha s i))))))

;; the update-i the scan "sees" is the most recent one
(assert (forall ((s E) (i PID))
                (=> (scan s)
                    (not (exists ((u E))
                                 (=> (p-update u i)
                                     (and (pre (alpha s i) u)
                                          (pre u s))))))))

;; if s1 < s2 then alpha(s1, i) <= alpha(s2, i)
(assert (forall ((s1 E) (s2 E) (i PID))
                (=> (and (scan s1) (scan s2) (pre s1 s2))
                    (not (pre (alpha s2 i) (alpha s1 i))))))

;; the update-i the scan "sees" is the most recent one
(assert (forall ((s E) (i PID) (j PID))
                (=> (scan s)
                    (forall ((u E))
                            (=> (p-update u i)
                                (not (and (pre (alpha s i) u)
                                          (pre u (alpha s j)))))))))

;; helper relation pre-alpha
(define-fun pre-alpha ((x!1 E) (x!2 E)) Bool
  (and (scan x!1)
       (scan x!2)
       (exists ((i PID))
               (pre (alpha x!1 i) (alpha x!2 i)))))

;; sets of updates are ordered
(assert (forall ((s1 E) (s2 E))
                (=> (and (scan s1) (scan s2))
                    (not (and (pre-alpha s1 s2) (pre-alpha s2 s1))))))

(declare-fun PRE (E E) bool)

(assert 
  (forall ((e1 E) (e2 E)) 
          (= (PRE e1 e2) 
             (or (pre e1 e2)
                  (and (update e1) (scan e2) (exists ((i PID)) (and (p-update e1 i) (= e1 (alpha e2 i)))))
                  (and (scan e1) (update e2) (exists ((i PID)) (and (PRE (alpha e1 i) e2) (p-update e2 i))))))))

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
