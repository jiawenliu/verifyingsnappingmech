 (**
   This file contains the coq implementation of the snapping mechanism.
 **)
From Coq
     Require Import QArith.QArith QArith.Qminmax QArith.Qabs QArith.Qreals
     micromega.Psatz Reals.Reals
     Strings.Ascii Strings.BinaryString.

From Snapv
     Require Import 
     Expressions Command ExpressionTransitions
     CommandSemantics apRHL Environments.

Require Import Coq.Strings.Ascii Coq.Strings.BinaryString.

From mathcomp Require Import ssreflect ssrfun ssrbool eqtype choice seq.

From extructures Require Import ord fset fmap ffun.


(** Error bound validator **)

Open Scope R_scope.
Open Scope aprHoare_scope.

Definition Snap (a: R) (Lam: R) (B: R) (eps: R) :=
	SEQ (UNIF1 (Var 1)) 
	(SEQ (UNIF2 (Var 2)) 
		(ASGN (Var 3) 
			(Binop Clamp (Const B) 
				(Binop Round (Const Lam)
					(Binop Plus (Const a)
						(Binop Mult (Const eps)
							(Binop Mult (Var 2)
								(Unop Ln (Var 1)))))))))
.

Definition eta := 0.0000000005%R.
Lemma SnapDP' :
  forall a a' Lam B eps: R,
    (Rplus a (Ropp a')) = 1 ->
    hoare_rule ATrue (Snap a Lam B eps) (Rmult eps (Rplus 1 (Rmult 24%R (Rmult B eta)))) (Snap a' Lam B eps)
               (fun (pm : (state * state)) =>
                    match pm with
                    | (m1, m2) => match (m1 (of_nat 3)),(m2 (of_nat 3)) with
                                  | (v1, er1),(v2, er2) =>
                                      v1 = v2
                                  end
                    end)
.

Proof.
  intros.
  unfold Snap.
(* apply H_Seq with
      (P := ATrue)  (c1 := (UNIF1 (Var 1)))
      (c2 := (SEQ (UNIF2 (Var 2))
                  (ASGN (Var 3)
                        (Binop Clamp (Const B)
                               (Binop Round (Const Lam)
                                      (Binop Plus (Const a)
                                             (Binop Mult (Const eps)
                                                    (Binop Mult (Var 2)
                                                           (Unop Ln (Var 1))))))))))
      (r1 := (Rmult eps (Rplus 1 (Rmult 24%R (Rmult B eta))))) (r2 := (0%R))
      (d1 := (UNIF1 (Var 1)))
      (d2 := (SEQ (UNIF2 (Var 2))
                  (ASGN (Var 3)
                        (Binop Clamp (Const B)
                               (Binop Round (Const Lam)
                                      (Binop Plus (Const a')
                                             (Binop Mult (Const eps)
                                                    (Binop Mult (Var 2)
                                                           (Unop Ln (Var 1))))))))))
      (R0 :=  (fun pm : state * state =>
                 let (m1, m2) := pm in
                 let (v1, _) := m1 (of_nat 3) in
                 let (v2, _) := m2 (of_nat 3) in v1 = v2)
      ).

 *)

Admitted.

Lemma SnapDP:
  forall a a' Lam B eps: R,
    (Rplus a (Ropp a')) = 1 ->
    aprHore_judgement ATrue (Snap a Lam B eps) (Rmult eps (Rplus 1 (Rmult 24%R (Rmult B eta)))) (Snap a' Lam B eps)
               (fun (pm : (state * state)) =>
                    let (m1, m2) := pm in
                    let (v1, _) := m1 (of_nat 3) in let (v2, _) := m2 (of_nat 3) in v1 = v2)
.

Proof.
  intros.
apply aprHore_seq with (Q := fun pm : ffun (fun=> (0, (0, 0))) * ffun (fun=> (0, (0, 0))) =>
    let (m1, m2) := pm in
    let (v1, _) := m1 (of_nat 3) in let (v2, _) := m2 (of_nat 3) in v1 = v2)
                       (r1 := (Rmult eps (Rplus 1 (Rmult 24%R (Rmult B eta)))))
                       (r2 := 0%R)
                       (R0 := (fun (pm : (state * state)) =>
                                  let (m1, m2) := pm in
                                  let (v1, _) := m1 (of_nat 1) in
                                  let (v2, _) := m2 (of_nat 1) in
                                  forall l r,
                                    Rlt l v1 -> Rlt v1 r -> Rlt (Rmult (Rmult eps (Rplus 1 (Rmult 24%R (Rmult B eta)))) l) v2 -> Rlt v2 (Rmult (Rmult eps (Rplus 1 (Rmult 24%R (Rmult B eta)))) r))).
apply aprHore_unifP.
Admitted.


Close Scope aprHoare_scope.
Close Scope R_scope.