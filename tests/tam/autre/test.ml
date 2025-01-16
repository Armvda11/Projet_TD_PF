open Rat
open Compilateur

(* Changer le chemin d'accès du jar. *)
let runtamcmde = "java -jar ../../../../../tests/runtam.jar"
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
  Sys.remove tamfile;    (* à commenter si on veut étudier le code TAM. *)
  String.trim printed

(* Compile and run ratfile, then print its output *)
let runtam ratfile =
  print_string (runtamcode runtamcmde ratfile)

(****************************************)
(** Chemin d'accès aux fichiers de test *)
(****************************************)

let pathFichiersRat = "../../../../../tests/tam/autre/fichiersRat/"

(**********)
(*  TESTS *)
(**********)

(* requires ppx_expect in jbuild, and `opam install ppx_expect` *)



let%expect_test "testSimple" =
  runtam (pathFichiersRat^"testSimple.rat");
  [%expect{| 15 |}]

  let%expect_test "test_default_params" =
  runtam (pathFichiersRat ^ "test_default_params.rat");
  [%expect{| 1525 |}]


  let%expect_test "test_pointers" =
  runtam (pathFichiersRat ^ "test_pointers.rat");
  [%expect{| 4215 |}]


  let%expect_test "test_global_variables" =
  runtam (pathFichiersRat ^ "test_global_variables.rat");
  [%expect{| 542 |}]

  let%expect_test "test_combined" =
  runtam (pathFichiersRat ^ "test_combined.rat");
  [%expect{| 20020  |}]

  let%expect_test "test_pointer_global" =
  runtam (pathFichiersRat ^ "test_pointer_global.rat");
  [%expect{| 3050 |}]

  let%expect_test "test_nested_calls" =
  runtam (pathFichiersRat ^ "test_nested_calls.rat");
  [%expect{| 2040 |}]

  let%expect_test "test_static_persistence" =
  runtam (pathFichiersRat ^ "test_static_persistence.rat");
  [%expect{| 123 |}]

  let%expect_test "test_static_multiple_calls" =
  runtam (pathFichiersRat ^ "test_static_multiple_calls.rat");
  [%expect{| 51512 |}]

  let%expect_test "test_static_pointer" =
  runtam (pathFichiersRat ^ "test_static_pointer.rat");
  [%expect{| 434445 |}]

  let%expect_test "test_combined_1" =
  runtam (pathFichiersRat ^ "test_combined_1.rat");
  [%expect{| 111122113 |}]

  let%expect_test "test_combined_2" =
  runtam (pathFichiersRat ^ "test_combined_2.rat");
  [%expect{|  644746 |}]
