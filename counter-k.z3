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
    (forall ((i1 E) (i2 E))
        (=> (and (inc i1) (inc i2) (pre i1 i2))
            (< (k i1) (k i2)))))

; k(d) = #{successfull dec operations before d}
(assert
    (forall ((d1 E) (d2 E))
        (=> (and (dec d1) (dec d2) (pre d1 d2))
            (or (not (successful d1)) (< (k d1) (k d2))))))

(assert
    (forall ((d1 E) (d2 E))
        (=> (and (dec d1) (dec d2) (pre d1 d2) (not (successful d1)))
            (=> (forall ((d3 E))
                (not (and (pre d1 d3) (pre d3 d2))) )
            (= (k d1) (k d2))))))

; Properties
(assert
    (forall ((d E) (i E))
        (=> (and (dec d) (inc i) (<= (k i) (k d)) (pre d i))
            (not (successful d)))))

(assert
    (forall ((d E) (i E))
        (=> (and (dec d) (inc i) (>= (k i) (k d)) (pre i d))
            (successful d))))

;PRE is the union of full triangle with <
(declare-fun PRE (E E) Bool)

; PRE is a refinement of pre based on the definition of the object (a counter)
(assert 
    (forall ((e1 E) (e2 E)) 
        (= (PRE e1 e2) 
            (or (pre e1 e2)

                ; A decrease is successfull if there are enough increases before it
                (and (inc e1) (dec e2) (successful e2) (= (k e1) (k e2)))

                ; A decrease is not successfull if there arent enough increases before it
                (and (dec e1) (inc e2) (not(successful e1)) (= (k e2) (k e1)))))))

;--------------------------------------------------------------------------------------
; The following two assertions are expected to be tested seperatley. 
; We want to see that uncommenting each of them seperatly gives an unsat 
; result and without both the model is satisfiable
; This is implemented using the push and pop mechanisms.
;--------------------------------------------------------------------------------------

(check-sat)

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
; No cycle of length <= 4
(assert 
  (exists ((e1 E) (e2 E) (e3 E) (e4 E))
          (and (or (PRE e1 e2) (= e1 e2))
               (or (PRE e2 e3) (= e2 e3))
               (or (PRE e3 e4) (= e3 e4))
               (PRE e4 e1))))  

(check-sat)
(pop)
