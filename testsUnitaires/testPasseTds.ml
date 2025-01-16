open Rat
open Tds
open Ast
open PasseTdsRat
open Type


(* Définitions de variables pour les tests *)
let tds = creerTDSMere ()

let a = AstSyntax.Ident("a")
let b = AstSyntax.Ident("b")
exception ErreurNonDetectee

(* Test utilitaire pour afficher les infos *)
let string_of_info_ast ia =
  match !ia with
  | InfoVar (n, t, dep, base) -> Printf.sprintf "InfoVar(%s, %s, %d, %s)" n (string_of_type t) dep base
  | _ -> "Unknown"

(* Fonction pour comparer deux info_ast *)
let compare_info_ast ia1 ia2 =
    match (!ia1, !ia2) with
    | InfoVar (n1, t1, dep1, base1), InfoVar (n2, t2, dep2, base2) ->
      n1 = n2 && t1 = t2 && dep1 = dep2 && base1 = base2
    | _ -> false

(* Test pour analyse_tds_instruction_declaration_static *)
let%test "analyse_tds_instruction_declaration_static" =
  let expression = AstSyntax.Entier(5) in  (* Une expression simple *)
  let instruction = AstSyntax.DeclarationStatic(Int, "x", expression) in
  let result = analyse_tds_instruction tds None instruction in
  match result with
  | AstTds.DeclarationStatic(_, ia, _) ->
    let expected = ref (InfoVar("x", Int, 0, "")) in
    let is_equal = compare_info_ast ia expected in
    Printf.printf "Expected: %s, Got: %s\n" (string_of_info_ast expected) (string_of_info_ast ia);
    is_equal
  | _ -> false

(* Test pour analyse_tds_affectable avec un identifiant valide *)
let%test "analyse_tds_affectable_valid" =
  let ia = info_to_info_ast (InfoVar("a", Int, 0, "rbp")) in
  ajouter tds "a" ia;
  let res = analyse_tds_affectable tds (AstSyntax.Ident("a")) true in
  match res with
  | AstTds.Ident(info) -> info = ia
  | _ -> false

(* Test pour analyse_tds_expression avec un entier valide *)
let%test "analyse_tds_expression_int" =
  let res = analyse_tds_expression tds (AstSyntax.Entier(5)) in
  match res with
  | AstTds.Entier(5) -> true
  | _ -> false

(* Test pour analyse_tds_expression avec un booléen valide *)
let%test "analyse_tds_expression_bool" =
  let res = analyse_tds_expression tds (AstSyntax.Booleen(true)) in
  match res with
  | AstTds.Booleen(true) -> true
  | _ -> false


(* Test pour analyse_tds_instruction_declaration *)
let%test "analyse_tds_instruction_declaration" =
  let expression = AstSyntax.Entier(5) in
  let instruction = AstSyntax.Declaration(Int, "y", expression) in
  let result = analyse_tds_instruction tds None instruction in
  match result with
  | AstTds.Declaration(_, ia, _) ->
    let expected = ref (InfoVar("y", Int, 0, "")) in
    let is_equal = compare_info_ast ia expected in
    Printf.printf "Expected: %s, Got: %s\n" (string_of_info_ast expected) (string_of_info_ast ia);
    is_equal
  | _ -> false

(* Test pour analyse_tds_instruction_affectation *)
let%test "analyse_tds_instruction_affectation" =
  let ia = info_to_info_ast (InfoVar("x", Int, 0, "")) in
  ajouter tds "x" ia;
  let expression = AstSyntax.Entier(10) in
  let instruction = AstSyntax.Affectation(AstSyntax.Ident("x"), expression) in
  let result = analyse_tds_instruction tds None instruction in
  match result with
  | AstTds.Affectation(AstTds.Ident(info), AstTds.Entier(10)) ->
    info = ia
  | _ -> false

(* Test pour analyse_tds_instruction_constante *)
let%test "analyse_tds_instruction_constante" =
  let instruction = AstSyntax.Constante("v", 3) in
  let result = analyse_tds_instruction tds None instruction in
  match result with
  | AstTds.Empty -> true
  | _ -> false

(* Test pour analyse_tds_instruction_affichage *)
let%test "analyse_tds_instruction_affichage" =
  let expression = AstSyntax.Entier(42) in
  let instruction = AstSyntax.Affichage(expression) in
  let result = analyse_tds_instruction tds None instruction in
  match result with
  | AstTds.Affichage(AstTds.Entier(42)) -> true
  | _ -> false

(* Test pour analyse_tds_instruction_conditionnelle *)
let%test "analyse_tds_instruction_conditionnelle" =
  let condition = AstSyntax.Booleen(true) in
  let then_bloc = [AstSyntax.Declaration(Int, "x", AstSyntax.Entier(1))] in
  let else_bloc = [AstSyntax.Declaration(Int, "y", AstSyntax.Entier(2))] in
  let instruction = AstSyntax.Conditionnelle(condition, then_bloc, else_bloc) in
  let result = analyse_tds_instruction tds None instruction in
  match result with
  | AstTds.Conditionnelle(AstTds.Booleen(true), then_bloc', else_bloc') ->
    (* On s'assure que les blocs then et else contiennent des déclarations de type Int *)
    (match then_bloc' with
     | [AstTds.Declaration(Int, _, _)] -> 
       (match else_bloc' with
        | [AstTds.Declaration(Int, _, _)] -> true
        | _ -> false)
     | _ -> false)
  | _ -> false


(* Test pour analyse_tds_instruction_tantque *)
let%test "analyse_tds_instruction_tantque" =
  let condition = AstSyntax.Booleen(false) in
  let bloc = [AstSyntax.Declaration(Int, "x", AstSyntax.Entier(0))] in
  let instruction = AstSyntax.TantQue(condition, bloc) in
  let result = analyse_tds_instruction tds None instruction in
  match result with
  | AstTds.TantQue(AstTds.Booleen(false), bloc') ->
    (* Vérification explicite de la structure du bloc *)
    (match bloc' with
     | [AstTds.Declaration(Int, _, _)] -> true
     | _ -> false)
  | _ -> false


(* Test pour analyse_tds_instruction_retour *)
let%test "analyse_tds_instruction_retour" =
  let expression = AstSyntax.Entier(0) in
  let instruction = AstSyntax.Retour(expression) in
  let info_fun = ref (InfoFun("main", Int, [], [])) in  (* Utilisation de ref pour créer une référence de type info_ast *)
  let result = analyse_tds_instruction tds (Some info_fun) instruction in  (* On passe info_fun directement, pas besoin de déréférencer *)
  match result with
  | AstTds.Retour(AstTds.Entier(0), _) -> true
  | _ -> false

 (* Définir l'exception DoubleDeclaration si elle n'est pas encore définie *)
exception DoubleDeclaration of string

let%test "analyse_variable_globale_ajout_correct" =
  (* Réinitialiser la table des symboles avant chaque test *)
let tds = creerTDSMere () in

  (* Créer une expression simple pour initialiser la variable *)
  let expression = AstSyntax.Entier(10) in
  let instruction = AstSyntax.DeclarationGlobale(Int, "x", expression) in
  
  (* Appeler analyse_variable_globale et vérifier que la variable est bien ajoutée *)
  let result = analyse_variable_globale tds instruction in
  match result with
  | AstTds.Declaration(_, ia, _) -> 
      (* Vérifier que l'information de la variable a été correctement ajoutée *)
      let expected = ref (InfoVar("x", Int, 0, "")) in
      compare_info_ast ia expected  (* Comparer l'info ajoutée avec l'info attendue *)
  | _ -> false

(* Définir l'exception DoubleDeclaration si elle n'est pas encore définie *)


let%test "analyse_variable_globale_double_declaration" =
  (* Réinitialiser la table des symboles avant chaque test *)
  let tds = creerTDSMere () in

  (* Créer une expression simple pour initialiser la variable *)
  let expression = AstSyntax.Entier(10) in
  let instruction = AstSyntax.DeclarationGlobale(Int, "x", expression) in
  
  (* Ajouter une première fois la variable *)
  let _ = analyse_variable_globale tds instruction in

  (* Essayer d'ajouter la même variable et vérifier que l'exception DoubleDeclaration est levée *)
  try
    let _ = analyse_variable_globale tds instruction in
    false  (* Si aucune exception n'est levée, le test échoue *)
  with
  | Exceptions.DoubleDeclaration "x" -> 
      true  (* Vérifier que l'exception DoubleDeclaration a été levée avec le bon nom *)
  | _ -> 
      false  (* Si une autre exception est levée, le test échoue *)


(* Test pour analyse_gestion_id_variable_globale *)
let%test "analyse_gestion_id_variable_globale_declaration_unique" =
  (* Réinitialiser la table des symboles avant chaque test *)
  let tds = creerTDSMere () in

  (* Créer une expression simple pour initialiser la variable *)
  let expression = AstSyntax.Entier(10) in
  let instruction = AstSyntax.DeclarationGlobale(Int, "x", expression) in
  
  (* Ajouter la variable et vérifier qu'elle est correctement ajoutée *)
  let result = analyse_gestion_id_variable_globale tds instruction in
  match result with
  | AstTds.Declaration(_, ia, _) -> 
      (* Vérifier que l'information de la variable a été correctement ajoutée *)
      let expected = ref (InfoVar("x", Int, 0, "")) in
      compare_info_ast ia expected  (* Comparer l'info ajoutée avec l'info attendue *)
  | _ -> false



let%test "analyse_gestion_id_variable_globale_double_declaration" =
  (* Réinitialiser la table des symboles avant chaque test *)
  let tds = creerTDSMere () in

  (* Créer une expression simple pour initialiser la variable *)
  let expression = AstSyntax.Entier(10) in
  let instruction = AstSyntax.DeclarationGlobale(Int, "x", expression) in
  
  (* Ajouter une première fois la variable *)
  let _ = analyse_gestion_id_variable_globale tds instruction in

  (* Essayer d'ajouter la même variable et vérifier que l'exception DoubleDeclaration est levée *)
  try
    let _ = analyse_gestion_id_variable_globale tds instruction in
    false  (* Si aucune exception n'est levée, le test échoue *)
  with
  | Exceptions.DoubleDeclaration "x" -> true  (* Vérifier que l'exception DoubleDeclaration a été levée avec le bon nom *)
  | _ -> false  (* Si une autre exception est levée, le test échoue *)
