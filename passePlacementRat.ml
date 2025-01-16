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
  | [] -> ([], 0), 0  (* Cas de base : liste vide *)
  | h :: q ->
      (* Analyse de l'instruction courante *)
      let ((instr, tailleLB), tailleSB) =
        match h with
        | AstType.DeclarationStatic (info, e) ->
            (* Traitement des variables statiques locales *)
            (match info_ast_to_info info with
             | InfoVar(_, t, _, _) ->
                 let taille = getTaille t in
                 modifier_adresse_variable deplSB "SB" info;
                 ((AstPlacement.DeclarationStatic(info, e), 0), taille)
             | _ -> failwith "Erreur interne : mauvaise utilisation de DeclarationStatic")
        | _ ->
            (* Traitement standard pour les autres instructions *)
            (analyse_placement_instruction h deplLB "LB", 0)
      in
      (* Analyse récursive des instructions suivantes *)
      let ((instrs_suivants, tailleBlocLB), tailleBlocSB) =
        analyse_placement_bloc_fonction q (deplLB + tailleLB) (deplSB + tailleSB)
      in
      (* Combine les résultats *)
      ((instr :: instrs_suivants, tailleLB + tailleBlocLB), tailleSB + tailleBlocSB)




(* analyse_placement_fonction : AstType.fonction -> int -> AstPlacement.fonction * (AstPlacement.instruction list * int) *)
(* Paramètre info : l'info_ast de la fonction analysée *)
(* Paramètre lp : la liste des info_ast des paramètres de la fonction *)
(* Paramètre li : le bloc des instructions de la fonction *)
(* Analyse le placement d'une fonction. *)
(* Renvoie la fonction et la liste des instructions des variables statiques avec leur taille *)
let analyse_placement_fonction (AstType.Fonction(info, lp, li)) deplSB =
  (* Vérification que l'information est bien une fonction *)
  match info_ast_to_info info with
  | InfoFun(_, _, _, _) ->
    (* Analyse des paramètres de la fonction *)
    let analyser_parametres tailleActuelleParam lst =
      List.fold_left (fun tailleActuelle h ->
        match info_ast_to_info h with
        | InfoVar(_, t, _, _) ->
            let nouvelleTailleParam = tailleActuelle - getTaille t in
            modifier_adresse_variable nouvelleTailleParam "LB" h; (* Mise à jour des adresses *)
            nouvelleTailleParam
        | _ -> failwith "Erreur interne paramètres fonction"
      ) tailleActuelleParam lst
    in
    let _ = analyser_parametres 0 (List.rev lp) in (* Traiter les paramètres *)

    (* Analyse du bloc d'instructions de la fonction *)
    let ((nli, tailleBlocLB), tailleBlocSB) = analyse_placement_bloc_fonction li 3 deplSB in

    (* Séparation des déclarations statiques et des instructions *)
    let static_elements, function_elements =
      List.partition (function AstPlacement.DeclarationStatic _ -> true | _ -> false) nli
    in

    (* Retourner le résultat final *)
    (AstPlacement.Fonction(info, lp, (function_elements, tailleBlocLB)), 
     (static_elements, tailleBlocSB))
  
  | _ -> failwith "Erreur interne Placement Fonction"




(* analyse_fonctions : AstType.fonction list -> int -> AstPlacement.fonction list * (AstPlacement.instruction list * int) *)
(* Paramètre lf : la liste des fonctions à analyser *)
(* Paramètre deplSB : le déplacement actuel dans le registre SB *)
(* Analyse le placement de plusieurs fonctions *)
(* Renvoie la liste des fonctions analysées et la liste des instructions des variables statiques avec leur taille *)
let analyse_fonctions lf deplSB =
  let rec aux lst depl =
    match lst with
    | [] -> ([], ([], depl)) (* Cas de base : liste vide *)
    | h :: q ->
        (* Analyse de la fonction courante *)
        let (niFun, (liStatic, tailleFonctionSB)) = analyse_placement_fonction h (deplSB + depl) in
        (* Appel récursif pour les fonctions restantes *)
        let (nlf, (nliStatic, tailleTotalSB)) = aux q (tailleFonctionSB + depl) in
        (* Construction du résultat *)
        (niFun :: nlf, (liStatic @ nliStatic, tailleTotalSB))
  in
  aux lf 0






(* analyse_placement_bloc : AstType.bloc -> int -> string -> AstPlacement.bloc * int *)
(* bloc, dep, reg -> bloc * taille *)
let analyser (AstType.Programme (vg, fonctions, prog)) =
  (* Définir une fonction pour l'analyse du programme *)
  let analyser_programme vg fonctions prog =
    (* Traiter les variables globales dans SB *)
    let (nvg, globales) = analyse_placement_bloc vg 0 "SB" in
    (* Traiter les fonctions en fonction des variables globales analysées *)
    let (nlf, (li_static, taille_static)) = analyse_fonctions fonctions globales in
    (* Calculer le déplacement de SB après les variables statiques et globales *)
    let deplSB = taille_static + globales in
    (*  Traiter le bloc principal avec le déplacement actuel de SB *)
    let bloc_main = analyse_placement_bloc prog deplSB "SB" in
    (* Retourner le programme complet *)
    (nvg, globales), nlf, (li_static, deplSB), bloc_main
  in

  (* Appliquer l'analyse sur le programme donné *)
  let (blocGlobale, nlf, blocStatique, bloc_main) = analyser_programme vg fonctions prog in

  (* Construire le programme final avec les informations traitées *)
  AstPlacement.Programme (blocGlobale, nlf, blocStatique, bloc_main)
