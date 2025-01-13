open Type
open Tds

open Ast
open AstPlacement


type t1 = Ast.AstType.programme
type t2 = Ast.AstPlacement.programme





(* AstType.instruction -> int -> string -> AstPlacement.instruction * int *)
(* instruction, dep, reg -> instruction * taille *)
(* Paramètre instruction : l'instruction à analyser *)
(* Paramètre dep : déplacement actuel par rapport au registre reg *)
(* Paramètre reg : registre de référence (SB ou LB) *)
let rec analyse_placement_instruction i dep reg = match i with
| AstType.DeclarationStatic _ -> raise (Exceptions.DeclarationStatiqueDansMAIN ("Declaration statique dans le main"))
  (* l'instructiion est une déclaration *)
  | AstType.Declaration(info,e) ->
    begin
      match !info with
        (* L'identifiant est bien une variable *)
        | InfoVar(n,t,_,_) -> 
          (* on modifie l'adresse de la variable *)
          let ninfo = InfoVar(n,t,dep,reg) in
            modifier_adresse_variable dep reg info;
          (Declaration(ref ninfo, e), getTaille t)
        | _ -> failwith "type non-attendu dans le placement instruction Declaration"
    end

  | AstType.Affectation(ia,e) -> (Affectation(ia,e),0)
  (* l'instruction est une conditionnelle *)
  | AstType.Conditionnelle(c,t,e) ->
    (* analyse du premier et du second bloc*)
    let nbt = analyse_placement_bloc t dep reg in
    let nbe = analyse_placement_bloc e dep reg in
    (* on renvoie la conditionnelle avec les blocs analysés *)
    (Conditionnelle(c,nbt,nbe), 0)
  (* l'instruction est un retour *)
  | AstType.Retour(e,ia) ->
    (* on vérifie que l'information est bien une fonction *)
    begin
      match !ia with
      | InfoFun(_,tr,tp,_) -> 
        let tailleParam = List.fold_left (fun acc t -> (getTaille t) + acc) 0 tp in
        (Retour(e,getTaille tr, tailleParam),0)
      | _ -> failwith "type non-attendu dans le placement instruction Retour"
    end
  (* l'instruction est une boucle tantque *)
  | AstType.TantQue(c,b) ->
    let nbb = analyse_placement_bloc b dep reg in
    (TantQue(c,nbb),0)
  (* l'instruction est une affectation *)
  | AstType.Affectation(ia,e) -> (Affectation(ia,e),0)
  (* l'instruction est un affichage *)
  | AstType.AffichageInt e -> (AffichageInt(e),0)
  (* l'instruction est un affichage Rat*)
  | AstType.AffichageRat e -> (AffichageRat(e),0)
  (* l'instruction est un affichage Bool *)
  | AstType.AffichageBool e -> (AffichageBool(e),0)
  | AstType.AffichagePointeur (_, _) ->(AstPlacement.Empty, 0) (* (AstPlacement.AffichagePointeur (e, t), 0) *)
  | AstType.AffichageNull _ -> (AstPlacement.Empty, 0) (*(AstPlacement.AffichageNull e, 0)*)
  | AstType.Empty -> (AstPlacement.Empty, 0)


(* AstType.bloc -> int -> string -> AstPlacement.bloc * int *)
(* bloc, dep, reg -> bloc * taille *)
(* Paramètre li : liste d'instruction à analyser *)
(* Paramètre dep : déplacement actuel par rapport au registre reg *)
(* Paramètre reg : registre de référence (SB ou LB) *)
and  analyse_placement_bloc li dep reg = match li with
| [] -> ([], 0)
| i :: q ->
  (* Analyse une instruction et calcule sa taille *)
  let (ni, ti) = analyse_placement_instruction i dep reg in
  (* Analyse les instructions suivantes avec le déplacement mis à jour *)
  let (nli, tb) = analyse_placement_bloc q (dep + ti) reg in
  (* Combine les résultats *)
  (ni :: nli, ti + tb)






(* analyse_placement_bloc_fonction : AstType.instruction list -> int -> int -> (AstPlacement.instruction list * int) * int *)
(* Paramètre li : la liste d'instructions à analyser *)
(* Paramètre deplLB : le déplacement actuel dans le registres LB *)
(* Paramètre deplSB : le déplacement actuel dans le registre SB *)
(* Analyse un bloc d'instructions d'une fonction *)
(* Met à jour les Infos de la TDS et renvoie le bloc d'instructions avec la taille du bloc dans le registre LB *)
(* et la taille prise dans le registre SB et est de type (AstPlacement.instruction * int) * int *)

let rec analyse_placement_bloc_fonction li deplLB deplSB =
  match li with
  | h::q ->
    let ((i, tailleLB), tailleSB) = 
      match h with
      | AstType.DeclarationStatic (info, e) ->
        let (_, t, _, _) = 
          match (info_ast_to_info info) with
          | InfoVar(nom, t, d, reg) -> (nom, t, d, reg)
        in
        let taille = getTaille t in
        modifier_adresse_variable deplSB "SB" info;
        ((AstPlacement.DeclarationStatic(info, e), 0), taille)
      | _ -> (analyse_placement_instruction h deplLB "LB", 0)
    in
    (* On traite les instructions suivantes pour récupérer la liste des résultats des suivantes *)
    let ((listeInstructions, tailleBlocActuelleLB), tailleBlocActuelleSB) =
      analyse_placement_bloc_fonction q (deplLB + tailleLB) (deplSB + tailleSB)
    in
    (* On renvoie la mise à jour des variables : listes des instructions et les tailles dans les registres LB et SB *)
    ((i::listeInstructions, tailleLB + tailleBlocActuelleLB), tailleSB + tailleBlocActuelleSB)
  (* Cas final, on a traité toutes les instructions *)
  | [] -> ([], 0), 0

(* traiter_parametres_fonction : int -> info_ast list -> unit *)
(* Paramètre li : la liste d'instructions à trier *)
(* Traite la liste des infos des paramètres d'une fonction *)
(* Les fonctions partagent toutes le registre LB, le placement dépend *)
(* donc uniquement des instructions de la fonction elle-même. *)
let rec traiter_parametres_fonction tailleActuelleParam lst =
  (
  match lst with
  (* S'il n'y a aucun paramètre, on ne fait rien *)
  | [] -> ()
  | h::q ->
    begin
      match (info_ast_to_info h) with
      | InfoVar(_, t, _, _) -> let nouvelleTailleParam = (tailleActuelleParam - (getTaille t)) in
      (* On met à jour l'info du paramètre pour le placer dans LB *)
      modifier_adresse_variable nouvelleTailleParam "LB" h;
      (* On traite les paramètres suivants *)
      traiter_parametres_fonction nouvelleTailleParam q;
      | _ -> failwith ("Erreur interne paramètres fonction")
    end
  )



(* analyse_placement_fonction : AstType.fonction -> int -> AstPlacement.fonction * (AstPlacement.instruction list * int) *)
(* Paramètre info : l'info_ast de la fonction analysée *)
(* Paramètre lp : la liste des info_ast des paramètes de la fonction *)
(* Paramètre li : le bloc des instructions de la fonction *)
(* Analyse le placement d'une fonction. *)
(* Renvoie la fonction et la liste des instructions des variables statiques avec leur taille *)

let analyse_placement_fonction (AstType.Fonction(info,lp, li )) deplSB =
  let rec separer_declaration_static li =
    match li with
    | h::q ->
      let (lstFun, lstStatic) = separer_declaration_static q in
      begin
        match h with
          | AstPlacement.DeclarationStatic _ -> (lstFun, h::lstStatic)
          | _ -> (h::lstFun, lstStatic)
      end
    | [] -> ([],[])
  in
  match (info_ast_to_info info) with
  | InfoFun(_, _, _,_) ->
    let rec analyse_parametres tailleActuelleParam lst =
      match lst with
      (* S'il n'y a aucun paramètre, on ne fait rien *)
      | [] -> ()
      | h::q ->
        begin
          match (info_ast_to_info h) with
          | InfoVar(_, t, _, _) -> 
            let nouvelleTailleParam = (tailleActuelleParam - (getTaille t)) in
            (* On met à jour l'info du paramètre pour le placer dans LB *)
            modifier_adresse_variable nouvelleTailleParam "LB" h;
            (* On traite les paramètres suivants *)
            analyse_parametres nouvelleTailleParam q;
          | _ -> failwith ("Erreur interne paramètres fonction")
        end
    in
    analyse_parametres 0 (List.rev lp);
    (* Lors de la création du registre, on décale de 3 places pour le registre *)
    let ((nli, tailleBlocLB), tailleBlocSB) = analyse_placement_bloc_fonction li 3 deplSB in
    let (nliFun, nliStatic) = separer_declaration_static nli in
    (AstPlacement.Fonction(info, lp, (nliFun, tailleBlocLB)), (nliStatic, tailleBlocSB))
  | _-> failwith "Erreur interne Placement Fonction"

(* analyse_placement_fonctions : AstType.fonction list -> int -> AstPlacement.fonction list * (AstPlacement.instruction list * int) *)
(* Paramètre info : l'info_ast de la fonction analysée *)
(* Paramètre lp : la liste des info_ast des paramètes de la fonction *)
(* Paramètre li : le bloc des instructions de la fonction *)
(* Analyse le placement des fonctions. *)
(* Renvoie la liste des fonctions et la liste des instructions des variables statiques avec sa taille totale *)

let analyse_placement_fonctions lf deplSB =
  (* On défini une fonction auxiliaire pour prendre en compte le décalage dans le registre SB*)
  let rec aux lst depl =
  match lst with
  | h::q ->
    let (niFun, (liStatic, tailleFonctionSB)) = analyse_placement_fonction h (deplSB + depl) in
      let (nlf, (nliStatic, tailleActuelleFonctionsSB)) = aux q (tailleFonctionSB + depl) in
        (niFun::nlf, (nliStatic@liStatic, tailleActuelleFonctionsSB))
  | [] -> ([],([], depl))
  in
    aux lf 0


(* analyser : AstType.programme -> AstPlacement.programme *)
(* Analyse un programme complet *)
let analyser (AstType.Programme (vg, fonctions, prog)) =
  (* Analyse les variables globales dans SB *)
  let (nvg, taille_var_globales) = analyse_placement_bloc vg 0 "SB" in
  (* Analyse les fonctions avec le décalage SB actuel *)
  let (nlf, (li_static, taille_static)) = analyse_placement_fonctions fonctions taille_var_globales in
  (* Analyse le bloc principal avec le décalage final *)
  let (nprog, _) = analyse_placement_bloc prog taille_static "SB" in
  (* Construit le programme final *)
  AstPlacement.Programme ((nvg, taille_var_globales), nlf, (li_static, taille_static), (nprog, taille_static))