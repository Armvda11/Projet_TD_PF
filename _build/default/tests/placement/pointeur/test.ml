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

let pathFichiersRat = "../../../../../tests/placement/pointeur/fichiersRat/"

(**********)
(*  TESTS *)
(**********)

let%test "pointeur1_a" = 
  test (pathFichiersRat^"pointeur.rat") "main" ("a",1) (0,"SB")

let%test "pointeur1_c" = 
  test (pathFichiersRat^"pointeur.rat") "main" ("c",1) (2,"SB")

  let%test "pointeur1_x" = 
  test (pathFichiersRat^"pointeur.rat") "main" ("x",1) (3,"SB")

let%test "pointeur1_a_f" = 
  test (pathFichiersRat^"pointeur.rat") "add" ("a",1) (-3,"LB")

let%test "pointeur1_b_f" = 
  test (pathFichiersRat^"pointeur.rat") "add" ("b",1) (-2,"LB")

let%test "pointeur1_c_f" = 
  test (pathFichiersRat^"pointeur.rat") "add" ("c",1) (-1,"LB")

let%test "pointeur1_x_f" = 
  test (pathFichiersRat^"pointeur.rat") "add" ("x",1) (3,"LB")

let%test "pointeur1_z_f" = 
  test (pathFichiersRat^"pointeur.rat") "add" ("z",1) (4,"LB")

  

  let%test "testPointeur_x" = 
  test (pathFichiersRat^"pointeur2.rat")  "main" ("x",1)  (0, "SB")

let%test "testPointeur_p" = 
  test (pathFichiersRat^"pointeur2.rat")  "main" ("p",1)  (2, "SB")

let%test "testPointeur_p2" = 
  test (pathFichiersRat^"pointeur2.rat")  "main" ("l",1)  (1, "SB")








let%test "pointeur3_r" = 
  test (pathFichiersRat^"pointeur3.rat") "main" ("r", 1) (0, "SB")

let%test "pointeur3_a" = 
  test (pathFichiersRat^"pointeur3.rat") "main" ("a", 1) (2, "SB")

let%test "pointeur3_flag" = 
  test (pathFichiersRat^"pointeur3.rat") "main" ("flag", 1) (3, "SB")

let%test "pointeur3_result" = 
  test (pathFichiersRat^"pointeur3.rat") "main" ("result", 1) (4, "SB")

let%test "pointeur3_x_f" = 
  test (pathFichiersRat^"pointeur3.rat") "mult" ("x", 1) (-3, "LB")

let%test "pointeur3_y_f" = 
  test (pathFichiersRat^"pointeur3.rat") "mult" ("y", 1) (-2, "LB")

let%test "pointeur3_z_f" = 
  test (pathFichiersRat^"pointeur3.rat") "mult" ("z", 1) (-1, "LB")

let%test "pointeur3_temp_f" = 
  test (pathFichiersRat^"pointeur3.rat") "mult" ("temp", 1) (3, "LB")



