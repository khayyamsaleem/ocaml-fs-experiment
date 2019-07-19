open Opium.Std
open Lib

let json_of_todo { Todos.id ; content } =
  let open Ezjsonm in
  dict [ "id", (int id)
       ; "content", (string content)]

let json_of_todos todos =
  let open Ezjsonm in
  dict ["success", (bool true)
       ; "todos", (`A (List.map json_of_todo todos))]

let json_of_error e =
  let open Ezjsonm in
  dict ["success", (bool false)
       ; "message", (string e)]

let get_all = get "/todos" begin fun _req ->
    match%lwt Todos.get_all () with
    | Ok todos -> `Json (todos |> json_of_todos) |> respond'
    | Error (Todos.Database_error msg) -> `Json (msg |> json_of_error) |> respond'
  end

let add_todo = post "/new" begin fun req ->
    req |> App.json_of_body_exn |> Lwt.map (fun json ->
        match json with
        | `O [("content", `String todo)] ->
          let _ = Todos.add todo in
          let open Ezjsonm in
          respond (`Json (dict [
              ("success", bool true);
              ("message", (string "added"))]))
        | _ -> respond (`Json ("bad request" |> json_of_error))
      )
  end


let _ =
  print_endline "Launched server on http://localhost:3000";
  App.empty
  |> get_all
  |> add_todo
  |> App.run_command