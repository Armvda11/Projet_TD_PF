
open Type
open Tds

open Ast
open AstType
open Exceptions

type t1 = Ast.AstTds.programme
type t2 = Ast.AstType.programme



(* analyse_tds_expression : tds -> AstTds.expression -> AstType.expression *)
(* Paramètre e : l'expression à analyser *)
(* Vérifie le bon type type des expressions *)
(* Erreur si le type de l'expression ne correspond pas au type attendu *)
let rec analyse_type_expression e =
   match e with
  (* l'identifiant est un appel de fonction *)
   | AstTds.AppelFonction (info, le) ->
    begin
      match !info with
      (* vérifie que l'identifiant est un fonction avec les type de retour et type des parametre *)
      | InfoFun(_,tr,tl) -> 
        let nbase = List.map analyse_type_expression le in
        let nle = List.map fst nbase in
        let nlsg = List.map snd nbase in
        (* vérifie que les parametres sont compatibles avec les types attendus *)
        if est_compatible_list tl  nlsg then
          (AstType.AppelFonction (info, nle), tr)
        else
          raise (TypesParametresInattendus (tl, nlsg))
      | _ -> raise (MauvaiseUtilisationIdentifiant "fonction")
    end
    (* l'expression est un booléen on revoie un type Bool  *)
    |AstTds.Booleen b -> (Booleen(b),Bool)
     (* l'expression est un entier , on renvoie un type Int*)
    |AstTds.Entier n -> (Entier(n),Int)
    (* l'expression est un identifiant *)
    | AstTds.Ident info -> 
    begin
      match !info with
      (* (vérifie que l'identifiant est une variable ou une constante) *)
      | InfoVar(_,t,_,_) -> (Ident(info),t)
      | InfoConst(_,_) -> (Ident(info), Int)
      | _ -> failwith "type error : type inconnu"
    end 
    (* l'expression est un unaire n , et donc un rationnel *)
    |AstTds.Unaire (u,exp) -> let (expType,te) = analyse_type_expression exp in
    if (te = Rat) then
        begin
          match u with 
            | Numerateur -> (AstType.Unaire(Numerateur,expType),Int)
            | Denominateur -> (AstType.Unaire(Denominateur,expType),Int)
        end
     else raise (TypeInattendu (te,Rat))
    (* l'expression est un binaire ,on renvoie les opération binaire spéficique au type *)
    |AstTds.Binaire(binaire,exp1,exp2) -> let (ne1,t1) = analyse_type_expression exp1 in
    let (ne2,t2) = analyse_type_expression exp2 in
    begin
      match t1,binaire,t2 with
       | Int,Fraction,Int   -> (Binaire(Fraction,ne1,ne2),Rat)
       | Int,Plus,Int -> (Binaire(PlusInt,ne1,ne2),Int)
       | Rat,Plus,Rat -> (Binaire(PlusRat,ne1,ne2),Rat)
       | Int,Mult,Int  ->  (Binaire(MultInt,ne1,ne2),Int)
       | Rat,Mult,Rat -> (Binaire(MultRat,ne1,ne2),Rat)
       | Int,Equ,Int ->  (Binaire(EquInt,ne1,ne2),Bool)
       | Bool,Equ,Bool -> (Binaire(EquBool,ne1,ne2),Bool)
       | Int,Inf,Int -> (Binaire(Inf,ne1,ne2),Bool)
       | _ -> raise(TypeBinaireInattendu(binaire,t1,t2))   
    end


(* analyse_type_instruction tds -> info_ast option -> AstTds.instruction -> AstType.instruction*)
(* parametre i : l'instruction *)
(* retourne : l'instruction typée *)
let rec analyse_type_instruction i = 
  match i with
  (* l'instruction est empty , on renvoie empty *)
  | AstTds.Empty -> AstType.Empty
  (* l'instruction est une déclaration *)
  | AstTds.Declaration(t, info, e) ->
    (* on analyse le type de l'expression *)
     let (ne,te) = analyse_type_expression e in
      (* on vérifie que le type de l'expression est compatible avec le type de la variable *)
     if est_compatible t  te then
      (*on modifie le type de la variable dans la tds*)
      (modifier_type_variable te info ;
       AstType.Declaration(info,ne))
     else
       (raise (TypeInattendu ( te,t)))
  (* l'instruction est une affectation*)
  | AstTds.Affectation(info, e) -> 
    (* on analyse le type de l'expression *)
    let (ne,te) = analyse_type_expression e in
    begin
    (* on vérifie que l'identifiant est une variable et on vérifie si son type est compatible avec l'affectation *)
    match !info with 
    | InfoVar(_,t,_,_) -> 
      if  est_compatible t te then
       ( modifier_type_variable te info ;
        AstType.Affectation(info,ne))
      else
        raise (TypeInattendu ( te,t))
    | _ -> failwith "erreur interne : affectation sur un non-variable"
      end
  (* l'instruction est un affichage , on fait les affichages distints en fonction des types *)
 | AstTds.Affichage e -> 
    let (ne, te) = analyse_type_expression e in
    begin
      match te with 
      | Int -> AstType.AffichageInt ne
      | Bool -> AstType.AffichageBool ne  
      | Rat -> AstType.AffichageRat ne
      | _ -> failwith "type error : type inconnu"
    end

  (* l'instruction est une conditionnelle , on vérifie que le type de l'expression est un booléen *)
    | AstTds.Conditionnelle(e,b1,b2) ->
      let (ne,te) = analyse_type_expression e in
      if ( est_compatible te  Bool ) then
        let nb1 = analyse_type_bloc b1 in
        let nb2 = analyse_type_bloc b2 in
        Conditionnelle(ne,nb1,nb2)
      else
        raise (TypeInattendu ( te, Bool))
  (* l'instruction est une boucle tant que , on vérifie que le type de l'expression est un booléen *)
  | AstTds.TantQue(e,b) ->
    let (ne,te) = analyse_type_expression e in
    if ( est_compatible te  Bool )  then
      let nb = analyse_type_bloc b in
      TantQue(ne,nb)
    else
      raise (TypeInattendu ( te,Bool))
  (* l'instruction est un retour , on vérifie que le type de l'expression est compatible avec le type de retour de l'expression *)
  | AstTds.Retour(e,info) ->
    let (ne,te) = analyse_type_expression e in
    match !info with
    | InfoFun(_,t,_) -> 
      if t = te then
        Retour(ne,info)
      else
        raise (TypeInattendu ( te,t))
    | _ -> failwith "erreur interne : retour d'une fonction non déclarée"


(* analyse_type_bloc : tds -> AstTds.bloc -> AstType.bloc *)
(* parametre b : le bloc à analyser *)
(* retourne : le bloc typé *)
(* verifie que le type de chaque instruction est correct *)
and analyse_type_bloc b = List.map analyse_type_instruction b

(* analyse_type_fonction : AstTds.fonction -> AstType.fonction *)
(* parametre : AstTds.fonction *)
(* retourne : AstType.fonction *)
(* verifie que le type de chaque paramètre est correct et que le type de retour est correct *)
(* et que le type de chaque instruction est correct *)
let analyse_type_fonction (AstTds.Fonction(t, n, lp, li)) = 
  (* Associer les types aux paramètres dans la table des symboles *)
  List.iter (fun (tp, p) -> modifier_type_variable tp p) lp;
  (* Mettre à jour les informations de type de la fonction dans la TDS *)
  modifier_type_fonction t (List.map fst lp) n;
  (* Extraire les paramètres typés *)
  let liste_param = List.map snd lp in
  (* Analyser le corps de la fonction *)
  let nli = analyse_type_bloc li in
  (* Construire et retourner la fonction typée *)
  Fonction(n, liste_param, nli)


(* analyse_type_programme : AstTds.programme -> AstType.programme *)
(* parametre : AstTds.programme *)
(* retourne : AstType.programme *)
let analyser (AstTds.Programme(fonctions, prog)) =  
  let nf = List.map analyse_type_fonction fonctions in
  let nb = analyse_type_bloc prog in
  AstType.Programme(nf, nb)
