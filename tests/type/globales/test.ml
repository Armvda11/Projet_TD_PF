open Rat
open Compilateur
open Exceptions

exception ErreurNonDetectee

(****************************************)
(** Chemin d'accès aux fichiers de test *)
(****************************************)

let pathFichiersRat = "../../../../../tests/type/globales/fichiersRat/"

(**********)
(*  TESTS *)
(**********)

let%test_unit "testAffectation1" = 
  let _ = compiler (pathFichiersRat^"testAffectation1.rat") in ()

let%test_unit "testAffectation2" = 
  try
    let _ = compiler (pathFichiersRat^"testAffectation2.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Bool,Int) -> ()

let%test_unit "testAffectation3" = 
  try
    let _ = compiler (pathFichiersRat^"testAffectation3.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Rat,Bool) -> ()

let%test_unit "testAffectation4" = 
  try
    let _ = compiler (pathFichiersRat^"testAffectation4.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Int,Rat) -> ()

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
  | TypeInattendu(Int,Bool) -> ()

let%test_unit "testAcces5" = 
  try
    let _ = compiler (pathFichiersRat^"testAcces5.rat")
    in raise ErreurNonDetectee
  with
  | TypeBinaireInattendu(_,Int,Bool) -> ()

let%test_unit "testAcces6" = 
  try
    let _ = compiler (pathFichiersRat^"testAcces6.rat")
    in raise ErreurNonDetectee
  with
  | TypeInattendu(Int,Bool) -> ()

let%test_unit "testAcces7" = 
  let _ = compiler (pathFichiersRat^"testAcces7.rat") in ()