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

(*AstPlacement.expression (AstType.expression) -> e -> string*)
(*Paramètre e : expression à analyser*)
(*Retour : le code TAM correspondant à l'expression*)
let rec analyse_code_expression e = match e with
(* l'expression est un Appel de fonction *)
| AstType.AppelFonction (info, le) -> 
  (* on vérifie que l'information est bien une fonction *)
    (match !info with 
     | InfoFun (nom, _, _) -> 
         (* Analyser les arguments *)
         let all_le = List.fold_left (fun acc e -> acc ^ analyse_code_expression e) "" le in
         (* Appeler la fonction avec les arguments empilés *)
         all_le ^ call "SB" nom
     | _ -> failwith "problème analyse_code_expression __ appel_fonction"
    )
(* l'expression est une variable *)
  | AstType.Ident info ->
    begin
      (* on vérifie que l'information est bien une variable ou une constante *)
      match !info with
        | InfoVar(_,t,dep, reg) -> 
            load (getTaille t) dep reg
        | InfoConst (_,v )-> 
            loadl_int v
        | _ ->failwith "problème analyse_code_expression __ appel_fonction"
    end
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
  (* l'expression est un opération binaire *)
  | AstType.Binaire(op, e1,e2) -> 
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
let rec analyse_code_instruction i = match i with 
  (* l'instruction est une déclaration *)
  | Declaration (i,e) ->
    begin 
      (* on vérifie que l'information est bien une variable *)
      match !i with 
      | InfoVar(_,t,dep,reg) -> (Tam.push (getTaille t)) ^ ( analyse_code_expression e) ^ (Tam.store (getTaille t) dep reg)
      | _ -> failwith" problème analyse_code_instruction __ déclaration "
    end
  (* l'instruction est une affectation *)
  | Affectation (i,e) ->
    begin
      (* on vérifie que l'information est bien une variable *)
      match !i with 
      | InfoVar(_,t,dep,reg) -> (analyse_code_expression e) ^ (Tam.store (getTaille t) dep reg)
      | _ -> failwith "problème analyse_code_instruction __  Affectation"
    end
  (* l'instruction est une constante *)
  | AffichageInt e -> (analyse_code_expression e ) ^ Tam.subr "IOut"
  (* l'instruction est un Rat*)
  | AffichageRat e -> (analyse_code_expression e ) ^ Tam.call "SB" "ROut"
  (* l'instruction est un Bool *)
  | AffichageBool e -> (analyse_code_expression e) ^ Tam.subr "BOut"
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
  and analyse_code_bloc (li , taille) = 
      let all_li = List.map analyse_code_instruction li in 
      (String.concat "" all_li) ^ Tam.pop 0 taille

  
(* AstPlacement.fonction -> string *)
(* fonction -> string *)
(* paramètre Fonction(info, _ , bloc) : fonction à analyser *)
(* retour : le code TAM correspondant à la fonction *)
  let analyse_code_fonction (Fonction(info, _ , bloc)) =
    begin 
      (* on vérifie que l'information est une fonction *)
      match ! info with 
      | InfoFun (n,_,_ ) -> label n ^ analyse_code_bloc bloc ^ Tam.halt
      | _ -> failwith " problème analyse code fonction "
    end

(* AstPlacement.programme -> string *)
(* programme -> string *)
(* paramètre Programme(fonctions , prog) : programme à analyser *)
(* retour : le code TAM correspondant au programme *)
  let analyser (Programme(fonctions , prog)) =
    (* on analyse des fonctions du programme  *)
    let code_fonction = List.map analyse_code_fonction fonctions in 
    (* on analyse le programme principal *)
    let code_prog = "MAIN\n" ^ analyse_code_bloc prog ^ Tam.halt in 
    getEntete() ^ code_prog ^ (String.concat "" code_fonction)
