open Tds
open Exceptions
open Ast.AstPlacement
open Ast
open String
open Type
open Code
open Tam

type t1 = Ast.AstPlacement.programme
type t2 = string

  
(*AstPlacement.affectable (AstType.affectable) -> a -> string*)
(*Paramètre a : affectable à analyser*)
(*Retour : le code TAM correspondant à l'affectable*)
let rec analyse_code_affectable a en_ecriture =
  (* on vérifie que l'information est bien une variable *)
  match a with
  (* l'affectable est un identifiant *)
  | AstTds.Ident info ->
    begin
      match !info with
      | InfoVar(_, t, d, reg) ->
        let taille_type = getTaille t in
        if en_ecriture then
          store taille_type d reg
        else
          load taille_type d reg
      | InfoConst(_, c) -> loadl_int c
      | _ -> failwith "Erreur interne Ident"
    end
  (* l'affectable est un pointeur *)
  | AstTds.Deref na ->
    (* on vérifie que l'affectable est bien un pointeur *)
    (* on récupère le type de l'affectable *)
    let rec type_affectable a =
      match a with
      (* l'affectable est un identifiant *)
      | AstTds.Ident info ->
        begin
          match !info with
            | InfoVar(_, t, _, _) -> t
            | InfoConst(_, _) -> Int
            | _ -> failwith "Erreur interne Ident"
        end
      (* l'affectable est un pointeur *)
      | AstTds.Deref a ->
        let t = type_affectable a in
        match t with
        | Pointeur d -> d
        | _ -> failwith "Erreur interne Pointeur"
    in
    (* on récupère la taille du type de l'affectable *)
    let t = getTaille (type_affectable a)in
    let code = analyse_code_affectable na false in
    if en_ecriture then
      code ^ (storei t)
    else
      code ^ (loadi t)

(*AstPlacement.expression (AstType.expression) -> e -> string*)
(*Paramètre e : expression à analyser*)
(*Retour : le code TAM correspondant à l'expression*)
let rec analyse_code_expression e =
  
  match e with
    (* on vérifie que l'information est bien une fonction *)
  | AstType.AppelFonction (info, le) ->
    let all_le = List.map analyse_code_expression le in
    let nom, _, _, _ =  
    begin
      match (! info) with
      | InfoFun(nom, t, tp, lp) -> (nom, t, tp, lp) 
      | _ -> failwith "erreur dans le type de l'information de la fonction"
    end in

    List.fold_left ( ^ ) "" all_le ^ (call "SB" nom)
  | AstType.Affectable a -> analyse_code_affectable a false
  | AstType.New t ->
    let taille_type = getTaille t in
    (loadl_int taille_type) ^ (subr "MAlloc")
  | AstType.Adresse info ->
    (
      match !info with
      | InfoVar(_, _, d, reg) -> loada d reg
      | _ -> failwith "Erreur interne Ident"
    )
  | AstType.Null -> ""
  (* l'expression est un booléen *)
  | AstType.Booleen b -> loadl_int ( if b then 1 else 0 )
 (* l'expression est un entier *)
 | AstType.Entier i -> loadl_int i
 (* l'expression est un opération unaire *)
  |AstType.Unaire (op , e1) -> 
    (* charger e1 au sommet de la pile *)
    let expr = analyse_code_expression e1 in 
    let elt = 
    begin
      match op with 
        | Numerateur ->   (* on retire le dénominateur on le garde que le numérateur *)
          pop (0) 1
        | Denominateur -> (* on retire le numérateur on ne garder que la dénominateur *)
          pop (1) 1
    end in 
      expr ^ elt 
  |AstType.Binaire(op, e1,e2) -> 
    (* charger e1 et e2 au sommet de la pile *)
    let expr1 = analyse_code_expression e1 in
    let expr2 = analyse_code_expression e2 in 
    (* on applique l'opération binaire *)
    let code_val =
      match op with 
      | PlusInt -> Tam.subr "IAdd" 
      | PlusRat -> Tam.call "SB" "RAdd" 
      | MultInt -> Tam.subr "IMul"
      | MultRat -> Tam.call "SB" "RMul" 
      | EquInt| EquBool -> Tam.subr "Ieq" 
      | Inf -> Tam.subr "ILss" 
      | Fraction -> ""
      | _ -> failwith "Opérateur binaire non supporté dans analyse_code_expression"
    in 
    expr1 ^ expr2 ^ code_val

(* AstPlacement.instruction -> string *)
(* instruction -> string *)
(* Paramètre i : instruction à analyser *)
(* Retour : le code TAM correspondant à l'instruction *)
let rec analyse_code_instruction i =
  match i with
  (* l'instruction est une déclaration de variable statique *)
  | AstPlacement.DeclarationStatic (info, e) ->
    (* on récupère les informations sur la variable *)
    let (_, t, d, reg) = 
    begin
      match ( ! info) with
      | InfoVar(nom, t, d, reg) -> (nom, t, d, reg)
      | _ -> failwith "problème analyse_code_instruction __ DeclarationStatic"
    end
  in
    (* on récupère la taille du type de la variable *)
    let taille_type_e = getTaille t in
    (* on charge l'expression sur la pile *)
    (push taille_type_e) ^ (analyse_code_expression e) ^ (store taille_type_e d reg)
  (* l'instruction est une déclaration *)
  | AstPlacement.Declaration (info, e) ->
    (* on récupère les informations sur la variable *)
    let (_, t, d, reg) =
    begin
      match ( ! info) with
      | InfoVar(nom, t, d, reg) -> (nom, t, d, reg)
      | _ -> failwith "problème analyse_code_instruction __ Declaration"
    end in
    (* on récupère la taille du type de la variable *)
    let taille_type_e = getTaille t in
    (* on charge l'expression sur la pile *)
    (push taille_type_e) ^ (analyse_code_expression e) ^ (store taille_type_e d reg)
  | AstPlacement.Affectation (a, e) ->
    let sa = analyse_code_affectable a true in
    analyse_code_expression e ^ sa
 (* l'instruction est une constante *)
 | AffichageInt e -> (analyse_code_expression e ) ^ Tam.subr "IOut"
 (* l'instruction est un Rat*)
 | AffichageRat e -> (analyse_code_expression e ) ^ Tam.call "SB" "ROut"
 (* l'instruction est un Bool *)
 | AffichageBool e -> (analyse_code_expression e) ^ Tam.subr "BOut"
  | AstPlacement.AffichagePointeur (e, t) ->
    let taille_type = getTaille t in
    analyse_code_expression e ^ (loadi taille_type) ^ (subr "IOut")
  | AstPlacement.AffichageNull e -> analyse_code_expression e ^ (subr "SOut")
    (* l'instruction est une conditionnelle *)
  | Conditionnelle (c,e1,e2) -> 
    (* on crée deux étiquettes pour les deux blocs *)
    let etiquetteE = label (getEtiquette()) in 
    let etiquetteFin = label (getEtiquette ()) in 
    (* on analyse l'expression de la condition *)
    let code_e = analyse_code_expression c in
    (* on analyse les deux blocs *) 
    let bloc1 = analyse_code_bloc e1 in 
    let bloc2 = analyse_code_bloc e2 in 
   code_e ^ (Tam.jumpif 0 etiquetteE ) ^ bloc1 ^ (Tam.jump etiquetteFin) ^ etiquetteE ^ bloc2 ^ etiquetteFin
  (* l'instruction est une boucle tantque *)
  | TantQue(e,b) -> 
    (* on crée deux étiquettes pour la condition et la fin de la boucle *)
    let etiquetteCondition = label (getEtiquette()) in
    let etiquetteFin = label (getEtiquette()) in 
    (* on analyse l'expression de la condition *)
    let code_e = analyse_code_expression e in
    (* on analyse le bloc *)
    let code_b = analyse_code_bloc b in
    etiquetteCondition ^ code_e ^ (Tam.jumpif 0 etiquetteFin) ^ code_b ^ (Tam.jump etiquetteCondition) ^ etiquetteFin
  (* l'instruction est un retour *)
  | Retour (e,taille_Ret,taille_Param ) -> 
    (analyse_code_expression e) ^ (Tam.return taille_Ret taille_Param)
  | Empty -> ""
  
(* AstPlacement.bloc -> string *)
(* bloc -> string *)
(* paramètre li : liste des intructions à analyser *)
(* paramètre taille : ?? *)
(* retour : le code TAM correspondant au bloc *)
and analyse_code_bloc (li, _) =
  (* on analyse chaque instruction du bloc *) 
  let all_li = List.map analyse_code_instruction li in
  (* on concatène le code de chaque instruction *)
  List.fold_left ( ^ ) "" all_li

(* AstPlacement.fonction -> string *)
let analyse_code_fonction (AstPlacement.Fonction (info, _, bloc)) =
  (* on récupère les informations sur la fonction *)
  let nom_fonc, _, _, _ =   begin
    match (! info) with
    | InfoFun(nom, t, tp, lp) -> (nom, t, tp, lp) 
    | _ -> failwith "erreur dans le type de l'information de la fonction"
  end in
  (* on crée une étiquette pour la fonction *)
  (label nom_fonc) ^ analyse_code_bloc bloc ^ halt

(* AstPlacement.programme -> string *)
(* programme -> string *)
(* paramètre AstPlacement.Programme(globale, fonctions, static, prog) : programme à analyser *)
(* retourne : le code TAM correspondant au programme *)
let analyser (AstPlacement.Programme (globale, fonctions, static, prog)) =
  (* on analyse les variables globales *)
  let globales = analyse_code_bloc globale in
  (* on analyse les fonctions *)
  let fonctions = List.fold_left ( ^ ) "" (List.map analyse_code_fonction fonctions) in
  (* on analyse les variables statiques *)
  let static = analyse_code_bloc static in
  (* on analyse le programme *)
  let code_prog = analyse_code_bloc prog in
  (getEntete ()) ^ fonctions ^ "main\n" ^ globales ^ static ^ code_prog ^ halt 

