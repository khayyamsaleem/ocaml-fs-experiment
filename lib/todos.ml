let connection_url = "postgresql://localhost:5432"

type todo = {
  id: int;
  content: string;
}

type error =
  | Database_error of string

(* This is the connection pool we will use for executing DB Operations *)
let pool =
  match Caqti_lwt.connect_pool ~max_size: 10 (Uri.of_string connection_url) with
  | Ok pool -> pool
  | Error err -> failwith (Caqti_error.show err)

let or_error m =
  match%lwt m with
  | Ok a -> Ok a |> Lwt.return
  | Error e -> Error (Database_error (Caqti_error.show e)) |> Lwt.return

let migrate_query =
  Caqti_request.exec
    Caqti_type.unit
    {| CREATE TABLE todos (
        id SERIAL NOT NULL PRIMARY KEY,
        content VARCHAR
       )
    |}

let migrate () =
  let migrate' (module C : Caqti_lwt.CONNECTION) =
    C.exec migrate_query ()
  in
  Caqti_lwt.Pool.use migrate' pool |> or_error

let rollback_query =
  Caqti_request.exec
    Caqti_type.unit
    {| DROP TABLE todos |}

let rollback () =
  let rollback' (module C : Caqti_lwt.CONNECTION) =
    C.exec rollback_query ()
  in
  Caqti_lwt.Pool.use rollback' pool |> or_error

let get_all_query =
  Caqti_request.collect
    Caqti_type.unit
    Caqti_type.(tup2 int string)
    {| SELECT id, content FROM todos |}

let get_all () =
  let get_all' (module C : Caqti_lwt.CONNECTION) =
    C.fold get_all_query (fun (id, content) acc ->
        {id; content} :: acc
      )  () []
  in
  Caqti_lwt.Pool.use get_all' pool |> or_error

let add_query =
  Caqti_request.exec
    Caqti_type.string
    {| INSERT INTO todos (content) VALUES (?) |}

let add content =
  let add' content (module C : Caqti_lwt.CONNECTION) =
    C.exec add_query content
  in
  Caqti_lwt.Pool.use (add' content) pool |> or_error

let remove_query =
  Caqti_request.exec
    Caqti_type.int
    {| DELETE FROM todos WHERE id = ? |}

let remove id =
  let remove' id (module C : Caqti_lwt.CONNECTION) =
    C.exec remove_query id
  in Caqti_lwt.Pool.use (remove' id) pool |> or_error

let clear_query =
  Caqti_request.exec
    Caqti_type.unit
    {| TRUNCATE TABLE todos |}

let clear () =
  let clear' (module C : Caqti_lwt.CONNECTION) =
    C.exec clear_query ()
  in Caqti_lwt.Pool.use clear' pool |> or_error