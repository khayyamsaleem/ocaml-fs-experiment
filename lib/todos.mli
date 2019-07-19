type todo = {
  id: int;
  content: string;
}

type error =
  | Database_error of string

(* Migrations-related helper functions *)
val migrate : unit -> (unit, error) result Lwt.t
val rollback : unit -> (unit, error) result Lwt.t

(* Core functions *)
val get_all : unit -> (todo list, error) result Lwt.t
val add : string -> (unit, error) result Lwt.t
val remove : int -> (unit, error) result Lwt.t
val clear : unit -> (unit, error) result Lwt.t