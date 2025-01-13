(* Module de la passe de gestion des identifiants *)
(* doit être conforme à l'interface Passe *)
open Tds
open Exceptions
open Ast
type t1 = Ast.AstSyntax.programme
type t2 = Ast.AstTds.programme

type affouexpTds =
  | Affectable of AstTds.affectable
  | Expression of AstTds.expression


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
      (* On cherche l'identifiant dans la TDS globalement *)
      match chercherGlobalement tds n with
      | None -> raise (IdentifiantNonDeclare n) (* L'identifiant n'a pas été trouvé dans la TDS globale, il est non déclaré *)
      | Some info ->  (* L'identifiant est trouvé dans la TDS globale *)
        begin
          (* Vérification si l'identifiant est utilisé correctement *)
          match !info with
          | InfoVar _ -> AstTds.Ident info (* L'identifiant est correctement utilisé, on crée un identifiant dans l'AstTds *)
          | InfoConst (_, v) -> if modifiable then raise (MauvaiseUtilisationIdentifiant n) else
            AstTds.Ident info (* Utilisation correcte de la constante *)
          | _ -> raise (MauvaiseUtilisationIdentifiant n)
        end
    end
  (* L'affectable est un pointeur *)
  | AstSyntax.Deref a ->
    let na = analyse_tds_affectable tds a false in
    AstTds.Deref na

(* analyse_tds_expression : tds -> AstSyntax.expression -> AstTds.expression *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre e : l'expression à analyser *)
(* Vérifie la bonne utilisation des identifiants et transforme l'expression
en une expression de type AstTds.expression *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_tds_expression tds e = match e with

  (* L'identifiant est un appel de fontion *)
  | AstSyntax.AppelFonction(n, l) ->
    begin
      match chercherGlobalement tds n with
        | None ->
          (* L'identifiant n'est pas trouvé dans la TDS globale *)
          raise (Exceptions.IdentifiantNonDeclare n)
        | Some info_tds ->
          begin
            match info_ast_to_info info_tds with
            | InfoFun(_, _, _, params) ->
              (* Analyse des arguments passés *)
              let analysed_args = List.map (analyse_tds_expression tds) l in

              (* Compléter avec les paramètres par défaut *)
              let rec completer_arguments params args =
                match params, args with
                | [], [] -> [] (* Aucun paramètre restant, aucun argument manquant *)
                | Some (AstSyntax.Default(e)) :: rest_params, [] ->
                    (* Paramètre avec valeur par défaut et argument manquant *)
                    (analyse_tds_expression tds e) :: completer_arguments rest_params []
                | None :: _, [] ->
                    (* Paramètre obligatoire manquant *)
                    raise (Exceptions.TypesParametresInattendus ([], []))
                | _ :: rest_params, arg :: rest_args ->
                    (* Argument fourni, continuer *)
                    arg :: completer_arguments rest_params rest_args
                | [], _ :: _ ->
                    (* Trop d'arguments fournis *)
                    raise (Exceptions.TypesParametresInattendus ([], []))
              in

              let final_args = completer_arguments params analysed_args in
              AstTds.AppelFonction(info_tds, final_args)

            | _ -> raise (MauvaiseUtilisationIdentifiant n)
          end
    end

  (* L'identifiant est un affectable *)
  | AstSyntax.Affectable(a) ->
    let na = analyse_tds_affectable tds a false in
    AstTds.Affectable na
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
  | AstSyntax.DeclarationStatic (t, n, e) -> 
    let ne = analyse_tds_expression tds e in
      let info = InfoVarStatic( n,t, 0, "", false) in
        let ia = info_to_info_ast info in
          ajouter tds n ia;
          AstTds.DeclarationStatic (t, ia, ne)
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
            let info = InfoVar (n,t, 0, "") in
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




let analyse_variable_globale tds (AstSyntax.DeclarationGlobale(t,n,e)) =
  match chercherLocalement tds n with
  | None -> 
    let ne = analyse_tds_expression tds e in
    let info = InfoVar(n, t, 0, "") in
    let ia = info_to_info_ast info in
    ajouter tds n ia;
    AstTds.Declaration(t, ia, ne)
  | Some _ -> raise (DoubleDeclaration n)




(* analyse_tds_fonction : tds -> AstSyntax.fonction -> AstTds.fonction *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre : la fonction à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme la fonction
en une fonction de type AstTds.fonction *)
(* Erreur si mauvaise utilisation des identifiants *)
let analyse_tds_fonction tds (AstSyntax.Fonction(t, n, lp, li)) =
  match chercherGlobalement tds n with
  | None ->
      (* Création de l'information de la fonction avec les valeurs par défaut des paramètres *)
      let defauts = List.map (fun (_, _, def_opt) -> def_opt) lp in
      let info_func = InfoFun (n, t, [], defauts) in  (* Le quatrième argument est la liste des valeurs par défaut *)
      let info_func_ast = ref info_func in
      ajouter tds n info_func_ast;

      (* Création de la TDS pour les paramètres *)
      let paramtds = creerTDSFille tds in

      (* Fonction locale pour ajouter un paramètre à la TDS *)
      let ajouter_param (t, n, def_opt) =
        match chercherLocalement paramtds n with
        | None ->
            let info = InfoVar (n, t, 0, "") in
            let ia = ref info in
            ajouter paramtds n ia;
            (t, ia, def_opt) (* Inclure la valeur par défaut dans le tuple *)
        | Some _ -> raise (DoubleDeclaration n)
      in

      (* Analyse des paramètres avec gestion des valeurs par défaut *)
      let lpia = List.map ajouter_param lp in

      (* Création de la TDS pour le corps de la fonction *)
      let bloctds = creerTDSFille paramtds in
      let nbloc = analyse_tds_bloc bloctds (Some info_func_ast) li in

      (* Retourne la fonction transformée avec l'AST TDS *)
      AstTds.Fonction(t, info_func_ast, List.map (fun (t, ia, _) -> (t, ia)) lpia, nbloc)

  | Some _ -> raise (DoubleDeclaration n)




let analyse_gestion_id_variable_globale tds (AstSyntax.DeclarationGlobale(t, n, e)) = 
  match chercherLocalement tds n with
  | None -> 
    let ne = analyse_tds_expression tds e in
    let info = InfoVar(n, t, 0, "") in
    let ia = info_to_info_ast info in
    ajouter tds n ia;
    AstTds.Declaration(t, ia, ne)
  | Some _ -> raise (DoubleDeclaration n)

      (* analyser : AstSyntax.programme -> AstTds.programme *)
(* Paramètre : le programme à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme le programme
en un programme de type AstTds.programme *)
(* Erreur si mauvaise utilisation des identifiants *)
let analyser (AstSyntax.Programme (vg, fonctions,prog)) =
  let tds = creerTDSMere () in
  let nvg = List.map (analyse_gestion_id_variable_globale tds) vg in
  let nf = List.map (analyse_tds_fonction tds) fonctions in
  let nb = analyse_tds_bloc tds None prog in
  AstTds.Programme (nvg, nf, nb)