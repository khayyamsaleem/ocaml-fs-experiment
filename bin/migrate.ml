open Lib

let migrate () =
  print_endline "Creating todos table.";
  match%lwt Todos.migrate () with
  | Ok () -> print_endline "Done." |> Lwt.return
  | Error (Todos.Database_error msg) -> print_endline msg |> Lwt.return

let () = Lwt_main.run (migrate ())