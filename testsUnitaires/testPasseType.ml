open Rat
open Tds
open Ast
open PasseTypeRat
open Type
open Exceptions


(* Test pour l'identifiant de variable *)
let%test "analyse_type_affectable_ident_variable" =
  (* Créer un identifiant pour une variable *)
  let var_info = ref (InfoVar("x", Int, 0, "")) in
  let ident = AstTds.Ident var_info in
  
  (* Appeler analyse_type_affectable et vérifier le résultat *)
  let result, typ = analyse_type_affectable ident in
  match result with
  | AstTds.Ident info -> 
      !info = !var_info && typ = Int  (* Vérifier que le type est correct et l'info correspond *)
  | _ -> false

(* Test pour l'identifiant de constante *)
let%test "analyse_type_affectable_ident_constante" =
  (* Créer un identifiant pour une constante *)
  let const_info = ref (InfoConst("PI", 3)) in
  let ident = AstTds.Ident const_info in
  
  (* Appeler analyse_type_affectable et vérifier le résultat *)
  let result, typ = analyse_type_affectable ident in
  match result with
  | AstTds.Ident info -> 
      !info = !const_info && typ = Int  (* Vérifier que le type d'une constante est Int *)
  | _ -> false

(* Test pour un pointeur correctement typé *)
let%test "analyse_type_affectable_pointeur" =
  (* Créer un identifiant pour une variable de type pointeur *)
  let ptr_info = ref (InfoVar("ptr", Pointeur Int, 0, "")) in
  let deref = AstTds.Deref (AstTds.Ident ptr_info) in
  
  (* Appeler analyse_type_affectable et vérifier le résultat *)
  let result, typ = analyse_type_affectable deref in
  match result with
  | AstTds.Deref _ -> typ = Int  (* Vérifier que le type de l'affectable est le type pointeur *)
  | _ -> false

(* Test pour un pointeur avec un type incorrect *)
let%test "analyse_type_affectable_pointeur_incorrect" =
  (* Créer un identifiant pour une variable de type entier (pas pointeur) *)
  let var_info = ref (InfoVar("x", Int, 0, "")) in
  let deref = AstTds.Deref (AstTds.Ident var_info) in
  
  (* Essayer d'analyser un pointeur d'un type incorrect et vérifier que l'exception est levée *)
  try
    let _ = analyse_type_affectable deref in
    false  (* Si aucune exception n'est levée, le test échoue *)
  with
  | TypeInattendu (t1, t2) -> 
      t1 = Int && t2 = Pointeur Int  (* Vérifier que le type attendu était Pointeur Int *)
  | _ -> false  (* Si une autre exception est levée, le test échoue *)

(* Test pour une mauvaise utilisation de l'identifiant (cas où ce n'est ni une variable ni une constante) *)
let%test "analyse_type_affectable_ident_mauvais_type" =
  (* Créer un identifiant pour un autre type (pas une variable ni une constante) *)
  let fun_info = ref (InfoFun("f", Int, [Int], [])) in
  let ident = AstTds.Ident fun_info in
  
  (* Essayer d'analyser un identifiant de fonction et vérifier que l'exception est levée *)
  try
    let _ = analyse_type_affectable ident in
    false  (* Si aucune exception n'est levée, le test échoue *)
  with
  | MauvaiseUtilisationIdentifiant "variable" -> true  (* Vérifier que l'exception MauvaiseUtilisationIdentifiant a été levée *)
  | _ -> false  (* Si une autre exception est levée, le test échoue *)




(* test type expression *)


(* Test pour une expression d'entier *)
let%test "analyse_type_expression_entier" =
  let expr = AstTds.Entier 42 in
  let result, typ = analyse_type_expression expr in
  match result with
  | AstType.Entier _ -> typ = Int
  | _ -> false

(* Test pour une expression booléenne *)
let%test "analyse_type_expression_booleen" =
  let expr = AstTds.Booleen true in
  let result, typ = analyse_type_expression expr in
  match result with
  | AstType.Booleen _ -> typ = Bool
  | _ -> false

(* Test pour une expression d'appel de fonction avec des types corrects *)
let%test "analyse_type_expression_appel_fonction_correct" =
  let info = ref (InfoFun("f", Int, [Int], [])) in
  let param = AstTds.Entier 10 in
  let expr = AstTds.AppelFonction(info, [param]) in
  let result, typ = analyse_type_expression expr in
  match result with
  | AstType.AppelFonction(_, [AstType.Entier _]) -> typ = Int
  | _ -> false

(* Test pour une expression d'appel de fonction avec des types de paramètres incorrects *)
let%test "analyse_type_expression_appel_fonction_incorrect" =
  let info = ref (InfoFun("f", Int, [Int], [])) in
  let param = AstTds.Booleen true in
  let expr = AstTds.AppelFonction(info, [param]) in
  try
    let _ = analyse_type_expression expr in
    false  (* Si aucune exception n'est levée, le test échoue *)
  with
  | TypesParametresInattendus([Int], [Bool]) -> true
  | _ -> false



(* Test pour une expression unitaire avec un type incorrect (non-rationnel) *)
let%test "analyse_type_expression_unnaire_incorrect" =
  let expr = AstTds.Unaire(Numerateur, AstTds.Booleen true) in
  try
    let _ = analyse_type_expression expr in
    false  (* Si aucune exception n'est levée, le test échoue *)
  with
  | TypeInattendu(Bool, Rat) -> true
  | _ -> false

(* Test pour une expression binaire de type correcte (addition d'entiers) *)
let%test "analyse_type_expression_binaire_plus_int" =
  let expr1 = AstTds.Entier 10 in
  let expr2 = AstTds.Entier 20 in
  let expr = AstTds.Binaire(Plus, expr1, expr2) in
  let result, typ = analyse_type_expression expr in
  match result with
  | AstType.Binaire(PlusInt, _, _) -> typ = Int
  | _ -> false

(* Test pour une expression binaire de type incorrect (addition entre entier et booléen) *)
let%test "analyse_type_expression_binaire_plus_incorrect" =
  let expr1 = AstTds.Entier 10 in
  let expr2 = AstTds.Booleen true in
  let expr = AstTds.Binaire(Plus, expr1, expr2) in
  try
    let _ = analyse_type_expression expr in
    false  (* Si aucune exception n'est levée, le test échoue *)
  with
  | TypeBinaireInattendu(Plus, Int, Bool) -> true
  | _ -> false

(* Test pour une expression Null *)
let%test "analyse_type_expression_null" =
  let expr = AstTds.Null in
  let result, typ = analyse_type_expression expr in
  match result with
  | AstType.Null -> typ = Null
  | _ -> false

(* Test pour une expression New pour créer un pointeur *)
let%test "analyse_type_expression_new" =
  let expr = AstTds.New Int in
  let result, typ = analyse_type_expression expr in
  match result with
  | AstType.New _ -> typ = Pointeur Int
  | _ -> false

(* Test pour une expression Adresse valide (variable) *)
let%test "analyse_type_expression_adresse" =
  let var_info = ref (InfoVar("x", Int, 0, "")) in
  let expr = AstTds.Adresse var_info in
  let result, typ = analyse_type_expression expr in
  match result with
  | AstType.Adresse _ -> typ = Pointeur Int
  | _ -> false

(* Test pour une expression Adresse invalide (fonction) *)
let%test "analyse_type_expression_adresse_invalide" =
  let fun_info = ref (InfoFun("f", Int, [Int], [])) in
  let expr = AstTds.Adresse fun_info in
  try
    let _ = analyse_type_expression expr in
    false  (* Si aucune exception n'est levée, le test échoue *)
  with
  | MauvaiseUtilisationIdentifiant "variable" -> true
  | _ -> false


  let%test "analyse_type_instruction_declaration" =
  let expr = AstTds.Entier 42 in
  let info = ref (InfoVar("x", Int, 0, "")) in
  let decl = AstTds.Declaration(Int, info, expr) in
  let result = analyse_type_instruction decl in
  match result with
  | AstType.Declaration(_, AstType.Entier _) -> true
  | _ -> false


  let%test "analyse_type_instruction_affectation" =
  let expr = AstTds.Entier 42 in
  let info = ref (InfoVar("x", Int, 0, "")) in
  let aff = AstTds.Affectation(AstTds.Ident info, expr) in  (* Utiliser AstTds.Ident(info) pour l'affectable *)
  let result = analyse_type_instruction aff in
  match result with
  | AstType.Affectation(_, AstType.Entier _) -> true
  | _ -> false


   let%test "analyse_type_instruction_affectation_incorrecte" =
  let expr = AstTds.Booleen true in
  let info = ref (InfoVar("x", Int, 0, "")) in
  let aff =  AstTds.Affectation(AstTds.Ident info, expr) in 
  try
    let _ = analyse_type_instruction aff in
    false (* Si aucune exception n'est levée, le test échoue *)
  with
  | TypeInattendu(_, Int) -> true
  | _ -> false 

  let%test "analyse_type_instruction_conditionnelle" =
  let expr = AstTds.Booleen true in
  let bloc1 = [] (* Un bloc vide pour simplifier le test *) in
  let bloc2 = [] in
  let cond = AstTds.Conditionnelle(expr, bloc1, bloc2) in
  let result = analyse_type_instruction cond in
  match result with
  | AstType.Conditionnelle(_, [], []) -> true
  | _ -> false



(* Test pour une variable avec type compatible *)
let%test "analyse_type_variable_globale_var_type_compatible" =
  let expr = AstTds.Entier 42 in
  let info = ref (InfoVar("x", Int, 0, "")) in
  let decl_globale = AstTds.DeclarationGlobale(info, expr) in
  let result = analyse_type_variable_globale decl_globale in
  match result with
  | AstType.DeclarationGlobale(_, AstType.Entier _) -> true
  | _ -> false

(* Test pour une variable avec type incompatible *)
let%test "analyse_type_variable_globale_var_type_incompatible" =
  let expr = AstTds.Booleen true in  (* Le type de l'expression est Bool, mais la variable est de type Int *)
  let info = ref (InfoVar("x", Int, 0, "")) in
  let decl_globale = AstTds.DeclarationGlobale(info, expr) in
  try
    let _ = analyse_type_variable_globale decl_globale in
    false  (* Si aucune exception n'est levée, le test échoue *)
  with
  | Exceptions.TypeInattendu (_, Int) -> true  (* Vérifier que l'exception est levée pour un type incompatible *)
  | _ -> false

(* Test pour une constante avec type compatible (Int attendu) *)
let%test "analyse_type_variable_globale_const_type_compatible" =
  let expr = AstTds.Entier 42 in
  let info = ref (InfoConst("c", 42)) in
  let decl_globale = AstTds.DeclarationGlobale(info, expr) in
  let result = analyse_type_variable_globale decl_globale in
  match result with
  | AstType.DeclarationGlobale(_, AstType.Entier _) -> true
  | _ -> false

(* Test pour une constante avec type incompatible (autre que Int) *)
let%test "analyse_type_variable_globale_const_type_incompatible" =
  let expr = AstTds.Booleen true in  (* Le type de l'expression est Bool, mais la constante attend un Int *)
  let info = ref (InfoConst("c", 42)) in
  let decl_globale = AstTds.DeclarationGlobale(info, expr) in
  try
    let _ = analyse_type_variable_globale decl_globale in
    false  (* Si aucune exception n'est levée, le test échoue *)
  with
  | Exceptions.TypeInattendu (_, Int) -> true  (* Vérifier que l'exception est levée pour un type incompatible *)
  | _ -> false
