;; E is the set of events
(declare-sort E)
 
;; Type of the operation
(declare-fun inc (E) Bool)
(declare-fun dec (E) Bool)
(declare-fun successful (E) Bool)
 
 
;; < is pre
(declare-fun pre (E E) Bool)
 
;; every event is either a inc event or a dec event
(assert 
  (forall ((e E))
          (xor (inc e) (dec e))))
 
;; pre is Antisimetric
(assert 
  (forall ((e E)) (not (pre e e))))
 
;; pre is Transitive  
(assert 
  (forall ((e E) (y E) (z E))
          (=> (and (pre e y) (pre y z)) (pre e z))))
 
;; Extra condition (to simulate intervals = Russel & Wienner)
(assert 
  (forall ((a E) (b E) (c E) (d E))
          (=> (and (pre a b) (pre c d) (not(pre c b))) (pre a d))))
  
;; Every two dec operations are comparable in <
(assert 
  (forall ((d1 E) (d2 E))
          (=> (and (dec d1) (dec d2)) (or (= d1 d2) (pre d1 d2) (pre d2 d1)))))
 
 
 
;; Axioms for our alpha function
(declare-fun alpha (E) E)
 
;; alpha maps dec to inc
(assert 
  (forall ((e E)) 
          (=> (dec e) (inc (alpha e)))))

;; alpha doesnt map two successful decreases to the same increase
;; *** it seems to me that this should be required for things to work ***
;; (assert
;;  (forall ((d1 E) (d2 E))
;; 		 (=> (and (dec d1) (dec d2))
;; 			 (or (not (= (alpha d1) (alpha d2)))
;; 				 (not (and (successful d1) (successful d2)))))))
 
;; no "holes" on alpha
(assert 
  (forall ((i E) (d E)) 
          (=> (and (inc i) (dec d) (successful d))
              (=> (pre i (alpha d))
                  (exists ((d2 E)) (and (dec d2) (successful d2) (= (alpha d2) i)))))))
 
;; alpha is weakly monotonic
;; (assert
;;   (forall ((d1 E) (d2 E))
;;           (=> (and (dec d1) (dec d2))
;;               (=> (pre d1 d2)
;;                   (or (pre (alpha d1) (alpha d2))  (= (alpha d1)(alpha d2)))))))
 
;; alpha "jumps forward" after a successful dec
(assert 
  (forall ((d1 E) (d2 E)) 
          (=> (and (dec d1) (dec d2) (successful d1))
              (=> (pre d1 d2) (pre (alpha d1) (alpha d2))))))
 
;; if D fails, alpha(D)=alpha(successor(D))
(assert 
  (forall ((d1 E) (d2 E)) 
          (=> (and (dec d1) (dec d2) 
                   (not (successful d1)) 
                   (not (exists ((d3 E)) (and (dec d3) (pre d1 d3) (pre d3 d2)))))
              (= (alpha d1)(alpha d2)))))
 
 
;; Properties (implementation assumptions)
(assert
  (forall ((d E))
          (=> (and (dec d) (pre d (alpha d)))
              (not (successful d)))))
 
(assert
  (forall ((d E)) 
          (=> (and (dec d) (pre (alpha d) d))
              (successful d))))
 
;; Full triangle is PRE		  
(declare-fun PRE (E E) Bool)
 
(assert 
  (forall ((e1 E) (e2 E)) 
          (= (PRE e1 e2) 
             (or (pre e1 e2)
                 (and (inc e1) (dec e2) (successful e2) (= e1 (alpha e2)))
                 (and (dec e1) (inc e2) (not (successful e1)) (= e2 (alpha e1)))))))
 
 
;; ensure the correctness of the problem definition
(check-sat)

;--------------------------------------------------------------------------------------
; The following two assertions are expected to be tested seperatley. 
; We want to see that uncommenting each of them seperatly gives an unsat 
; result and without both the model is satisfiable
; This is implemented using the push and pop mechanisms.
;--------------------------------------------------------------------------------------

(push)
(assert (not 
    (forall ((b E) (e E)) 
        (=> 
            ; Path of length 4 from b to e
            (exists ((e1 E) (e2 E)) (and (PRE b e1) (PRE e1 e2) (PRE e2 e)))

            ; Path of length <4 from b to e
            (exists ((e1 E)) (and (or (= b e1) (PRE b e1)) (or (= e1 e) (PRE e1 e))))))))

(check-sat)
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
