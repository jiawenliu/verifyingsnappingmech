Require Import Coq.Bool.Bool.
Require Import Coq.Arith.Arith.
Require Import Coq.Arith.EqNat.
Require Import Coq.omega.Omega.
Require Import Coq.Lists.List.
Require Import Decimal Ascii String.
Require Import Coq.Strings.Ascii Coq.Strings.BinaryString.
Import ListNotations.

From Coq
     Require Import Reals.Reals.

From Snapv.Infra
     Require Import RealRationalProps RationalSimps.

From Snapv
    Require Export Expressions.


From Snapv Require Import Maps.

(**
  Define the Transition From the real computation to the Floating Point Computation with Floating point Relative Error
**)
Definition state := total_map (R * (R * R)).

Open Scope R_scope.

Inductive ptbdir : Type := Down | Up.

Definition perturb (e: R) (delta: R) (dir: ptbdir) :  R :=
  match dir with
  (* The Real-type has no error *)
  |Down =>  ( e * (1 + delta))
  (* Fixed-point numbers have an absolute error *)
  |Up => ( e / (1 + delta))
  end.

Hint Unfold perturb.

(**
Define expression evaluation relation parametric by an "error" epsilon.
The result value exprresses float computations according to the IEEE standard,
using a perturbation of the real valued computation by (1 + delta), where
|delta| <= machine epsilon.
**)
Definition trs_env := state.

Definition fl (r : R) := r
  .


Definition err : Type :=  (R * R).
(*TO RENAME*)
Inductive trans_expr (E : trs_env) (delta : R)
  :(expr R) -> R * err -> Prop :=
| Var_load x v er1 er2:
    E (of_nat x) = (v, (er1, er2)) ->
    trans_expr E delta (Var R x) (v, (er1, er2))
| Const_lt_zero c:
    ~ (fl c = c) -> c < 0 ->
    trans_expr E delta  (Const REAL c) 
   (c, (perturb (c) delta Up, 
        perturb (c) delta Down))
| Const_gt_zero c :
    ~ fl c = c -> 0 <= c ->
    trans_expr E delta (Const REAL c) 
    (c, (perturb (c) delta Down, 
        perturb (c) delta Up))
| Const_eq c :
    fl c = c -> 
    trans_expr E delta (Const REAL c) 
    (c, (c, c))
| Unop_gt_zero e v op er1 er2:
    (evalUnop op v) > 0 -> 
    trans_expr E delta e (v, (er1, er2)) ->
    trans_expr E delta (Unop Neg e) 
    (fl (evalUnop Neg v), 
      (perturb (evalUnop op er1) delta Down, 
        perturb (evalUnop op er2) delta Up)) 
| Unop_lt_zero e v op er1 er2:
    (evalUnop op v) < 0 -> 
    trans_expr E delta e (v, (er1, er2)) ->
    trans_expr E delta (Unop Neg e) 
    (evalUnop op v, 
      (perturb (evalUnop op er1) delta Up, 
        perturb (evalUnop op er2) delta Down)) 

| Binop_PSRC_gt0 op e1 e2 v1 v2 er1_l er1_u er2_l er2_u v:
    (evalBinop op v1 v2) = v ->
    0 <= v ->
    trans_expr E delta e1 (v1, (er1_l, er1_u)) ->
    trans_expr E delta e2 (v2, (er2_l, er2_u)) ->
    ((op = Plus) \/ (op = Sub) \/ (op = Round) \/ (op = Clamp)) ->
    trans_expr E delta (Binop op e1 e2) 
    (v, 
      (perturb (evalBinop op er1_l er2_l) delta Down, 
        perturb (evalBinop op er1_u er2_u) delta Up)) 
| Binop_PSRC_lt0 op e1 e2 v1 v2 er1_l er1_u er2_l er2_u v:
    (evalBinop op v1 v2) = v ->
    v < 0 ->
    trans_expr E delta e1 (v1, (er1_l, er1_u)) ->
    trans_expr E delta e2 (v2, (er2_l, er2_u)) ->
    ((op = Plus) \/ (op = Sub) \/ (op = Round) \/ (op = Clamp)) ->
    trans_expr E delta (Binop op e1 e2) 
    (v, 
      (perturb (evalBinop op er1_l er2_l) delta Up, 
        perturb (evalBinop op er1_u er2_u) delta Down)) 
| Binop_MD_ltlt op e1 e2 v1 v2 er1_l er1_u er2_l er2_u v:
    (evalBinop op v1 v2) = v ->
    v1 < 0 /\ v2 < 0 ->
    trans_expr E delta e1 (v1, (er1_l, er1_u)) ->
    trans_expr E delta  e2 (v2, (er2_l, er2_u)) ->
    ((op = Mult) \/ (op = Div)) ->
    trans_expr E delta (Binop op e1 e2) 
    (v, 
      (perturb (evalBinop op er1_u er2_u) delta Down, 
        perturb (evalBinop op er1_l er2_l) delta Up))
| Binop_MD_gtgt op e1 e2 v1 v2 er1_l er1_u er2_l er2_u v:
    (evalBinop op v1 v2) = v ->
    0 <= v1 /\ 0 <= v2 ->
    trans_expr E delta e1 (v1, (er1_l, er1_u)) ->
    trans_expr E delta e2 (v2, (er2_l, er2_u)) ->
    ((op = Mult) \/ (op = Div)) ->
    trans_expr E delta (Binop op e1 e2) 
    (v, 
      (perturb (evalBinop op er1_l er2_l) delta Down, 
        perturb (evalBinop op er1_u er2_u) delta Up))
| Binop_MD_ltgt op e1 e2 v1 v2 er1_l er1_u er2_l er2_u v:
    (evalBinop op v1 v2) = v ->
    v1 < 0 /\ 0 <= v2 ->
    trans_expr E delta e1 (v1, (er1_l, er1_u)) ->
    trans_expr E delta e2 (v2, (er2_l, er2_u)) ->
    ((op = Mult) \/ (op = Div)) ->
    trans_expr E delta (Binop op e1 e2) 
    (v, 
      (perturb (evalBinop op er1_l er2_u) delta Up, 
        perturb (evalBinop op er1_u er2_l) delta Down)) 
| Binop_MD_gtlt op e1 e2 v1 v2 er1_l er1_u er2_l er2_u v:
    (evalBinop op v1 v2) = v ->
    0 <= v1 /\ v2 < 0 ->
    trans_expr E delta e1 (v1, (er1_l, er1_u)) ->
    trans_expr E delta e2 (v2, (er2_l, er2_u)) ->
    ((op = Mult) \/ (op = Div)) ->
    trans_expr E delta (Binop op e1 e2) 
    (v, 
      (perturb (evalBinop op er1_u er2_l) delta Up, 
        perturb (evalBinop op er1_l er2_u) delta Down))
.


Close Scope R_scope.

Hint Constructors trans_expr.

(** *)
(*   Show some simpler (more general) rule lemmata *)
(* **)

