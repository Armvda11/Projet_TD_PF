open Rat
open Compilateur
open Exceptions

exception ErreurNonDetectee

(****************************************)
(** Chemin d'accès aux fichiers de test *)
(****************************************)

let pathFichiersRat = "../../../../../tests/gestion_id/defaut/fichiersRat/"

(**********)
(*  TESTS *)
(**********)

let%test_unit "testDeclaration1" = 
  let _ = compiler (pathFichiersRat^"testDeclaration1.rat") in ()

let%test_unit "testDeclaration2" = 
  let _ = compiler (pathFichiersRat^"testDeclaration2.rat") in ()

let%test_unit "testDeclaration3" =
  let _ = compiler (pathFichiersRat^"testDeclaration3.rat") in ()

let%test_unit "testDoubleDecla1" = 
  try
    let _ = compiler (pathFichiersRat^"testDoubleDecla1.rat")
    in raise ErreurNonDetectee
  with
  | DoubleDeclaration _ -> ()

let%test_unit "testDoubleDecla2" = 
  try
    let _ = compiler (pathFichiersRat^"testDoubleDecla2.rat")
    in raise ErreurNonDetectee
  with
  | DoubleDeclaration _  -> ()


let%test_unit "testDoubleDecla3" = 
  try
    let _ = compiler (pathFichiersRat^"testDoubleDecla3.rat")
    in raise ErreurNonDetectee
  with
  | DoubleDeclaration _  -> ()

let%test_unit "testNonDeclaDefaut1" = 
  try
    let _ = compiler (pathFichiersRat^"testNonDeclaDefaut1.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare _ -> ()

  let%test_unit "testNonDeclaDefaut2" =
  try
    let _ = compiler (pathFichiersRat^"testNonDeclaDefaut2.rat")
    in raise ErreurNonDetectee
  with  
  | IdentifiantNonDeclare _ -> ()

let%test_unit "testNonDeclaDefautSS  -> sans problème " =
  let _ = compiler (pathFichiersRat^"testNonDeclaDefautSS.rat") in ()

let%test_unit "testNonDeclaDefautSS2  -> sans problème " =
  let _ = compiler (pathFichiersRat^"testNonDeclaDefautSS2.rat") in ()

let%test_unit "testNonDeclaDefautSS3  -> sans problème " =
  try
    let _ = compiler (pathFichiersRat^"testNonDeclaDefautSS3.rat")
    in raise ErreurNonDetectee
  with  
  | IdentifiantNonDeclare _ -> ()



let%test_unit "testNonDeclaDefaut3" =
  try
    let _ = compiler (pathFichiersRat^"testNonDeclaDefaut3.rat")
    in raise ErreurNonDetectee
  with
  | IdentifiantNonDeclare _ -> ()
