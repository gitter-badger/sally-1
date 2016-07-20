open Ast.Sal_ast;;
open Inline;;
open Format;;

exception Duplicate_else_guarded_commands;;

(* call inline function and remove conditional expressions *)

let rec cond_ast_to_str ast =
  match ast with
  | And(e1, e2) -> "and("^(cond_ast_to_str e1)^", "^(cond_ast_to_str e2)^")"
  | Or(e1, e2) -> "or("^(cond_ast_to_str e1)^", "^(cond_ast_to_str e2)^")"
  | Not e -> "not("^(cond_ast_to_str e)^")"
  | True -> "true"
  | False -> "false"
  | _ -> "expr"

let rec conjunction ls =
  match ls with
  | l::l'::ls -> conjunction (And(l, l')::ls)
  | [res] -> res;;

let expand_conds conds =
  let rec ec prev conds res =
    (match conds with
    | [] -> (conjunction (List.map (fun x -> Not x) prev))::res
    | c::cs ->
        ec (c::prev) cs ((And (conjunction (List.map (fun x -> Not x) prev), c))::res)) in
  match conds with
   | [] -> []
   | c::cs -> ec [c] cs [c];;

(* turn an i b_1 then b_2 else if ... then b_n-1 else b_n expression into a disjunction *)
let is_cond = function Cond (e1, e2) -> true | _ -> false;;

let flatten_cond_to_bool = function
  | Cond (ifs, els) ->
      let ls = List.rev_map2 (fun x y -> And(x, y)) (expand_conds (List.map fst ifs)) (els::(List.rev_map snd ifs)) in
        List.fold_left (fun x y -> Or (x, y)) (List.hd ls) (List.tl ls)
  | other -> other

let rec flattener cond = function
  | Cond (ifs, els) ->
      (* generate new ifs *)
      List.rev_map2 (fun x y -> (And(cond, x), y))
        (expand_conds (List.map fst ifs)) (els::(List.rev_map snd ifs))
  | other -> [(cond, other)];;

(* flatten conditional statements in an expression so there is at most one conditional
in the expression (conditionals within logical expressions are converted
to logical expressions); simpler way? *)
let rec flatten_cond = function
  | Cond (ifs, els) ->
      let ifs' = List.map (fun (x, y) -> (flatten_cond x, flatten_cond y)) ifs in
      let els' = flatten_cond els in
      (* flatten the ifs *)
      let ifs'' = List.flatten (List.map2 flattener (List.map fst ifs') (List.map snd ifs')) in
      (* flatten the else *)
      (match els' with
      | Cond (e_ifs, e_els) ->
          Cond
            (List.map (fun (x, y) -> (And(x, List.hd (expand_conds (List.map fst ifs''))), y)) e_ifs,
             e_els)
      | _ -> Cond (ifs'', els'))
  (* arithmetic *)
  | Add (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, Add (y, e))) ifs in
     flatten_cond (Cond (ifs', Add (e, els)))
  | Add (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, Add (e, y))) ifs in
     flatten_cond (Cond (ifs', Add (els, e)))
  | Add (e1, e2) -> Add (flatten_cond e1, flatten_cond e2)
  | Sub (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, Sub (y, e))) ifs in
     flatten_cond (Cond (ifs', Sub (e, els)))
  | Sub (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, Sub (e, y))) ifs in
     flatten_cond (Cond (ifs', Sub (els, e)))
  | Sub (e1, e2) -> Sub (flatten_cond e1, flatten_cond e2)
  | Mul (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, Mul (y, e))) ifs in
     flatten_cond (Cond (ifs', Mul (e, els)))
  | Mul (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, Mul (e, y))) ifs in
     flatten_cond (Cond (ifs', Mul (els, e)))
  | Mul (e1, e2) -> Mul (flatten_cond e1, flatten_cond e2)
  | Div (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, Div (y, e))) ifs in
     flatten_cond (Cond (ifs', Div (e, els)))
  | Div (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, Div (e, y))) ifs in
     flatten_cond (Cond (ifs', Div (els, e)))
  | Div (e1, e2) -> Div (flatten_cond e1, flatten_cond e2)
  (* comparisons *)
  | Ge (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, Ge (y, e))) ifs in
     flatten_cond (Cond (ifs', Ge (e, els)))
  | Ge (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, Ge (e, y))) ifs in
     flatten_cond (Cond (ifs', Ge (els, e)))
  | Ge (e1, e2) -> Ge (flatten_cond e1, flatten_cond e2)
  | Gt (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, Gt (y, e))) ifs in
     flatten_cond (Cond (ifs', Gt (e, els)))
  | Gt (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, Gt (e, y))) ifs in
     flatten_cond (Cond (ifs', Gt (els, e)))
  | Gt (e1, e2) -> Gt (flatten_cond e1, flatten_cond e2)
  | Le (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, Le (y, e))) ifs in
     flatten_cond (Cond (ifs', Le (e, els)))
  | Le (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, Le (e, y))) ifs in
     flatten_cond (Cond (ifs', Le (els, e)))
  | Le (e1, e2) -> Le (flatten_cond e1, flatten_cond e2)
  | Lt (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, Lt (y, e))) ifs in
     flatten_cond (Cond (ifs', Lt (e, els)))
  | Lt (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, Lt (e, y))) ifs in
     flatten_cond (Cond (ifs', Lt (els, e)))
  | Lt (e1, e2) -> Lt (flatten_cond e1, flatten_cond e2)
  | Eq (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, Eq (y, e))) ifs in
     flatten_cond (Cond (ifs', Eq (e, els)))
  | Eq (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, Eq (e, y))) ifs in
     flatten_cond (Cond (ifs', Eq (els, e)))
  | Eq (e1, e2) -> Eq (flatten_cond e1, flatten_cond e2)
  | Neq (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, Neq (y, e))) ifs in
     flatten_cond (Cond (ifs', Neq (e, els)))
  | Neq (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, Neq (e, y))) ifs in
     flatten_cond (Cond (ifs', Neq (els, e)))
  | Neq (e1, e2) -> Neq (flatten_cond e1, flatten_cond e2)
  (* logical expressions *)
  | Not (Cond (ifs, els)) -> 
      let ifs' = List.map (fun (x, y) -> (x, Not y)) ifs in
      flatten_cond (Cond (ifs', Not els))
  | Not e -> Not (flatten_cond e)
  | And (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, And (y, e))) ifs in
     flatten_cond (Cond (ifs', And (e, els)))
  | And (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, And (e, y))) ifs in
     flatten_cond (Cond (ifs', And (els, e)))
  | And (e1, e2) -> And (flatten_cond e1, flatten_cond e2)
  | Or (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, Or (y, e))) ifs in
     flatten_cond (Cond (ifs', Or (e, els)))
  | Or (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, Or (e, y))) ifs in
     flatten_cond (Cond (ifs', Or (els, e)))
  | Or (e1, e2) -> Or (flatten_cond e1, flatten_cond e2)
  | Xor (Cond (ifs, els), e) ->
     let ifs' = List.map (fun (x, y) -> (x, Xor (y, e))) ifs in
     flatten_cond (Cond (ifs', Xor (e, els)))
  | Xor (e, Cond (ifs, els)) ->
     let ifs' = List.map (fun (x, y) -> (x, Xor (e, y))) ifs in
     flatten_cond (Cond (ifs', Xor (els, e)))
  | Xor (e1, e2) -> Xor (flatten_cond e1, flatten_cond e2)
  | Implies (e1, e2) -> 
      flatten_cond (Or (Not e1, e2))
  | Iff (e1, e2) ->
      flatten_cond
        (And (Or (Not e1, e2),
              Or (e1, Not e2)))
  | other -> other;;

let preproc_assign = function
  | Assign (e1, e2) -> Assign (e1, flatten_cond e2)
  | Member (e1, e2) -> Member (e1, flatten_cond e2);;

(* convert a guarded command with conditionals in its guard into separate guarded commands *)
let rec preproc_guarded_guard (Guarded (guard, assigns)) =
  match flatten_cond guard with 
    | Cond (ifs, els) ->
        let conds = List.rev_map2 (fun x y -> And(x, y)) (expand_conds (List.map fst ifs)) (els::(List.rev_map snd ifs)) in
        List.map (fun c -> Guarded (c, assigns)) conds
    | other -> [Guarded (other, assigns)];;

(* convert a guarded command with conditionals in its assignments into separate
guarded commands *)
let rec preproc_guarded_assigns (Guarded (guard, finished)) = function
  | (Assign (e, Cond (ifs, els)))::rest ->
      let conds = expand_conds (List.map fst ifs) in
      let exprs = els::(List.rev_map snd ifs) in
      let guardeds =
        List.rev_map2
          (fun x y -> preproc_guarded_assigns
             (Guarded (And (guard, x), (Assign (e, y))::finished))
             rest)
          conds exprs in
      List.flatten guardeds
  | assign::assigns ->
      preproc_guarded_assigns (Guarded (guard, assign::finished)) assigns
  | [] -> [Guarded (guard, finished)];;

let rec preproc_guarded = function
  | ExistentialGuarded (decl, gc) -> List.map (fun gc -> ExistentialGuarded (decl, gc)) (preproc_guarded gc)
  | Guarded (guard, assigns) ->
      (List.map (fun (Guarded (g, a)) -> preproc_guarded_assigns (Guarded (g, [])) (List.map preproc_assign a))
               (preproc_guarded_guard (Guarded (guard, assigns))))
      |> List.flatten
  | other -> [other];;

let rec preproc_transition st =
  match st with
  | NoTransition -> NoTransition
  | Assignments assigns ->
      (* if there are conditionals in the assignments, convert into guarded commands *)
      (match preproc_guarded (Guarded (True, assigns)) with
        | [g] -> Assignments assigns
        | gs -> GuardedCommands gs)
  | GuardedCommands gls ->
      let is_default = function
        | Default _ -> true
        | _ -> false in
      let (gs, ds) = List.partition is_default gls in
      let gs' = List.flatten (List.map preproc_guarded gs) in
      (* handle ELSE *)
      match ds with
      | [] -> GuardedCommands gs'
      | [Default assigns] -> GuardedCommands gs'
      | _ -> raise Duplicate_else_guarded_commands;;

let rec preproc_defs ds res =
  match ds with
  | [] -> res
  | (Module_def (str, sal_mod))::ds ->
      preproc_defs ds
        ((Module_def (str, { sal_mod with
          transition = preproc_transition (sal_mod.transition) }))::res)
  | _::ds -> preproc_defs ds res;;
  
let preproc sal_ctx =
  let ctx' = inline sal_ctx in
  printf "%s\n" "inlined";
  let defs = preproc_defs ctx'.definitions [] in
  { ctx' with definitions = defs };;