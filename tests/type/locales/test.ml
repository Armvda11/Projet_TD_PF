open Rat
open Compilateur
open Exceptions

exception ErreurNonDetectee

(****************************************)
(** Chemin d'accès aux fichiers de test *)
(****************************************)

let pathFichiersRat = "../../../../../tests/type/locales/fichiersRat/"


(**********)
(*  TESTS *)
(**********)

let%test_unit "testAcces1" = 
  let _ = compiler (pathFichiersRat^"testAcces1.rat") in ()

let%test_unit "testAcces2" =
try 
  let _ = compiler (pathFichiersRat^"testAcces2.rat")
  in raise ErreurNonDetectee
with    
| TypeInattendu(Bool, Int) -> ()

let%test_unit "testAcces3" =
try 
  let _ = compiler (pathFichiersRat^"testAcces3.rat")
  in raise ErreurNonDetectee
with
| TypeInattendu(Int, Bool) -> ()

let%test_unit "testAcces4" =
try 
  let _ = compiler (pathFichiersRat^"testAcces4.rat")
  in raise ErreurNonDetectee
with
| TypeInattendu(Int, Bool) -> ()

let%test_unit "testAcces5" =
try 
  let _ = compiler (pathFichiersRat^"testAcces5.rat")
  in raise ErreurNonDetectee
with
| TypeInattendu(Int, Bool) -> ()

let%test_unit "testAcces6" =
try 
  let _ = compiler (pathFichiersRat^"testAcces6.rat")
  in raise ErreurNonDetectee
with
| TypeInattendu(Int, Rat) -> ()

let%test_unit "testAcces7" =
let _ = compiler (pathFichiersRat^"testAcces7.rat") in ()


let%test_unit "testAcces8" =
let _ = compiler (pathFichiersRat^"testAcces8.rat") in ()


let%test_unit "testAcces9" =
try 
  let _ = compiler (pathFichiersRat^"testAcces9.rat")
  in raise ErreurNonDetectee  
with
| TypeInattendu(Int, Bool) -> ()

let%test_unit "testAcces10" =
try 
  let _ = compiler (pathFichiersRat^"testAcces10.rat")
  in raise ErreurNonDetectee
with
| TypeInattendu(Bool, Int) -> ()