open Rat
open Compilateur
open Exceptions

exception ErreurNonDetectee

(****************************************)
(** Chemin d'accès aux fichiers de test *)
(****************************************)

let pathFichiersRat = "../../../../../tests/gestion_id/locales/fichiersRat/"

(**********)
(*  TESTS *)
(**********)
let%test_unit "testStatiqueSimple" = 
  let _ = compiler (pathFichiersRat^"testStatiqueSimple.rat") in ()

let%test_unit "testStatiqueSimple2" =
  let _ = compiler (pathFichiersRat^"testStatiqueSimple2.rat") in ()

let%test_unit "testStatiqueSimple3" =
  let _ = compiler (pathFichiersRat^"testStatiqueSimple3.rat") in ()

let%test_unit "testStatiqueSimple4" =
  let _ = compiler (pathFichiersRat^"testStatiqueSimple4.rat") in ()

let%test_unit "testStatiqueCond"=
  let _ = compiler (pathFichiersRat^"testStatiqueCond.rat") in ()

let%test_unit "testDeclaration1" = 
try 
  let _ = compiler (pathFichiersRat^"testDeclaration1.rat")
  in raise ErreurNonDetectee
with
| DeclarationStatiqueDansMAIN _ -> ()

let%test_unit "testDeclaration2" = 
  let _ = compiler (pathFichiersRat^"testDeclaration2.rat") in ()



let%test_unit "testDoubleDecla1" = 
  try
    let _ = compiler (pathFichiersRat^"testDoubleDecla1.rat")
    in raise ErreurNonDetectee
  with
  | DoubleDeclaration("x") -> ()

let%test_unit "testDoubleDecla2" = 
    let _ = compiler (pathFichiersRat^"testDoubleDecla2.rat") in ()

let%test_unit "testDD" =
try 
  let _ = compiler (pathFichiersRat^"testDD.rat")
  in raise ErreurNonDetectee
with  
| DeclarationStatiqueDansMAIN _ -> () 
 