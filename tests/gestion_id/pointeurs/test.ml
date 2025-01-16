open Rat
open Compilateur

exception ErreurNonDetectee

(****************************************)
(** Chemin d'accès aux fichiers de test *)
(****************************************)

let pathFichiersRat = "../../../../../tests/gestion_id/pointeurs/fichiersRat/"

(**********)
(*  TESTS *)
(**********)

let%test_unit "testInitialisation1" = 
  let _ = compiler (pathFichiersRat^"testInitialisation1.rat") in ()

let%test_unit "testInitialisation2" = 
  let _ = compiler (pathFichiersRat^"testInitialisation2.rat") in ()

let%test_unit "testInitialisation3" = 
  let _ = compiler (pathFichiersRat^"testInitialisation3.rat") in ()

let%test_unit "testDeref1" = 
  let _ = compiler (pathFichiersRat^"testDeref1.rat") in ()

let%test_unit "testDeref2" = 
  let _ = compiler (pathFichiersRat^"testDeref2.rat") in ()

let%test_unit "testAcces1" = 
  let _ = compiler (pathFichiersRat^"testAcces1.rat") in ()

let%test_unit "testAcces2" = 
  let _ = compiler (pathFichiersRat^"testAcces2.rat") in ()

let%test_unit "testValAcces" = 
  let _ = compiler (pathFichiersRat^"testValAcces.rat") in ()

let%test_unit "testNullInitialisation" = 
  let _ = compiler (pathFichiersRat^"testNullInitialisation.rat") in ()

let%test_unit "testNullDeref" = 
  let _ = compiler (pathFichiersRat^"testNullDeref.rat") in ()