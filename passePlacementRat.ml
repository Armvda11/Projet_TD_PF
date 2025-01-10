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
  |AstType.DeclarationStatic(info,e) ->
      (* Récupère la taille de la variable statique et met à jour son adresse dans SB *)
      let taille = getTaille (match !info with InfoVarStatic(_, t, _, _,_) -> t | _ -> failwith "Type non attendu") in
      modifier_adresse_variable dep "SB" info;
      (* Renvoie l'instruction mise à jour et la taille consommée *)
      (AstPlacement.DeclarationStatic (info, e), taille)
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

(* AstType.fonction -> AstPlacement.fonction *)
(* fonction -> fonction *)
(* Paramètre AstType.Fonction(info,lp,li) : fonction à analyser *)
(* retourne : fonction *)
(* Analyse le placement des variables locales et des paramètres *)
let analyse_placement_fonction (AstType.Fonction(info, lp, li)) =
  (* Analyse le placement des paramètres *)
  let analyse_placement_params lp =
    (* Calcule les déplacements en partant de 0, en remontant dans la pile *)
    List.fold_right (fun param taille_courante ->
      match !param with
      | InfoVar(_, t, _, _) ->
          let taille = getTaille t in
          modifier_adresse_variable (-taille_courante - taille) "LB" param;
          taille_courante + taille
      | _ -> failwith "Type non attendu pour un paramètre"
    ) lp 0
  in
  (* Analyse le placement des variables locales *)
  let (nli, taille_var_locales) = analyse_placement_bloc li 3 "LB" in
  (* Traite les paramètres *)
  let _ = analyse_placement_params lp in
  (* Renvoie la fonction mise à jour avec les placements *)
  AstPlacement.Fonction (info, lp, (nli, taille_var_locales))



(* analyse_placement_fonctions : AstType.fonction list -> int -> AstPlacement.fonction list * (AstPlacement.instruction list * int) *)
(* Analyse une liste de fonctions et gère le placement des variables statiques dans SB *)
let analyse_placement_fonctions fonctions depSB =
  let rec aux lf depSB =
    match lf with
    | [] -> ([], ([], depSB))
    | f :: q ->
      (* Analyse une fonction et récupère ses instructions statiques *)
      let nf = analyse_placement_fonction f in
      let (nlf, (li_static, taille_static)) = aux q depSB in
      (* Combine les résultats *)
      (nf :: nlf, (li_static, taille_static))
  in aux fonctions depSB

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