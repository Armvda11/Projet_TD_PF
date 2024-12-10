open Rat
open Compilateur
open Exceptions

exception ErreurNonDetectee

(****************************************)
(** Chemin d'accès aux fichiers de test *)
(****************************************)

let pathFichiersRat = "../../../../../tests/gestion_id/globales/fichiersRat/"

(**********)
(*  TESTS *)
(**********)

let%test_unit "testDeclaration1" = 
  let _ = compiler (pathFichiersRat^"testDeclaration1.rat") in ()

let%test_unit "testDeclaration2" = 
  let _ = compiler (pathFichiersRat^"testDeclaration2.rat") in ()

let%test_unit "testAcces1" = 
  let _ = compiler (pathFichiersRat^"testAcces1.rat") in ()

let%test_unit "testAcces2" = 
  let _ = compiler (pathFichiersRat^"testAcces2.rat") in ()

let%test_unit "testDoubleDecla1" = 
  try
    let _ = compiler (pathFichiersRat^"testDoubleDecla1.rat")
    in raise ErreurNonDetectee
  with
  | DoubleDeclaration("x") -> ()

let%test_unit "testDoubleDecla2" = 
  try
    let _ = compiler (pathFichiersRat^"testDoubleDecla2.rat")
    in raise ErreurNonDetectee
  with
  | DoubleDeclaration("x") -> ()

let%test_unit "testDoubleDecla3" = 
  try
      let _ = compiler (pathFichiersRat^"testDoubleDecla3.rat")
      in raise ErreurNonDetectee
    with
    | DoubleDeclaration("x") -> ()

let%test_unit "testDoubleDecla4" = 
  try
    let _ = compiler (pathFichiersRat^"testDoubleDecla4.rat")
    in raise ErreurNonDetectee
  with
  | DoubleDeclaration("x") -> ()