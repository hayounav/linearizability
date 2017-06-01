; E is the set of events
(declare-sort E)
 
; Type of the operation
(declare-fun inc (E) Bool)
(declare-fun dec (E) Bool)
(declare-fun successful (E) Bool)
 
 
; < is pre
(declare-fun pre (E E) Bool)
 
; every event is either a inc event
;                    or a dec event
(assert 
  (forall ((e E))
          (xor (inc e) (dec e))))
 
; ; pre is Antisimetric
(assert 
  (forall ((e E)) (not (pre e e))))
 
; pre is Transitive  
(assert 
  (forall ((e E) (y E) (z E))
          (=> (and (pre e y) (pre y z)) (pre e z))))
 
; Extra condition (to simulate intervals = Russel & Wienner)
(assert 
  (forall ((a E) (b E) (c E) (d E))
          (=> (and (pre a b) (pre c d) (not(pre c b))) (pre a d))))
 
 
; Every two inc operations are comparable in < 
(assert 
  (forall ((i1 E) (i2 E))
          (=> (and (inc i1) (inc i2)) (or (= i1 i2) (pre i1 i2) (pre i2 i1)))))
 
 
; Every two dec operations are comparable in <
(assert 
  (forall ((d1 E) (d2 E))
          (=> (and (dec d1) (dec d2)) (or (= d1 d2) (pre d1 d2) (pre d2 d1)))))
 
 
 
; Axioms for our alpha function
(declare-fun alpha (E) E)
 
; alpha maps dec to inc
(assert 
  (forall ((e E)) 
          (=> (dec e) (inc (alpha e)))))
 
; no "holes" on alpha
(assert 
  (forall ((i E) (d E)) 
          (=> (and (inc i) (dec d) (successful d))
              (=> (pre i (alpha d))
                  (exists ((d2 E)) (and (dec d2) (successful d2) (= (alpha d2) i)))))))
 
; alpha is weakly monotonic
(assert
  (forall ((d1 E) (d2 E))
          (=> (and (dec d1) (dec d2))
              (=> (pre d1 d2)
                  (or (pre (alpha d1) (alpha d2))  (= (alpha d1)(alpha d2)))))))
 
; alpha "jumps forward" after a successful dec
(assert 
  (forall ((d1 E) (d2 E)) 
          (=> (and (dec d1) (dec d2) (successful d1))
              (=> (pre d1 d2) (pre (alpha d1) (alpha d2))))))
 
; if D fails, alpha(D)=alpha(successor(D))
(assert 
  (forall ((d1 E) (d2 E)) 
          (=> (and (dec d1) (dec d2) 
                   (not (successful d1)) 
                   (not( exists ((d3 E)) (and (dec d3) (pre d1 d3) (pre d3 d2)))))
              (= (alpha d1)(alpha d2)))))
 
 
; Properties (implementation assumptions)
(assert
  (forall ((d E))
          (=> (and (dec d) (pre d (alpha d)))
              (not (successful d)))))
 
(assert
  (forall ((d E)) 
          (=> (and (dec d) (pre (alpha d) d))
              (successful d))))
 
; Full triangle is PRE		  
(declare-fun PRE (E E) Bool)
 
(assert 
  (forall ((e1 E) (e2 E)) 
          (= (PRE e1 e2) 
             (or (pre e1 e2)
                 (and (inc e1) (dec e2) (successful e2) (= e1 (alpha e2)))
                 (and (dec e1) (inc e2) (not(successful e1)) (= e2 (alpha e1)))))))
 
 
; Every path of length 3 can be shorten
(assert 
  (not (forall ((x E) (y E))
               (=> (exists ((a1 E) (a2 E))  (and (PRE x a1) (PRE a1 a2) (PRE a2 y)))
                   (exists ((b1 E)) (and (PRE x b1) (PRE b1 y)))))))
 
 
; (assert 
;   (exists ((a1 E) (a2 E) (a3 E) (a4 E) (a5 E) (a6 E))
;           (and (or (PRE a1 a2) (= a1 a2))
;                (or (PRE a2 a3) (= a2 a3))
;                (or (PRE a3 a4) (= a3 a4))
;                (or (PRE a4 a5) (= a4 a5))
;                (or (PRE a5 a6) (= a5 a6))
;                (PRE a6 a1))))  
 
(check-sat)
(get-model)
