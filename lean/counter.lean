namespace counter

--------------------------------------------
-- generic linearizability type definitions
--------------------------------------------
variables (E V PID : Type)
variable α : E → E
variable pre : E → E → bool
variable PRE : E → E → bool
variable in_p : E → PID → bool
variable val : E → V

--------------------------------------------
-- counter-specific type definitions
--------------------------------------------
variable inc : E → bool
variable dec : E → bool

--------------------------------------------
-- assertions
--------------------------------------------

end counter
