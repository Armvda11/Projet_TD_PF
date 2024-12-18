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
      | InfoFun(_,tr,tp) -> 
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
  (* l'instruction est vide *)
  | AstType.Empty -> (Empty,0)
  (* l'instruction est un affectable *)
  (* | AstType.Affectable (a , e) -> (AstPlacement.Affectation(a,e),0)
  (* l'instruction est un new *)
  | AstType.New t -> (New t,0)
  (* l'instruction est une adresse *)
  | AstType.Adresse ia -> (Adresse ia,0) *)


(* AstType.bloc -> int -> string -> AstPlacement.bloc * int *)
(* bloc, dep, reg -> bloc * taille *)
(* Paramètre li : liste d'instruction à analyser *)
(* Paramètre dep : déplacement actuel par rapport au registre reg *)
(* Paramètre reg : registre de référence (SB ou LB) *)
and analyse_placement_bloc li dep reg = match li with
    | [] -> ([],0)
    | i::q ->
      let (ni,ti) = analyse_placement_instruction i dep reg in
      let (nli,tb) = analyse_placement_bloc q (dep+ti) reg in
      (ni::nli,ti+tb)

(* AstType.fonction -> AstPlacement.fonction *)
(* fonction -> fonction *)
(* Paramètre AstType.Fonction(info,lp,li) : fonction à analyser *)
(* retourne : fonction *)
(* Analyse le placement des variables locales et des paramètres *)
let analyse_placement_fonction (AstType.Fonction(info,lp,li)) =
  (** Fonction auxiliaire pour obtenir la taille d'une instruction *)
  let getTailleInstruction info = match !info with
    | InfoVar(_,t,_,_) -> getTaille t
    | _ -> failwith "type non-attendu dans analyse_placement_fonction"
  in
  (* Fonction auxiliaire pour analyser le placement des paramètres *)
  (* en dessous du LB *)
  let rec analyse_placement_params lp dep = match lp with
    | [] -> 0
    | i::q ->
      let tailleq = analyse_placement_params q dep in
      let taillei = getTailleInstruction i in
      modifier_adresse_variable (-(tailleq+taillei)) "LB" i;
      (tailleq+taillei)
  in
  (* Analyse le placement des variables locales et des paramètres *)
  let (nli,tvarloc) = analyse_placement_bloc li 3 "LB" in 
  let _ = analyse_placement_params lp 0 in
  Fonction(info,lp,(nli,tvarloc))

(* AstType.programme -> AstPlacement.programme *)
(* programme -> programme *)
(* Paramètre AstType.Programme(fonctions,prog) : programme à analyser *)
(* retourne : programme *)
(* Analyse le placement des variables locales et des paramètres *)
let analyser (AstType.Programme(fonctions,prog)) =
  let nlf = List.map analyse_placement_fonction fonctions in
  let nb = analyse_placement_bloc prog 0 "SB" in
  Programme(nlf,nb)
