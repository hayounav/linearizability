(declare-sort E)
 
; Type of the operation
(declare-fun inc (E) Bool)
(declare-fun dec (E) Bool)
(declare-fun successful (E) Bool)
 
; < is pre
(declare-fun pre (E E) Bool)
 
(assert 
  (forall ((e E))
          (xor (inc e) (dec e))))
 
; Antisimetric
(assert 
  (forall ((e E)) (not (pre e e))))
 
; Transitive  
(assert 
  (forall ((e E) (y E) (z E))
          (=> (and (pre e y) (pre y z)) (pre e z))))
 
; Extra condition (to simulate intervals)
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
 
 
(declare-fun k (E) Int)
 
; k(i) = #{inc operations before i} 
(assert 
  (forall ((i E))
          (=> (and (inc i) (forall ((i2 E)) (=> (and (inc i2) (not (= i2 i))) (pre i i2))))
              (= (k i) 0))))
 
(assert 
  (forall ((i1 E) (i2 E))
          (=> (and (inc i1) (inc i2) (not (= i1 i2))
                   (not (exists ((i3 E)) (and (inc i3) (pre i1 i3) (pre i3 i2)))))
              (= (k i2) (+ (k i1) 1)))))
 
; k(d) = #{successfull dec operations before d}
(assert 
  (forall ((d E))
          (=> (and (dec d) (forall ((d2 E)) (=> (and (dec d2) (not (= d2 d))) (pre d d2))))
              (= (k d) 0))))
 
(assert 
  (forall ((d1 E) (d2 E))
          (=> (and (dec d1) (dec d2) (not (= d1 d2))
                   (not (exists ((d3 E)) (and (dec d3) (pre d1 d3) (pre d3 d2)))))
              (=(k d2) (ite (successful d1) (+ (k d1) 1) (k d1))))))
 
 
; Properties
(assert
  (forall ((d E) (i E))
          (=> (and (dec d) (inc i) (= (k i) (k d)) (pre d i))
              (not (successful d)))))
 
(assert
  (forall ((d E) (i E))
          (=> (and (dec d) (inc i) (= (k i) (k d)) (pre i d))
              (successful d))))
 
; Full triangle is PRE		  
(declare-fun PRE (E E) Bool)
 
(assert 
  (forall ((e1 E) (e2 E)) 
          (= (PRE e1 e2) 
             (or (pre e1 e2)
                 (and (inc e1) (dec e2) (successful e2) (= (k e1) (k e2)))
                 (and (dec e1) (inc e2) (not(successful e1)) (= (k e2) (k e1)))))))
 
 
(assert 
  (exists ((a1 E) (a2 E) (a3 E))
          (and (or (PRE a1 a2) (= a1 a2))
               (or (PRE a2 a3) (= a2 a3))
               (PRE a3 a1))))  
 
 
 
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
