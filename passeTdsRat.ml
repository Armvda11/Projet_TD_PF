(* Module de la passe de gestion des identifiants *)
(* doit être conforme à l'interface Passe *)
open Tds
open Exceptions
open Ast
type t1 = Ast.AstSyntax.programme
type t2 = Ast.AstTds.programme

(* analyse_tds_affectable : tds -> AstSyntax.affectable -> AstTds.affectable *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre af : l'affectable à analyser *)
(* Parmaètre modifiable : l'affectable est-elle modifiable ? *)
(* Vérifie la bonne utilisation des identifiants et transforme l'affectable *)
(* en un affectable de type AstTds.affectable *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_tds_affectable tds af modifiable = 
  match af with
  (* L'affectable est un identifiant *)
  | AstSyntax.Ident n -> 
    begin
      (* On cherche l'identifiant dans la TDS globalement*)
      match chercherGlobalement tds n with
      | None -> raise (IdentifiantNonDeclare n) (* L'identifiant n'a pas été trouvé dans la TDS globale, il est non déclaré *)
      | Some info ->  (* L'identifiant est trouvé dans la TDS globale *)
        begin
          (* Vérification si l'identifiant est utilisé correctement *)
          match !info with
          | InfoVar _ -> AstTds.Ident info (* L'identifiant est correctement utilisé, on crée un identifiant dans l'AstTds *)
          | InfoConst _ -> if modifiable then raise (MauvaiseUtilisationIdentifiant n) else
            AstTds.Ident(info)
          | _ -> raise (MauvaiseUtilisationIdentifiant n)
        end
    end
  (* L'affectable est un pointeur *)
  | AstSyntax.Deref n ->  AstTds.Deref (analyse_tds_affectable tds n false)  

(* analyse_tds_expression : tds -> AstSyntax.expression -> AstTds.expression *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre e : l'expression à analyser *)
(* Vérifie la bonne utilisation des identifiants et transforme l'expression
en une expression de type AstTds.expression *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_tds_expression tds e = match e with
  (* L'identifiant est un appel de fontion *)
  | AstSyntax.AppelFonction(id, le) -> 
    begin
      match chercherGlobalement tds id with
        | None -> (* L'identifiant n'a pas été trouvé dans la TDS globale, il est non déclaré *)
          raise (IdentifiantNonDeclare id)
        | Some info ->
          (* Vérification si l'identifiant est utilisé correctement *)
          (match !info with
          | InfoFun _ -> (* L'identifiant est une fonction , on crée un appel de fonction dans l'AstTds *) 
            AstTds.AppelFonction(info, (List.map (analyse_tds_expression tds) le))
          | _ ->  (* L'identifiant n'est pas une fonction, mauvaise utilisation *)
            raise (MauvaiseUtilisationIdentifiant id))
    end
  (* L'identifiant est un affectable *)
  | AstSyntax.Affectable(af) -> AstTds.Affectable(analyse_tds_affectable tds af false)
  (* Les booleens ne changent pas entre l'AstSyntax et l'AstTds *)
  | AstSyntax.Booleen(b) -> AstTds.Booleen(b)
  (* Les entiers ne changent pas entre l'AstSyntax et l'AstTds *)
  | AstSyntax.Entier(nb) -> AstTds.Entier(nb)
  (* L'identifiant est un unaire *)
  | AstSyntax.Unaire(op, expr) -> 
    (* On récupère la nouvelle expression qui correspond à l'AstTds et on crée notre expression de type AstTds *)
    let expr_tds = analyse_tds_expression tds expr in
    AstTds.Unaire(op, expr_tds)
  (* L'identifiant est un binaire *)
  | AstSyntax.Binaire(op, expr1, expr2) ->
    (* On récupère les deux nouvelles expressions qui correspondent à l'AstTds et on crée notre expression de type AstTds *)
    let nexpr1 = analyse_tds_expression tds expr1 in
    let nexpr2 = analyse_tds_expression tds expr2 in
    AstTds.Binaire(op, nexpr1, nexpr2)
  (* L'identifiant est une adresse *)
  | AstSyntax.Adresse n -> 
    begin
      (* On cherche l'identifiant dans la TDS globalement*)
      match chercherGlobalement tds n with
      | None -> raise (IdentifiantNonDeclare n) (* L'identifiant n'a pas été trouvé dans la TDS globale, il est non déclaré *)
      | Some info -> 
        begin
          match !info with
          | InfoVar _ -> AstTds.Adresse info
          | _ -> raise (MauvaiseUtilisationIdentifiant n)
        end
    end
  | AstSyntax.Null -> AstTds.Null
  | AstSyntax.New t -> AstTds.New t


(* analyse_tds_instruction : tds -> info_ast option -> AstSyntax.instruction -> AstTds.instruction *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre oia : None si l'instruction i est dans le bloc principal,
                   Some ia où ia est l'information associée à la fonction dans laquelle est l'instruction i sinon *)
(* Paramètre i : l'instruction à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme l'instruction
en une instruction de type AstTds.instruction *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_tds_instruction tds oia i =
  match i with
  | AstSyntax.Declaration (t, n, e) ->
      begin
        match chercherLocalement tds n with
        | None ->
            (* L'identifiant n'est pas trouvé dans la tds locale,
            il n'a donc pas été déclaré dans le bloc courant *)
            (* Vérification de la bonne utilisation des identifiants dans l'expression *)
            (* et obtention de l'expression transformée *)
            let ne = analyse_tds_expression tds e in
            (* Création de l'information associée à l'identfiant *)
            let info = InfoVar (n,Undefined, 0, "") in
            (* Création du pointeur sur l'information *)
            let ia = info_to_info_ast info in
            (* Ajout de l'information (pointeur) dans la tds *)
            ajouter tds n ia;
            (* Renvoie de la nouvelle déclaration où le nom a été remplacé par l'information
            et l'expression remplacée par l'expression issue de l'analyse *)
            AstTds.Declaration (t, ia, ne)
        | Some _ ->
            (* L'identifiant est trouvé dans la tds locale,
            il a donc déjà été déclaré dans le bloc courant *)
            raise (DoubleDeclaration n)
      end
  | AstSyntax.Affectation (n,e) ->
      (* Vérification de la bonne utilisation des identifiants dans l'affectable *)
      (* et obtention de l'affectable transformé *)
      let naf = analyse_tds_affectable tds n true in
      let ne = analyse_tds_expression tds e in
      AstTds.Affectation (naf, ne)
      (* begin
        match chercherGlobalement tds n with
        | None ->
          (* L'identifiant n'est pas trouvé dans la tds globale. *)
          raise (IdentifiantNonDeclare n)
        | Some info ->
          (* L'identifiant est trouvé dans la tds globale,
          il a donc déjà été déclaré. L'information associée est récupérée. *)
          begin
            match info_ast_to_info info with
            | InfoVar _ ->
              (* Vérification de la bonne utilisation des identifiants dans l'expression *)
              (* et obtention de l'expression transformée *)
              let ne = analyse_tds_expression tds e in
              (* Renvoie de la nouvelle affectation où le nom a été remplacé par l'information
                 et l'expression remplacée par l'expression issue de l'analyse *)
              AstTds.Affectation (info, ne)
            |  _ ->
              (* Modification d'une constante ou d'une fonction *)
              raise (MauvaiseUtilisationIdentifiant n)
          end
      end *)
  | AstSyntax.Constante (n,v) ->
      begin
        match chercherLocalement tds n with
        | None ->
          (* L'identifiant n'est pas trouvé dans la tds locale,
             il n'a donc pas été déclaré dans le bloc courant *)
          (* Ajout dans la tds de la constante *)
          ajouter tds n (info_to_info_ast (InfoConst (n,v)));
          (* Suppression du noeud de déclaration des constantes devenu inutile *)
          AstTds.Empty
        | Some _ ->
          (* L'identifiant est trouvé dans la tds locale,
          il a donc déjà été déclaré dans le bloc courant *)
          raise (DoubleDeclaration n)
      end
  | AstSyntax.Affichage e ->
      (* Vérification de la bonne utilisation des identifiants dans l'expression *)
      (* et obtention de l'expression transformée *)
      let ne = analyse_tds_expression tds e in
      (* Renvoie du nouvel affichage où l'expression remplacée par l'expression issue de l'analyse *)
      AstTds.Affichage (ne)
  | AstSyntax.Conditionnelle (c,t,e) ->
      (* Analyse de la condition *)
      let nc = analyse_tds_expression tds c in
      (* Analyse du bloc then *)
      let tast = analyse_tds_bloc tds oia t in
      (* Analyse du bloc else *)
      let east = analyse_tds_bloc tds oia e in
      (* Renvoie la nouvelle structure de la conditionnelle *)
      AstTds.Conditionnelle (nc, tast, east)
  | AstSyntax.TantQue (c,b) ->
      (* Analyse de la condition *)
      let nc = analyse_tds_expression tds c in
      (* Analyse du bloc *)
      let bast = analyse_tds_bloc tds oia b in
      (* Renvoie la nouvelle structure de la boucle *)
      AstTds.TantQue (nc, bast)
  | AstSyntax.Retour (e) ->
      begin
      (* On récupère l'information associée à la fonction à laquelle le return est associée *)
      match oia with
        (* Il n'y a pas d'information -> l'instruction est dans le bloc principal : erreur *)
      | None -> raise RetourDansMain
        (* Il y a une information -> l'instruction est dans une fonction *)
      | Some ia ->
        (* Analyse de l'expression *)
        let ne = analyse_tds_expression tds e in
        AstTds.Retour (ne,ia)
      end


(* analyse_tds_bloc : tds -> info_ast option -> AstSyntax.bloc -> AstTds.bloc *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre oia : None si le bloc li est dans le programme principal,
                   Some ia où ia est l'information associée à la fonction dans laquelle est le bloc li sinon *)
(* Paramètre li : liste d'instructions à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme le bloc en un bloc de type AstTds.bloc *)
(* Erreur si mauvaise utilisation des identifiants *)
and analyse_tds_bloc tds oia li =
  (* Entrée dans un nouveau bloc, donc création d'une nouvelle tds locale
  pointant sur la table du bloc parent *)
  let tdsbloc = creerTDSFille tds in
  (* Analyse des instructions du bloc avec la tds du nouveau bloc.
     Cette tds est modifiée par effet de bord *)
   let nli = List.map (analyse_tds_instruction tdsbloc oia) li in
   (* afficher_locale tdsbloc ; *) (* décommenter pour afficher la table locale *)
   nli


(* analyse_tds_fonction : tds -> AstSyntax.fonction -> AstTds.fonction *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre : la fonction à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme la fonction
en une fonction de type AstTds.fonction *)
(* Erreur si mauvaise utilisation des identifiants *)

let analyse_tds_fonction tds (AstSyntax.Fonction(t,n,lp,li))  =
  match chercherGlobalement tds n with
    | None -> 
      (* L'identifiant de la fonction n'a pas été trouvé dans la TDS globale, il est donc non déclaré *)
      (* On crée une nouvelle InfoFun pour la fonction et on l'ajoute à la TDS *)
      let info_func = InfoFun (n,t,[]) in
      (* On crée une référence pour pouvoir modifier l'information de la fonction plus tard *)
      let info_func_ast = ref info_func in
      ajouter tds n info_func_ast; (* On ajoute la fonction à la TDS *)

      (* On crée une nouvelle TDS fille pour les paramètres de la fonction *)
      let paramtds = creerTDSFille tds in

       (* Fonction locale pour ajouter un paramètre à la TDS des paramètres *)
      let ajouter_param (t,n) =
        begin
         (* On vérifie si le paramètre est déjà déclaré localement *)
        match chercherLocalement paramtds n with
        | None ->
          (* Le paramètre n'est pas déclaré, on l'ajoute à la TDS des paramètres *)
            let info = InfoVar (n,t,0,"") in
            let ia = ref info in
            ajouter paramtds n ia;
            (t,ia)
        | Some _ -> raise (DoubleDeclaration n)
        end
      in
      (* On ajoute tous les paramètres à la TDS des paramètres *)
      let lpia = List.map ajouter_param lp in

    (* On crée une nouvelle TDS petite-fille pour le bloc de la fonction *)
      let bloctds = creerTDSFille paramtds in
     (* On analyse le bloc de la fonction avec la nouvelle TDS petite-fille *)
      let nbloc = analyse_tds_bloc bloctds (Some info_func_ast) li in
      (* On retourne la fonction transformée en type AstTds.fonction *)
      AstTds.Fonction (t,info_func_ast, lpia, nbloc)
    
    | Some _ -> (* L'identifiant de la fonction est déjà déclaré globalement, on lève une exception *)
      raise (DoubleDeclaration n)
    
(* analyser : AstSyntax.programme -> AstTds.programme *)
(* Paramètre : le programme à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme le programme
en un programme de type AstTds.programme *)
(* Erreur si mauvaise utilisation des identifiants *)
let analyser (AstSyntax.Programme (fonctions,prog)) =
  let tds = creerTDSMere () in
  let nf = List.map (analyse_tds_fonction tds) fonctions in
  let nb = analyse_tds_bloc tds None prog in
  AstTds.Programme (nf,nb)