open Rat
open Compilateur
open Exceptions

exception ErreurNonDetectee

(****************************************)
(** Chemin d'accès aux fichiers de test *)
(****************************************)

let pathFichiersRat = "../../../../../tests/type/pointeurs/fichiersRat/"

(**********)
(*  TESTS *)
(**********)

let%test_unit "testNull3" = 
  try
    let _ = compiler (pathFichiersRat^"testNull3.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Pointeur(Bool),Pointeur(Rat)) -> ()

  let%test_unit "testAffectation1" = 
  let _ = compiler (pathFichiersRat^"testAffectation1.rat") in ()

let%test_unit "testAffectation2" = 
  let _ = compiler (pathFichiersRat^"testAffectation2.rat") in ()

let%test_unit "testAffectation3" = 
  try
    let _ = compiler (pathFichiersRat^"testAffectation3.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Bool,Pointeur(Int)) -> ()

let%test_unit "testAffectation4" = 
  try
    let _ = compiler (pathFichiersRat^"testAffectation4.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Int,Pointeur(Bool)) -> ()

let%test_unit "testAffectation5" = 
  try
    let _ = compiler (pathFichiersRat^"testAffectation5.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Int,Pointeur(Int)) -> ()

let%test_unit "testAffectation6" = 
  try
    let _ = compiler (pathFichiersRat^"testAffectation6.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Pointeur(Int),Pointeur(Rat)) -> ()

let%test_unit "testAffectation7" = 
  try
    let _ = compiler (pathFichiersRat^"testAffectation7.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Pointeur(Pointeur(Int)),Pointeur(Int)) -> ()

let%test_unit "testNull1" = 
  let _ = compiler (pathFichiersRat^"testNull1.rat") in ()

let%test_unit "testNull2" = 
  let _ = compiler (pathFichiersRat^"testNull2.rat") in ()

let%test_unit "testDeref1" = 
  let _ = compiler (pathFichiersRat^"testDeref1.rat") in ()

let%test_unit "testDeref2" = 
  try
    let _ = compiler (pathFichiersRat^"testDeref2.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Bool,Int) -> ()

let%test_unit "testDeref3" = 
  let _ = compiler (pathFichiersRat^"testDeref3.rat") in ()

let%test_unit "testDeref4" = 
  let _ = compiler (pathFichiersRat^"testDeref4.rat") in ()

let%test_unit "testDeref5" = 
  let _ = compiler (pathFichiersRat^"testDeref5.rat") in ()

let%test_unit "testAcces1" = 
  let _ = compiler (pathFichiersRat^"testAcces1.rat") in ()

let%test_unit "testAcces2" = 
  let _ = compiler (pathFichiersRat^"testAcces2.rat") in ()

let%test_unit "testAcces3" = 
  let _ = compiler (pathFichiersRat^"testAcces3.rat") in ()

let%test_unit "testAcces4" = 
  try
    let _ = compiler (pathFichiersRat^"testAcces4.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Pointeur(Int),Pointeur(Pointeur(Bool))) -> ()

let%test_unit "testAcces5" = 
  try
    let _ = compiler (pathFichiersRat^"testAcces5.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Pointeur(Int),Pointeur(Bool)) -> ()

let%test_unit "testOp1" = 
  try
    let _ = compiler (pathFichiersRat^"testOp1.rat")
    in raise ErreurNonDetectee
  with
  | TypeBinaireInattendu(_,Pointeur(Bool),Pointeur(Int)) -> ()

let%test_unit "testOp2" = 
  try
    let _ = compiler (pathFichiersRat^"testOp2.rat")
    in raise ErreurNonDetectee
  with
  | TypeBinaireInattendu(_,Pointeur(Int),Pointeur(Int)) -> ()

let%test_unit "testOp3" = 
  try
    let _ = compiler (pathFichiersRat^"testOp3.rat")
    in raise ErreurNonDetectee
  with
  | TypeBinaireInattendu(_,Pointeur(Rat),Pointeur(Rat)) -> ()

let%test_unit "testOp4" = 
  try
    let _ = compiler (pathFichiersRat^"testOp4.rat")
    in raise ErreurNonDetectee
  with
  | TypeBinaireInattendu(_,Pointeur(Bool),Pointeur(Rat)) -> ()

let%test_unit "testOp5" = 
  try
    let _ = compiler (pathFichiersRat^"testOp5.rat")
    in raise ErreurNonDetectee
  with
  | TypeBinaireInattendu(_,Pointeur(Rat),Pointeur(Int)) -> ()

let%test_unit "testOp6" = 
  try
    let _ = compiler (pathFichiersRat^"testOp6.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Pointeur(Rat),Rat) -> ()

let%test_unit "testOp7" = 
  try
    let _ = compiler (pathFichiersRat^"testOp7.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Pointeur(Rat),Rat) -> ()

let%test_unit "testOp8" = 
  try
    let _ = compiler (pathFichiersRat^"testOp8.rat")
    in raise ErreurNonDetectee
  with
  | TypeBinaireInattendu(_,Pointeur(Int),Pointeur(Int)) -> ()

let%test_unit "testOp9" = 
  let _ = compiler (pathFichiersRat^"testOp9.rat") in ()

let%test_unit "testOp10" = 
  try
    let _ = compiler (pathFichiersRat^"testOp10.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Pointeur(Int),Int) -> ()














