/* Imports. */

%{

open Type
open Ast.AstSyntax
%}


%token <int> ENTIER
%token <string> ID
%token RETURN
%token VIRG
%token PV
%token AO
%token AF
%token PF
%token PO
%token EQUAL
%token CONST
%token PRINT
%token IF
%token ELSE
%token WHILE
%token BOOL
%token INT
%token RAT
%token CO
%token CF
%token SLASH
%token NUM
%token DENOM
%token TRUE
%token FALSE
%token PLUS
%token MULT
%token INF
%token EOF
(* pointeur *)
%token NEW
%token NULL
%token REF
(* static *)
%token STATIC


(* Type de l'attribut synthétisé des non-terminaux *)
%type <programme> prog
%type <variable_globale> globale
%type <instruction list> bloc
%type <fonction> fonc
%type <instruction> i
%type <typ> typ
%type <expression> e 
%type <affectable>  af (* Affectable *)




(* Type et définition de l'axiome *)
%start <Ast.AstSyntax.programme> main

%%
(* variable globale *)
globale : STATIC t=typ n=ID EQUAL e1=e PV {DeclarationGlobale (t,n,e1)}

(*variable locale*)
main : lfi=prog EOF     {lfi}

prog : lf=fonc* ID li=bloc  {Programme (lf,li)}

fonc : t=typ n=ID PO lp=separated_list(VIRG,param) PF li=bloc {Fonction(t,n,lp,li)}

param : t=typ n=ID  {(t,n)}

bloc : AO li=i* AF      {li}



(* Affectable *)
af :
| MULT af=af              {Deref af}
| n=ID                         {Ident n} (* Identifiant  affectable *)

i :
| t=typ n=ID EQUAL e1=e PV          {Declaration (t,n,e1)}
| n=af EQUAL e1=e PV                 {Affectation (n,e1)}
| CONST n=ID EQUAL e=ENTIER PV      {Constante (n,e)}
| PRINT e1=e PV                     {Affichage (e1)}
| IF exp=e li1=bloc ELSE li2=bloc   {Conditionnelle (exp,li1,li2)}
| WHILE exp=e li=bloc               {TantQue (exp,li)}
| RETURN exp=e PV                   {Retour (exp)}
// variable static dans une instruction 
| STATIC t=typ n=ID EQUAL e1=e PV {DeclarationStatic (t,n,e1)}


typ :
| t=typ MULT {Pointeur t}  (* Pointeur sur un type *) 
| BOOL    {Bool}
| INT     {Int}
| RAT     {Rat}

e : 
| a1=af                 {Affectable a1} (* Affectable *)
| n=ID PO lp=separated_list(VIRG,e) PF   {AppelFonction (n,lp)}
| CO e1=e SLASH e2=e CF   {Binaire(Fraction,e1,e2)}
| TRUE                    {Booleen true}
| FALSE                   {Booleen false}
| e=ENTIER                {Entier e}
| NUM e1=e                {Unaire(Numerateur,e1)}
| DENOM e1=e              {Unaire(Denominateur,e1)}
| PO e1=e PLUS e2=e PF    {Binaire (Plus,e1,e2)}
| PO e1=e MULT e2=e PF    {Binaire (Mult,e1,e2)}
| PO e1=e EQUAL e2=e PF   {Binaire (Equ,e1,e2)}
| PO e1=e INF e2=e PF     {Binaire (Inf,e1,e2)}
| PO NEW t1=typ PF        {New t1}
| PO exp=e PF             {exp}
| REF n=ID                {Adresse n}
| NULL                    {Null}