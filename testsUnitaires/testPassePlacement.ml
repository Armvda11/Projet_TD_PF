open Rat
open Tds
open Ast
open PassePlacementRat
open Type




(* Test pour une déclaration de variable *)
let%test "analyse_placement_instruction_declaration" =
  let dep = 0 in
  let reg = "" in
  let expr = AstType.Entier 42 in
  let info = ref (InfoVar("x", Int, dep, reg)) in
  let decl = AstType.Declaration(info, expr) in
  let result = analyse_placement_instruction decl dep reg in
  match result with
  (* Ajuster le constructeur pour correspondre à AstPlacement *)
  | (AstPlacement.Declaration(_, AstType.Entier _), taille) -> taille = 1  (* Supposons que la taille d'un Int est 4 *)
  | _ -> false


(* Test pour une déclaration statique dans le main *)
let%test "analyse_placement_instruction_declaration_statique" =
  let dep = 0 in
  let reg = "" in
  let expr = AstType.Entier 42 in
  let info = ref (InfoVar("x", Int, dep, reg)) in
  let decl_statique = AstType.DeclarationStatic(info, expr) in
  try
    let _ = analyse_placement_instruction decl_statique dep reg in
    false (* Si aucune exception n'est levée, le test échoue *)
  with
  | Exceptions.DeclarationStatiqueDansMAIN _ -> true
  | _ -> false




(* Test de la transformation d'une déclaration dans la phase de placement *)
let%test "analyse_placement_instruction_declaration" =
  let dep = 0 in
  let reg = "" in
  let expr = AstType.Entier 42 in
  let declaration = AstType.Declaration(ref (InfoVar("x", Int, dep, reg)), expr) in
  let result = analyse_placement_instruction declaration dep reg in
  match result with
  | (AstPlacement.Declaration(_, _), 1) -> true
  | _ -> false

(* Test de la transformation d'une affectation dans la phase de placement *)
(* let%test "analyse_placement_instruction_affectation" =
  let dep = 0 in
  let reg = "" in
  let expr = AstType.Entier 42 in
  let affectable = AstType.Affectable(AstTds.Registre("eax")) in
  let affectation = AstType.Affectation(affectable, expr) in
  let result = analyse_placement_instruction affectation dep reg in
  match result with
  | (AstPlacement.Affectation(_, _), 0) -> true
  | _ -> false *)

(* Test de la transformation d'une instruction de retour dans la phase de placement *)
let%test "analyse_placement_instruction_retour" =
  let dep = 0 in
  let reg = "" in
  let expr = AstType.Entier 42 in
  let info = ref (InfoFun("foo", Int, [Int], [])) in
  let retour = AstType.Retour(expr, info) in
  let result = analyse_placement_instruction retour dep reg in
  match result with
  | (AstPlacement.Retour(_, taille_retour, taille_params), 0) -> 
      taille_retour = 1 && taille_params = 1  
  | _ -> false

(* Test de la transformation d'une conditionnelle dans la phase de placement *)
let%test "analyse_placement_instruction_conditionnelle" =
  let dep = 0 in
  let reg = "" in
  let expr = AstType.Entier 42 in
  let c = AstType.Booleen true in
  let b1 = [AstType.Declaration(ref (InfoVar("x", Int, dep, reg)), expr)] in
  let b2 = [AstType.Declaration(ref (InfoVar("y", Int, dep, reg)), expr)] in
  let cond = AstType.Conditionnelle(c, b1, b2) in
  let result = analyse_placement_instruction cond dep reg in
  match result with
  | (AstPlacement.Conditionnelle(_, (nbt, _), (nbe, _)), 0) -> 
      (List.length nbt = 1) && (List.length nbe = 1)
  | _ -> false