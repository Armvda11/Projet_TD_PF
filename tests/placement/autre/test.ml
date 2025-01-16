open Rat
open Compilateur
open Passe

(* Return la liste des adresses des variables d'un programme RAT *)
let getListeDep ratfile =
  let input = open_in ratfile in
  let filebuf = Lexing.from_channel input in
  try
  let ast = Parser.main Lexer.token filebuf in
  let past = CompilateurRat.calculer_placement ast in
  let listeAdresses = VerifPlacement.analyser past in
  listeAdresses
  with
  | Lexer.Error _ as e ->
      report_error ratfile filebuf "lexical error (unexpected character).";
      raise e
  | Parser.Error as e->
      report_error ratfile filebuf "syntax error.";
      raise e

(* teste si dans le fichier fichier, dans la fonction fonction (main pour programme principal)
la occ occurence de la variable var a l'adresse dep[registre]
*)
let test fichier fonction (var,occ) (dep,registre) = 
  let l = getListeDep fichier in
  let lmain = List.assoc fonction l in
  let rec aux i lmain = 
    if i=1 
    then
      let (d,r) = List.assoc var lmain in
      (d=dep && r=registre)
    else 
      aux (i-1) (List.remove_assoc var lmain)
  in aux occ lmain

(****************************************)
(** Chemin d'accès aux fichiers de test *)
(****************************************)

let pathFichiersRat = "../../../../../tests/placement/autre/fichiersRat/"

(**********)
(*  TESTS *)
(**********)

let%test "mult_a" = 
  test (pathFichiersRat^"complexe.rat") "mult" ("a", 1) (-2, "LB")

let%test "mult_r" = 
  test (pathFichiersRat^"complexe.rat") "mult" ("r", 1) (-1, "LB")

let%test "mult_temp" = 
  test (pathFichiersRat^"complexe.rat") "mult" ("temp", 1) (3, "LB")

let%test "mult_b" = 
  test (pathFichiersRat^"complexe.rat") "mult" ("b", 1) (5, "LB")


  let%test "main_r1" = 
  test (pathFichiersRat^"complexe.rat") "main" ("r1", 1) (2, "SB")

let%test "main_r2" = 
  test (pathFichiersRat^"complexe.rat") "main" ("r2", 1) (4, "SB")


let%test "main_result" = 
  test (pathFichiersRat^"complexe.rat") "main" ("result", 1) (6, "SB")

let%test "main_final" = 
  test (pathFichiersRat^"complexe.rat") "main" ("final", 1) (7, "SB")




  let%test "simple_main_c" = 
  test (pathFichiersRat^"simple.rat") "main" ("b", 1) (1, "SB")



  let%test "compute_a" = 
  test (pathFichiersRat^"test_param_default2.rat") "compute" ("a", 1) (-4, "LB")

let%test "compute_b" = 
  test (pathFichiersRat^"test_param_default2.rat") "compute" ("b", 1) (-3, "LB")

let%test "compute_c" = 
  test (pathFichiersRat^"test_param_default2.rat") "compute" ("c", 1) (-2, "LB")

let%test "main_x" = 
  test (pathFichiersRat^"test_param_default2.rat") "main" ("x", 1) (0, "SB")

let%test "main_y" = 
  test (pathFichiersRat^"test_param_default2.rat") "main" ("y", 1) (1, "SB")

let%test "main_z" = 
  test (pathFichiersRat^"test_param_default2.rat") "main" ("z", 1) (2, "SB")
