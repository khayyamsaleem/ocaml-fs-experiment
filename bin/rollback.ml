open Lib

let rollback () =
  print_endline "Dropping todos table.";
  match%lwt Todos.rollback () with
  | Ok () -> print_endline "Done." |> Lwt.return
  | Error (Todos.Database_error msg) -> print_endline msg |> Lwt.return

let () = Lwt_main.run (rollback ())