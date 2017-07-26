(**************************************************************************)
(*                                                                        *)
(*  This file is part of TrustInSoft Kernel.                              *)
(*                                                                        *)
(*  TrustInSoft Kernel is a fork of Frama-C. All the differences are:     *)
(*    Copyright (C) 2016-2017 TrustInSoft                                 *)
(*                                                                        *)
(*  TrustInSoft Kernel is released under GPLv2                            *)
(*                                                                        *)
(**************************************************************************)

(**************************************************************************)
(*                                                                        *)
(*  This file is part of WP plug-in of Frama-C.                           *)
(*                                                                        *)
(*  Copyright (C) 2007-2015                                               *)
(*    CEA (Commissariat a l'energie atomique et aux energies              *)
(*         alternatives)                                                  *)
(*                                                                        *)
(*  you can redistribute it and/or modify it under the terms of the GNU   *)
(*  Lesser General Public License as published by the Free Software       *)
(*  Foundation, version 2.1.                                              *)
(*                                                                        *)
(*  It is distributed in the hope that it will be useful,                 *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *)
(*  GNU Lesser General Public License for more details.                   *)
(*                                                                        *)
(*  See the GNU Lesser General Public License version 2.1                 *)
(*  for more details (enclosed in the file licenses/LGPLv2.1).            *)
(*                                                                        *)
(**************************************************************************)

(* This file is generated by Why3's Coq-realize driver *)
(* Beware! Only edit allowed sections below    *)
Require Import BuiltIn.
Require BuiltIn.
Require bool.Bool.
Require int.Int.
Require int.Abs.
Require int.ComputerDivision.
Require real.Real.
Require real.RealInfix.
Require real.FromInt.

(* Why3 goal *)
Definition match_bool: forall {a:Type} {a_WT:WhyType a}, bool -> a -> a -> a.
exact (fun _ _ b x y => if b then x else y).
Defined.

(* Why3 goal *)
Lemma match_bool1 : forall {a:Type} {a_WT:WhyType a}, forall (p:bool) (x:a)
  (y:a), ((p = true) /\ ((match_bool p x y) = x)) \/ ((p = false) /\
  ((match_bool p x y) = y)).
Proof.
  intros a a_WT p x y.
  destruct p; intuition.
Qed.

(* Why3 goal *)
Definition eqb: forall {a:Type} {a_WT:WhyType a}, a -> a -> bool.
exact (fun a a_WT x y => if why_decidable_eq x y then true else false).
Defined.

(* Why3 goal *)
Lemma eqb1 : forall {a:Type} {a_WT:WhyType a}, forall (x:a) (y:a), ((eqb x
  y) = true) <-> (x = y).
Proof.
  intros a a_WT x y.
  destruct a_WT.
  compute;destruct (why_decidable_eq x y);intuition discriminate.
Qed.

(* Why3 goal *)
Lemma eqb_false : forall {a:Type} {a_WT:WhyType a}, forall (x:a) (y:a),
  ((eqb x y) = false) <-> ~ (x = y).
Proof.
  intros a a_WT x y.
  destruct a_WT.
  compute;destruct (why_decidable_eq x y);intuition discriminate.
Qed.

(* Why3 goal *)
Definition neqb: forall {a:Type} {a_WT:WhyType a}, a -> a -> bool.
exact (fun a a_WT x y => if why_decidable_eq x y then false else true).
Defined.

(* Why3 goal *)
Lemma neqb1 : forall {a:Type} {a_WT:WhyType a}, forall (x:a) (y:a), ((neqb x
  y) = true) <-> ~ (x = y).
Proof.
  intros a a_WT x y.
  destruct a_WT.
  compute;destruct (why_decidable_eq x y);intuition discriminate.
Qed.

(* Why3 goal *)
Definition zlt: Z -> Z -> bool.
exact(Zlt_bool).
Defined.

(* Why3 goal *)
Definition zleq: Z -> Z -> bool.
exact(Zle_bool).
Defined.

(* Why3 goal *)
Lemma zlt1 : forall (x:Z) (y:Z), ((zlt x y) = true) <-> (x < y)%Z.
Proof.
  intros x y.
  assert (T:= Zlt_is_lt_bool x y).
  tauto.
Qed.

(* Why3 goal *)
Lemma zleq1 : forall (x:Z) (y:Z), ((zleq x y) = true) <-> (x <= y)%Z.
Proof.
  intros x y.
  assert (T:= Zle_is_le_bool x y).
  tauto.
Qed.

(* Why3 goal *)
Definition rlt: R -> R -> bool.
exact (fun x y => if Rlt_dec x y then true else false).
Defined.

(* Why3 goal *)
Definition rleq: R -> R -> bool.
exact (fun x y => if Rle_dec x y then true else false).
Defined.

(* Why3 goal *)
Lemma rlt1 : forall (x:R) (y:R), ((rlt x y) = true) <-> (x < y)%R.
Proof.
  intros x y.
  compute;destruct (Rlt_dec x y); intuition discriminate.
Qed.

(* Why3 goal *)
Lemma rleq1 : forall (x:R) (y:R), ((rleq x y) = true) <-> (x <= y)%R.
Proof.
  intros x y.
  compute;destruct (Rle_dec x y);intuition;discriminate.
Qed.

(* Why3 goal *)
Definition truncate: R -> Z.
Admitted.

(* Why3 assumption *)
Definition real_of_int (x:Z): R := (Reals.Raxioms.IZR x).

(* Why3 goal *)
Lemma truncate_of_int : forall (x:Z), ((truncate (real_of_int x)) = x).
Admitted.

(* Why3 comment *)
(* pdiv is replaced with (ZArith.BinInt.Z.quot x x1) by the coq driver *)

(* Why3 comment *)
(* pmod is replaced with (ZArith.BinInt.Z.rem x x1) by the coq driver *)

(* Why3 goal *)
Lemma c_euclidian : forall (n:Z) (d:Z), (~ (d = 0%Z)) ->
  (n = (((ZArith.BinInt.Z.quot n d) * d)%Z + (ZArith.BinInt.Z.rem n d))%Z).
Proof.
  intros n d.
  intros H.
  rewrite Int.Comm1.
  exact (ComputerDivision.Div_mod n d H).
Qed.

Lemma lt_is_not_eqb1: forall x y, (x < y -> Z.eqb x y = false)%Z.
Proof.
  intros.
  rewrite Z.eqb_compare.
  rewrite H.
  reflexivity.
Qed.

Lemma lt_is_not_eqb2: forall x y, (y < x -> Z.eqb x y = false)%Z.
Proof.
  intros.
  rewrite Z.eqb_compare.
  rewrite (Z.lt_gt _ _ H).
  reflexivity.
Qed.


(* Why3 goal *)
Lemma cdiv_cases : forall (n:Z) (d:Z), ((0%Z <= n)%Z -> ((0%Z < d)%Z ->
  ((ZArith.BinInt.Z.quot n d) = (ZArith.BinInt.Z.quot n d)))) /\
  (((n <= 0%Z)%Z -> ((0%Z < d)%Z ->
  ((ZArith.BinInt.Z.quot n d) = (-(ZArith.BinInt.Z.quot (-n)%Z d))%Z))) /\
  (((0%Z <= n)%Z -> ((d < 0%Z)%Z ->
  ((ZArith.BinInt.Z.quot n d) = (-(ZArith.BinInt.Z.quot n (-d)%Z))%Z))) /\
  ((n <= 0%Z)%Z -> ((d < 0%Z)%Z ->
  ((ZArith.BinInt.Z.quot n d) = (ZArith.BinInt.Z.quot (-n)%Z (-d)%Z)))))).
Proof.
  intros n d.
  rewrite Zquot.Zquot_opp_l.
  rewrite Zquot.Zquot_opp_r.
  rewrite Zquot.Zquot_opp_l.
  rewrite Zquot.Zquot_opp_r.
  rewrite Z.opp_involutive.
  assert (lem1 := lt_is_not_eqb1 d 0).
  assert (lem2 := lt_is_not_eqb2 d 0).
  intuition (rewrite H1;reflexivity).
Qed.

(* Why3 goal *)
Lemma cmod_cases : forall (n:Z) (d:Z), ((0%Z <= n)%Z -> ((0%Z < d)%Z ->
  ((ZArith.BinInt.Z.rem n d) = (ZArith.BinInt.Z.rem n d)))) /\
  (((n <= 0%Z)%Z -> ((0%Z < d)%Z ->
  ((ZArith.BinInt.Z.rem n d) = (-(ZArith.BinInt.Z.rem (-n)%Z d))%Z))) /\
  (((0%Z <= n)%Z -> ((d < 0%Z)%Z ->
  ((ZArith.BinInt.Z.rem n d) = (ZArith.BinInt.Z.rem n (-d)%Z)))) /\
  ((n <= 0%Z)%Z -> ((d < 0%Z)%Z ->
  ((ZArith.BinInt.Z.rem n d) = (-(ZArith.BinInt.Z.rem (-n)%Z (-d)%Z))%Z))))).
Proof.
  intros n d.
  rewrite Zquot.Zrem_opp_l.
  rewrite Zquot.Zrem_opp_r.
  rewrite Zquot.Zrem_opp_l.
  rewrite Zquot.Zrem_opp_r.
  rewrite Z.opp_involutive.
  assert (lem1 := lt_is_not_eqb1 d 0).
  assert (lem2 := lt_is_not_eqb2 d 0).
  intuition (rewrite H1;reflexivity).
Qed.

(* Why3 goal *)
Lemma cmod_remainder : forall (n:Z) (d:Z), ((0%Z <= n)%Z -> ((0%Z < d)%Z ->
  ((0%Z <= (ZArith.BinInt.Z.rem n d))%Z /\
  ((ZArith.BinInt.Z.rem n d) < d)%Z))) /\ (((n <= 0%Z)%Z -> ((0%Z < d)%Z ->
  (((-d)%Z < (ZArith.BinInt.Z.rem n d))%Z /\
  ((ZArith.BinInt.Z.rem n d) <= 0%Z)%Z))) /\ (((0%Z <= n)%Z ->
  ((d < 0%Z)%Z -> ((0%Z <= (ZArith.BinInt.Z.rem n d))%Z /\
  ((ZArith.BinInt.Z.rem n d) < (-d)%Z)%Z))) /\ ((n <= 0%Z)%Z ->
  ((d < 0%Z)%Z -> ((d < (ZArith.BinInt.Z.rem n d))%Z /\
  ((ZArith.BinInt.Z.rem n d) <= 0%Z)%Z))))).
Proof.
  intros n d.
  (split;[|split;[|split]]);intros;
  [exact (Zquot.Zrem_lt_pos_pos _ _ H H0)|
   exact (Zquot.Zrem_lt_neg_pos _ _ H H0)|
   exact (Zquot.Zrem_lt_pos_neg _ _ H H0)|
   exact (Zquot.Zrem_lt_neg_neg _ _ H H0)].
Qed.

(* Why3 goal *)
Lemma cdiv_neutral : forall (a:Z), ((ZArith.BinInt.Z.quot a 1%Z) = a).
Proof.
  intro a.
  exact (Z.quot_1_r a).
Qed.

(* Why3 goal *)
Lemma cdiv_inv : forall (a:Z), (~ (a = 0%Z)) ->
  ((ZArith.BinInt.Z.quot a a) = 1%Z).
Proof.
  intros a h1.
  exact (Z.quot_same a h1).
Qed.
