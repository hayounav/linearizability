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
;; *** try to avoid using this if possible!!! ***
(declare-sort V)

;; update event
(declare-fun update (E) bool)

;; scan event
(declare-fun scan (E) bool)

;; < is pre
(declare-fun pre (E E) Bool)
 
;; every event is either an update event or a scan event
(assert 
  (forall ((e E))
          (xor (inc e) (dec e))))
 
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


