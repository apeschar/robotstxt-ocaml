(** Bindings to the {{:https://github.com/nzrsky/robotstxt}nzrsky/robotstxt}
    parser and matcher. *)

type request_rate = { requests : int; seconds : int }
(** A [Request-rate: requests/seconds] directive. *)

type content_signal = {
  ai_train : bool option;
  ai_input : bool option;
  search : bool option;
}
(** Content-Signal preferences. [None] means that the preference was not
    specified by the selected user-agent group. *)

type decision = {
  allowed : bool;
  matching_line : int option;
  matched_specific_agent : bool;
  crawl_delay : float option;
  request_rate : request_rate option;
  content_signal : content_signal option;
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
  (** As [evaluate], considering multiple user-agent product tokens. The
      upstream matcher prefers the most specific matching group and combines
      groups of equal specificity. Raises [Invalid_argument] if [user_agents] is
      empty. *)

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

val allows_ai_train : decision -> bool
(** The [ai-train] preference, defaulting to [true] when unspecified. *)

val allows_ai_input : decision -> bool
(** The [ai-input] preference, defaulting to [true] when unspecified. *)

val allows_search : decision -> bool
(** The [search] preference, defaulting to [true] when unspecified. *)

val is_valid_user_agent : string -> bool
(** Whether a user-agent contains only characters accepted by the upstream
    matcher. Empty strings are invalid. *)

val content_signal_supported : bool
(** Whether the vendored library was compiled with Content-Signal support. *)

val version : string
(** The version of the vendored robotstxt library. *)
