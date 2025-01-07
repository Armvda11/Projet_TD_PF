open Rat
open Compilateur

(* Changer le chemin d'accès du jar. *)

let runtamcmde = "java -jar ../../../../projet_Tests/runtam.jar"
(* let runtamcmde = "java -jar /mnt/n7fs/.../tools/runtam/runtam.jar" *)

(* Execute the TAM code obtained from the rat file and return the ouptut of this code *)
let runtamcode cmde ratfile =
  let tamcode = compiler ratfile in
  let (tamfile, chan) = Filename.open_temp_file "test" ".tam" in
  
  output_string chan tamcode;
  close_out chan;
  let ic = Unix.open_process_in (cmde ^ " " ^ tamfile) in
  let printed = input_line ic in
  close_in ic;
  (*Sys.remove tamfile;    à commenter si on veut étudier le code TAM. *)
  String.trim printed

(* Compile and run ratfile, then print its output *)
let runtam ratfile =
  print_string (runtamcode runtamcmde ratfile)

(****************************************)
(** Chemin d'accès aux fichiers de test *)
(****************************************)

let pathFichiersRat = "../../../../projet_Tests/tam/fichiersRat/"

(**********)
(*  TESTS *)
(**********)

(* requires ppx_expect in jbuild, and `opam install ppx_expect` *)

(*************)
(* POINTEURS *)
(*************)

(* Tester les opérations générées pour le déréférencement et l’assignation.
Vérifier l’absence d’erreurs lors de l’utilisation d’un pointeur null.
*)

let%expect_test "testPointeur1" =
  runtam (pathFichiersRat^"testPointeur1.rat");
  [%expect{| 1048575 |}]

  let%expect_test "testPointeurRat" =
  runtam (pathFichiersRat^"testPointeurRat.rat");
  [%expect{| [2/2] |}]


let%expect_test "testPointeurFun" =
  runtam (pathFichiersRat^"testPointeurFun.rat");
  [%expect{| 24[1/4] |}]


let%expect_test "testPointeurFunParam" =
  runtam (pathFichiersRat^"testPointeurFunParam.rat");
  [%expect{| tam.TamException: Tam error : Program has failed due to a memory or stack error |}]

(*************)
(*  GLOBALES *)
(*************)

let%expect_test "testVarGlobalesSimpleInt" =
  runtam (pathFichiersRat^"testVarGlobalesSimpleInt.rat");
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
  (Rat.Parser.MenhirBasics.Error)
  Raised at Rat__Parser.MenhirBasics._eRR in file "parser.ml" (inlined), line 8, characters 6-17
  Called from Rat__Parser._menhir_run_098 in file "parser.ml", line 1513, characters 14-21
  Called from Rat__Compilateur.compiler in file "compilateur.ml", line 93, characters 14-45
  Re-raised at Rat__Compilateur.compiler in file "compilateur.ml", line 101, characters 6-13
  Called from Tam_projet__Test.runtamcode in file "projet_Tests/tam/test.ml", line 11, characters 16-32
  Called from Tam_projet__Test.runtam in file "projet_Tests/tam/test.ml" (inlined), line 24, characters 15-46
  Called from Tam_projet__Test.(fun) in file "projet_Tests/tam/test.ml", line 69, characters 2-57
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 142, characters 10-28

  Trailing output
  ---------------
  File "../../../../projet_Tests/tam/fichiersRat/testVarGlobalesSimpleInt.rat", line 1, characters 8-11: syntax error.
  |}]

let%expect_test "testVarGlobalesSimpleRat" =
  runtam (pathFichiersRat^"testVarGlobalesSimpleRat.rat");
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
  (Rat.Parser.MenhirBasics.Error)
  Raised at Rat__Parser.MenhirBasics._eRR in file "parser.ml" (inlined), line 8, characters 6-17
  Called from Rat__Parser._menhir_run_098 in file "parser.ml", line 1513, characters 14-21
  Called from Rat__Compilateur.compiler in file "compilateur.ml", line 93, characters 14-45
  Re-raised at Rat__Compilateur.compiler in file "compilateur.ml", line 101, characters 6-13
  Called from Tam_projet__Test.runtamcode in file "projet_Tests/tam/test.ml", line 11, characters 16-32
  Called from Tam_projet__Test.runtam in file "projet_Tests/tam/test.ml" (inlined), line 24, characters 15-46
  Called from Tam_projet__Test.(fun) in file "projet_Tests/tam/test.ml", line 73, characters 2-57
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 142, characters 10-28

  Trailing output
  ---------------
  File "../../../../projet_Tests/tam/fichiersRat/testVarGlobalesSimpleRat.rat", line 1, characters 8-11: syntax error.
  |}]

let%expect_test "testVarGlobalesSimplePointeur" =
  runtam (pathFichiersRat^"testVarGlobalesSimplePointeur.rat");
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
  (Rat.Parser.MenhirBasics.Error)
  Raised at Rat__Parser.MenhirBasics._eRR in file "parser.ml" (inlined), line 8, characters 6-17
  Called from Rat__Parser._menhir_run_098 in file "parser.ml", line 1513, characters 14-21
  Called from Rat__Compilateur.compiler in file "compilateur.ml", line 93, characters 14-45
  Re-raised at Rat__Compilateur.compiler in file "compilateur.ml", line 101, characters 6-13
  Called from Tam_projet__Test.runtamcode in file "projet_Tests/tam/test.ml", line 11, characters 16-32
  Called from Tam_projet__Test.runtam in file "projet_Tests/tam/test.ml" (inlined), line 24, characters 15-46
  Called from Tam_projet__Test.(fun) in file "projet_Tests/tam/test.ml", line 77, characters 2-62
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 142, characters 10-28

  Trailing output
  ---------------
  File "../../../../projet_Tests/tam/fichiersRat/testVarGlobalesSimplePointeur.rat", line 1, characters 8-11: syntax error.
  |}]


let%expect_test "testVarGlobalesInt" =
  runtam (pathFichiersRat^"testVarGlobalesInt.rat");
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
  (Rat.Parser.MenhirBasics.Error)
  Raised at Rat__Parser.MenhirBasics._eRR in file "parser.ml" (inlined), line 8, characters 6-17
  Called from Rat__Parser._menhir_run_098 in file "parser.ml", line 1513, characters 14-21
  Called from Rat__Compilateur.compiler in file "compilateur.ml", line 93, characters 14-45
  Re-raised at Rat__Compilateur.compiler in file "compilateur.ml", line 101, characters 6-13
  Called from Tam_projet__Test.runtamcode in file "projet_Tests/tam/test.ml", line 11, characters 16-32
  Called from Tam_projet__Test.runtam in file "projet_Tests/tam/test.ml" (inlined), line 24, characters 15-46
  Called from Tam_projet__Test.(fun) in file "projet_Tests/tam/test.ml", line 82, characters 2-51
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 142, characters 10-28

  Trailing output
  ---------------
  File "../../../../projet_Tests/tam/fichiersRat/testVarGlobalesInt.rat", line 1, characters 8-11: syntax error.
  |}]


let%expect_test "testVarGlobalesRat" =
  runtam (pathFichiersRat^"testVarGlobalesRat.rat");
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
  (Rat.Parser.MenhirBasics.Error)
  Raised at Rat__Parser.MenhirBasics._eRR in file "parser.ml" (inlined), line 8, characters 6-17
  Called from Rat__Parser._menhir_run_098 in file "parser.ml", line 1513, characters 14-21
  Called from Rat__Compilateur.compiler in file "compilateur.ml", line 93, characters 14-45
  Re-raised at Rat__Compilateur.compiler in file "compilateur.ml", line 101, characters 6-13
  Called from Tam_projet__Test.runtamcode in file "projet_Tests/tam/test.ml", line 11, characters 16-32
  Called from Tam_projet__Test.runtam in file "projet_Tests/tam/test.ml" (inlined), line 24, characters 15-46
  Called from Tam_projet__Test.(fun) in file "projet_Tests/tam/test.ml", line 87, characters 2-51
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 142, characters 10-28

  Trailing output
  ---------------
  File "../../../../projet_Tests/tam/fichiersRat/testVarGlobalesRat.rat", line 1, characters 8-11: syntax error.
  |}]


let%expect_test "testVarGlobalesEtPointeurSimple" =
  runtam (pathFichiersRat^"testVarGlobalesEtPointeurSimple.rat");
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
  (Rat.Parser.MenhirBasics.Error)
  Raised at Rat__Parser.MenhirBasics._eRR in file "parser.ml" (inlined), line 8, characters 6-17
  Called from Rat__Parser._menhir_run_098 in file "parser.ml", line 1513, characters 14-21
  Called from Rat__Compilateur.compiler in file "compilateur.ml", line 93, characters 14-45
  Re-raised at Rat__Compilateur.compiler in file "compilateur.ml", line 101, characters 6-13
  Called from Tam_projet__Test.runtamcode in file "projet_Tests/tam/test.ml", line 11, characters 16-32
  Called from Tam_projet__Test.runtam in file "projet_Tests/tam/test.ml" (inlined), line 24, characters 15-46
  Called from Tam_projet__Test.(fun) in file "projet_Tests/tam/test.ml", line 92, characters 2-64
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 142, characters 10-28

  Trailing output
  ---------------
  File "../../../../projet_Tests/tam/fichiersRat/testVarGlobalesEtPointeurSimple.rat", line 1, characters 8-11: syntax error.
  |}]


let%expect_test "testVarGlobalesEtPointeur" =
  runtam (pathFichiersRat^"testVarGlobalesEtPointeur.rat");
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
  (Rat.Parser.MenhirBasics.Error)
  Raised at Rat__Parser.MenhirBasics._eRR in file "parser.ml" (inlined), line 8, characters 6-17
  Called from Rat__Parser._menhir_run_098 in file "parser.ml", line 1513, characters 14-21
  Called from Rat__Compilateur.compiler in file "compilateur.ml", line 93, characters 14-45
  Re-raised at Rat__Compilateur.compiler in file "compilateur.ml", line 101, characters 6-13
  Called from Tam_projet__Test.runtamcode in file "projet_Tests/tam/test.ml", line 11, characters 16-32
  Called from Tam_projet__Test.runtam in file "projet_Tests/tam/test.ml" (inlined), line 24, characters 15-46
  Called from Tam_projet__Test.(fun) in file "projet_Tests/tam/test.ml", line 97, characters 2-58
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 142, characters 10-28

  Trailing output
  ---------------
  File "../../../../projet_Tests/tam/fichiersRat/testVarGlobalesEtPointeur.rat", line 1, characters 8-11: syntax error.
  |}]

(*
S’assurer que les instructions générées permettent une modification correcte depuis différentes fonctions.
Tester les dépendances et initialisations successives.
*)


(*************)
(* STATIQUES *)
(*************)

let%expect_test "testVarStatiqueSimple" =
  runtam (pathFichiersRat^"testVarStatiqueSimple.rat");
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
  (Rat.Parser.MenhirBasics.Error)
  Raised at Rat__Parser.MenhirBasics._eRR in file "parser.ml" (inlined), line 8, characters 6-17
  Called from Rat__Parser._menhir_run_090 in file "parser.ml", line 1149, characters 10-17
  Called from Rat__Compilateur.compiler in file "compilateur.ml", line 93, characters 14-45
  Re-raised at Rat__Compilateur.compiler in file "compilateur.ml", line 101, characters 6-13
  Called from Tam_projet__Test.runtamcode in file "projet_Tests/tam/test.ml", line 11, characters 16-32
  Called from Tam_projet__Test.runtam in file "projet_Tests/tam/test.ml" (inlined), line 24, characters 15-46
  Called from Tam_projet__Test.(fun) in file "projet_Tests/tam/test.ml", line 111, characters 2-54
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 142, characters 10-28

  Trailing output
  ---------------
  File "../../../../projet_Tests/tam/fichiersRat/testVarStatiqueSimple.rat", line 2, characters 10-13: syntax error.
  |}]


let%expect_test "testVarStatique" =
  runtam (pathFichiersRat^"testVarStatique.rat");
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
  (Rat.Parser.MenhirBasics.Error)
  Raised at Rat__Parser.MenhirBasics._eRR in file "parser.ml" (inlined), line 8, characters 6-17
  Called from Rat__Parser._menhir_run_090 in file "parser.ml", line 1149, characters 10-17
  Called from Rat__Compilateur.compiler in file "compilateur.ml", line 93, characters 14-45
  Re-raised at Rat__Compilateur.compiler in file "compilateur.ml", line 101, characters 6-13
  Called from Tam_projet__Test.runtamcode in file "projet_Tests/tam/test.ml", line 11, characters 16-32
  Called from Tam_projet__Test.runtam in file "projet_Tests/tam/test.ml" (inlined), line 24, characters 15-46
  Called from Tam_projet__Test.(fun) in file "projet_Tests/tam/test.ml", line 116, characters 2-48
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 142, characters 10-28

  Trailing output
  ---------------
  File "../../../../projet_Tests/tam/fichiersRat/testVarStatique.rat", line 2, characters 10-13: syntax error.
  |}]
(*
(*
Vérifier la persistance des valeurs entre appels via le code généré.
Tester les réinitialisations illégales.
*)

(*************)
(* DÉFAUTS   *)
(*************)


Valider que le code gère correctement les appels avec des paramètres omis.
Tester les cas où les valeurs par défaut interagissent avec d’autres arguments.
*)

let%expect_test "testParamDef1" =
  runtam (pathFichiersRat^"testParamDef1.rat");
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
  (Rat.Parser.MenhirBasics.Error)
  Raised at Rat__Parser.MenhirBasics._eRR in file "parser.ml" (inlined), line 8, characters 6-17
  Called from Rat__Parser._menhir_run_008 in file "parser.ml", line 1984, characters 14-21
  Called from Rat__Compilateur.compiler in file "compilateur.ml", line 93, characters 14-45
  Re-raised at Rat__Compilateur.compiler in file "compilateur.ml", line 101, characters 6-13
  Called from Tam_projet__Test.runtamcode in file "projet_Tests/tam/test.ml", line 11, characters 16-32
  Called from Tam_projet__Test.runtam in file "projet_Tests/tam/test.ml" (inlined), line 24, characters 15-46
  Called from Tam_projet__Test.(fun) in file "projet_Tests/tam/test.ml", line 134, characters 2-46
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 142, characters 10-28

  Trailing output
  ---------------
  File "../../../../projet_Tests/tam/fichiersRat/testParamDef1.rat", line 1, characters 22-23: syntax error.
  |}]

let%expect_test "testParamDef2" =
  runtam (pathFichiersRat^"testParamDef2.rat");
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)
  (Rat.Parser.MenhirBasics.Error)
  Raised at Rat__Parser.MenhirBasics._eRR in file "parser.ml" (inlined), line 8, characters 6-17
  Called from Rat__Parser._menhir_run_008 in file "parser.ml", line 1984, characters 14-21
  Called from Rat__Compilateur.compiler in file "compilateur.ml", line 93, characters 14-45
  Re-raised at Rat__Compilateur.compiler in file "compilateur.ml", line 101, characters 6-13
  Called from Tam_projet__Test.runtamcode in file "projet_Tests/tam/test.ml", line 11, characters 16-32
  Called from Tam_projet__Test.runtam in file "projet_Tests/tam/test.ml" (inlined), line 24, characters 15-46
  Called from Tam_projet__Test.(fun) in file "projet_Tests/tam/test.ml", line 138, characters 2-46
  Called from Ppx_expect_runtime__Test_block.Configured.dump_backtrace in file "runtime/test_block.ml", line 142, characters 10-28

  Trailing output
  ---------------
  File "../../../../projet_Tests/tam/fichiersRat/testParamDef2.rat", line 1, characters 22-23: syntax error.
  |}]
