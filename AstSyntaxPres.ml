(* 
Ast syntax de présentation pour gérer les problèmes de dépendance lié  aux 

Dependency cycle between:     
_build/default/.rat.objs/rat__Tds.intf.all-deps
-> _build/default/.rat.objs/rat__Ast.impl.all-deps
-> _build/default/.rat.objs/rat__Tds.intf.all-deps
 *)

 open Type

 (* Interface des arbres abstraits *)
 module type Ast =
 sig
    type expression
    type instruction
    type fonction
    type programme
    type affectable
    type variable_globale
 end
 
 
 (* *************************************** *)
 (* AST après la phase d'analyse syntaxique *)
 (* *************************************** *)

 (* Opérateurs unaires de Rat *)
 type unaire = Numerateur | Denominateur
 
 (* Opérateurs binaires de Rat *)
 type binaire = Fraction | Plus | Mult | Equ | Inf
 
 type affectable = 
   | Ident of string
   | Deref of affectable
 
 
 
 
 (* Expressions de Rat *)
 type expression =
   (* Appel de fonction représenté par le nom de la fonction et la liste des paramètres réels *)
   | AppelFonction of string * expression list
   (* Booléen *)
   | Booleen of bool
   (* Entier *)
   | Entier of int
   (* Opération unaire représentée par l'opérateur et l'opérande *)
   | Unaire of unaire * expression
   (* Opération binaire représentée par l'opérateur, l'opérande gauche et l'opérande droite *)
   | Binaire of binaire * expression * expression
   (* Affectable *)
   | Affectable of affectable
   (* Null *)
   | Null 
   (* Nouveau typ *)
   | New of typ
   (* Adresse d'une variable *)
   | Adresse of string
 
 type variable_globale =  DeclarationGlobale of typ * string * expression
 (* Instructions de Rat *)
 type bloc = instruction list
 and instruction =
   | DeclarationStatic of typ * string * expression
   (* Déclaration de variable représentée par son type, son nom et l'expression d'initialisation *)
   | Declaration of typ * string * expression
   (* Affectation d'une variable représentée par son nom et la nouvelle valeur affectée *)
   | Affectation of affectable * expression
   (* Déclaration d'une constante représentée par son nom et sa valeur (entier) *)
   | Constante of string * int
   (* Affichage d'une expression *)
   | Affichage of expression
   (* Conditionnelle représentée par la condition, le bloc then et le bloc else *)
   | Conditionnelle of expression * bloc * bloc
   (*Boucle TantQue représentée par la conditin d'arrêt de la boucle et le bloc d'instructions *)
   | TantQue of expression * bloc
   (* return d'une fonction *)
   | Retour of expression
 
 
 
 type default = Default of expression
 (* Structure des fonctions de Rat *)
 (* type de retour - nom - liste des paramètres (association type et nom) - corps de la fonction *)
 type fonction = Fonction of typ * string * (typ * string * default option) list * bloc
 
 (* Structure d'un programme Rat *)
 (* liste de fonction - programme principal *)
 type programme = Programme of variable_globale list * fonction list * bloc
