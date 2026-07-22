(** Bindings to the {{:https://github.com/google/robotstxt}google/robotstxt}
    parser and matcher. *)

type decision = {
  allowed : bool;
  matching_line : int option;
  matched_specific_agent : bool;
}
(** The result of matching one URL. Line numbers are one-based. *)

module Matcher : sig
  type t
  (** A reusable native matcher. A value may be reused sequentially, but must
      not be used by multiple domains at the same time. *)

  val create : unit -> t

  val evaluate :
    t -> robots_txt:string -> user_agent:string -> url:string -> decision
  (** Parse [robots_txt] and match [url] for [user_agent]. [url] must be
      percent-encoded according to RFC 3986. *)

  val evaluate_many :
    t -> robots_txt:string -> user_agents:string list -> url:string -> decision
  (** As [evaluate], considering multiple user-agent product tokens. Raises
      [Invalid_argument] if [user_agents] is empty. *)

  val is_allowed :
    t -> robots_txt:string -> user_agent:string -> url:string -> bool
  (** A lower-allocation version of [evaluate] when only the decision matters.
  *)

  val is_allowed_many :
    t -> robots_txt:string -> user_agents:string list -> url:string -> bool
  (** Raises [Invalid_argument] if [user_agents] is empty. *)
end

val evaluate : robots_txt:string -> user_agent:string -> url:string -> decision
(** One-shot matching. This allocates a fresh matcher and is safe to call from
    multiple domains. *)

val evaluate_many :
  robots_txt:string -> user_agents:string list -> url:string -> decision
(** One-shot matching for multiple user-agents. Raises [Invalid_argument] if
    [user_agents] is empty. *)

val is_allowed : robots_txt:string -> user_agent:string -> url:string -> bool
(** One-shot allow/deny check. *)

val is_allowed_many :
  robots_txt:string -> user_agents:string list -> url:string -> bool
(** One-shot allow/deny check for multiple user-agents. Raises
    [Invalid_argument] if [user_agents] is empty. *)

val is_valid_user_agent : string -> bool
(** Whether a user-agent contains only characters accepted by the upstream
    matcher. Empty strings are invalid. *)
