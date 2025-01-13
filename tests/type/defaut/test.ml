open Rat
open Compilateur
open Exceptions

exception ErreurNonDetectee

(****************************************)
(** Chemin d'accès aux fichiers de test *)
(****************************************)

let pathFichiersRat = "../../../../../tests/type/defaut/fichiersRat/"


(**********)
(*  TESTS *)
(**********)

let%test_unit "testDefaut1" = 
  let _ = compiler (pathFichiersRat^"testDefaut1.rat") in ()

let%test_unit "testDefaut2" =
  let _ = compiler (pathFichiersRat^"testDefaut2.rat") in ()

let%test_unit "testDefaut3" =
  let _ = compiler (pathFichiersRat^"testDefaut3.rat") in ()

let%test_unit "testDefaut4" =
try 
  let _ = compiler (pathFichiersRat^"testDefaut4.rat")
  in raise ErreurNonDetectee
with    
| TypesParametresInattendus(_, _) -> ()


let%test_unit "testDefaut5" =
try 
  let _ = compiler (pathFichiersRat^"testDefaut5.rat")
  in raise ErreurNonDetectee  
with
| TypesParametresInattendus(_, _) -> ()


let%test_unit "testDefaut6" =
try 
  let _ = compiler (pathFichiersRat^"testDefaut6.rat")
  in raise ErreurNonDetectee
with
| TypesParametresInattendus(_, _) -> ()

let%test_unit "testDefaut7" =
let _ = compiler (pathFichiersRat^"testDefaut7.rat") in ()


let%test_unit "testDefaut8" =
let _ = compiler (pathFichiersRat^"testDefaut8.rat") in ()

let%test_unit "testDefaut9" =
try 
  let _ = compiler (pathFichiersRat^"testDefaut9.rat")
  in raise ErreurNonDetectee
with
  | TypeBinaireInattendu(Plus, Int, Bool) -> ()


let%test_unit "testDefaut10" =
let _ = compiler (pathFichiersRat^"testDefaut10.rat") in ()


let%test_unit "testDefaut11" =
try 
  let _ = compiler (pathFichiersRat^"testDefaut11.rat")
  in raise ErreurNonDetectee
with
| TypesParametresInattendus(_, _) -> ()


let%test_unit "testDefaut12" =
try 
  let _ = compiler (pathFichiersRat^"testDefaut12.rat")
  in raise ErreurNonDetectee
with
| TypesParametresInattendus(_, _) -> ()