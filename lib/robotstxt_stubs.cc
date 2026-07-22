#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#include <cstddef>
#include <new>
#include <string>
#include <vector>

#include "robots.h"

namespace {

struct ocaml_robotstxt_matcher {
  googlebot::RobotsMatcher* matcher;
};

#define Matcher_val(value) \
  (reinterpret_cast<ocaml_robotstxt_matcher*>(Data_custom_val(value)))

void finalize_matcher(value v_matcher) {
  ocaml_robotstxt_matcher* wrapper = Matcher_val(v_matcher);
  delete wrapper->matcher;
  wrapper->matcher = nullptr;
}

custom_operations matcher_operations = {
    "org.ocaml.robotstxt.matcher.v1",
    finalize_matcher,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default,
};

googlebot::RobotsMatcher* unwrap_matcher(value v_matcher) {
  return Matcher_val(v_matcher)->matcher;
}

absl::string_view string_view_of_value(value v_string) {
  return {String_val(v_string), caml_string_length(v_string)};
}

std::string string_of_value(value v_string) {
  return {String_val(v_string), caml_string_length(v_string)};
}

[[noreturn]] void raise_native_exception() {
  caml_failwith("robotstxt: unexpected exception in the native library");
}

}  // namespace

extern "C" CAMLprim value ocaml_robotstxt_matcher_create(value v_unit) {
  CAMLparam1(v_unit);
  CAMLlocal1(v_matcher);

  v_matcher = caml_alloc_custom_mem(
      &matcher_operations, sizeof(ocaml_robotstxt_matcher),
      sizeof(googlebot::RobotsMatcher));
  ocaml_robotstxt_matcher* wrapper = Matcher_val(v_matcher);
  wrapper->matcher = nullptr;
  try {
    wrapper->matcher = new googlebot::RobotsMatcher();
  } catch (const std::bad_alloc&) {
    caml_raise_out_of_memory();
  } catch (...) {
    raise_native_exception();
  }

  CAMLreturn(v_matcher);
}

extern "C" CAMLprim value ocaml_robotstxt_is_allowed(
    value v_matcher, value v_robots_txt, value v_user_agent, value v_url) {
  CAMLparam4(v_matcher, v_robots_txt, v_user_agent, v_url);
  try {
    const bool allowed = unwrap_matcher(v_matcher)->OneAgentAllowedByRobots(
        string_view_of_value(v_robots_txt), string_of_value(v_user_agent),
        string_of_value(v_url));
    CAMLreturn(Val_bool(allowed));
  } catch (const std::bad_alloc&) {
    caml_raise_out_of_memory();
  } catch (...) {
    raise_native_exception();
  }
}

extern "C" CAMLprim value ocaml_robotstxt_is_allowed_many(
    value v_matcher, value v_robots_txt, value v_user_agents, value v_url) {
  CAMLparam4(v_matcher, v_robots_txt, v_user_agents, v_url);
  try {
    const mlsize_t count = Wosize_val(v_user_agents);
    std::vector<std::string> agents;
    agents.reserve(count);
    for (mlsize_t i = 0; i < count; ++i) {
      agents.push_back(string_of_value(Field(v_user_agents, i)));
    }

    const bool allowed = unwrap_matcher(v_matcher)->AllowedByRobots(
        string_view_of_value(v_robots_txt), &agents, string_of_value(v_url));
    CAMLreturn(Val_bool(allowed));
  } catch (const std::bad_alloc&) {
    caml_raise_out_of_memory();
  } catch (...) {
    raise_native_exception();
  }
}

extern "C" CAMLprim value ocaml_robotstxt_matching_line(value v_matcher) {
  CAMLparam1(v_matcher);
  CAMLreturn(Val_int(unwrap_matcher(v_matcher)->matching_line()));
}

extern "C" CAMLprim value ocaml_robotstxt_matched_specific_agent(
    value v_matcher) {
  CAMLparam1(v_matcher);
  CAMLreturn(Val_bool(unwrap_matcher(v_matcher)->ever_seen_specific_agent()));
}

extern "C" CAMLprim value ocaml_robotstxt_is_valid_user_agent(
    value v_user_agent) {
  CAMLparam1(v_user_agent);
  CAMLreturn(Val_bool(googlebot::RobotsMatcher::IsValidUserAgentToObey(
      string_view_of_value(v_user_agent))));
}
