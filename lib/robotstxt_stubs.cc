#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#include <cstddef>
#include <new>
#include <vector>

#define ROBOTS_IMPLEMENTATION
#include "robots_c.h"

namespace {

struct ocaml_robotstxt_matcher {
  robots_matcher_t* matcher;
};

#define Matcher_val(value) \
  (reinterpret_cast<ocaml_robotstxt_matcher*>(Data_custom_val(value)))

void finalize_matcher(value v_matcher) {
  ocaml_robotstxt_matcher* wrapper = Matcher_val(v_matcher);
  robots_matcher_free(wrapper->matcher);
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

robots_matcher_t* unwrap_matcher(value v_matcher) {
  return Matcher_val(v_matcher)->matcher;
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
  wrapper->matcher = robots_matcher_create();
  if (wrapper->matcher == nullptr) caml_raise_out_of_memory();

  CAMLreturn(v_matcher);
}

extern "C" CAMLprim value ocaml_robotstxt_is_allowed(
    value v_matcher, value v_robots_txt, value v_user_agent, value v_url) {
  CAMLparam4(v_matcher, v_robots_txt, v_user_agent, v_url);
  try {
    const bool allowed = robots_allowed_by_robots(
        unwrap_matcher(v_matcher), String_val(v_robots_txt),
        caml_string_length(v_robots_txt), String_val(v_user_agent),
        caml_string_length(v_user_agent), String_val(v_url),
        caml_string_length(v_url));
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
    std::vector<const char*> agents(count);
    std::vector<size_t> lengths(count);
    for (mlsize_t i = 0; i < count; ++i) {
      const value agent = Field(v_user_agents, i);
      agents[i] = String_val(agent);
      lengths[i] = caml_string_length(agent);
    }

    const bool allowed = robots_allowed_by_robots_multi(
        unwrap_matcher(v_matcher), String_val(v_robots_txt),
        caml_string_length(v_robots_txt), agents.data(), lengths.data(), count,
        String_val(v_url), caml_string_length(v_url));
    CAMLreturn(Val_bool(allowed));
  } catch (const std::bad_alloc&) {
    caml_raise_out_of_memory();
  } catch (...) {
    raise_native_exception();
  }
}

extern "C" CAMLprim value ocaml_robotstxt_matching_line(value v_matcher) {
  CAMLparam1(v_matcher);
  CAMLreturn(Val_int(robots_matching_line(unwrap_matcher(v_matcher))));
}

extern "C" CAMLprim value ocaml_robotstxt_matched_specific_agent(
    value v_matcher) {
  CAMLparam1(v_matcher);
  CAMLreturn(Val_bool(
      robots_ever_seen_specific_agent(unwrap_matcher(v_matcher))));
}

extern "C" CAMLprim value ocaml_robotstxt_crawl_delay(value v_matcher) {
  CAMLparam1(v_matcher);
  CAMLlocal2(v_delay, v_some);
  robots_matcher_t* matcher = unwrap_matcher(v_matcher);
  if (!robots_has_crawl_delay(matcher)) CAMLreturn(Val_none);

  v_delay = caml_copy_double(robots_get_crawl_delay(matcher));
  v_some = caml_alloc(1, 0);
  Store_field(v_some, 0, v_delay);
  CAMLreturn(v_some);
}

extern "C" CAMLprim value ocaml_robotstxt_request_rate(value v_matcher) {
  CAMLparam1(v_matcher);
  CAMLlocal2(v_rate, v_some);
  robots_request_rate_t rate;
  if (!robots_get_request_rate(unwrap_matcher(v_matcher), &rate)) {
    CAMLreturn(Val_none);
  }

  v_rate = caml_alloc_tuple(2);
  Store_field(v_rate, 0, Val_int(rate.requests));
  Store_field(v_rate, 1, Val_int(rate.seconds));
  v_some = caml_alloc(1, 0);
  Store_field(v_some, 0, v_rate);
  CAMLreturn(v_some);
}

extern "C" CAMLprim value ocaml_robotstxt_content_signal(value v_matcher) {
  CAMLparam1(v_matcher);
  CAMLlocal2(v_signal, v_some);
  robots_content_signal_t signal;
  if (!robots_get_content_signal(unwrap_matcher(v_matcher), &signal)) {
    CAMLreturn(Val_none);
  }

  v_signal = caml_alloc_tuple(3);
  Store_field(v_signal, 0, Val_int(signal.ai_train));
  Store_field(v_signal, 1, Val_int(signal.ai_input));
  Store_field(v_signal, 2, Val_int(signal.search));
  v_some = caml_alloc(1, 0);
  Store_field(v_some, 0, v_signal);
  CAMLreturn(v_some);
}

extern "C" CAMLprim value ocaml_robotstxt_is_valid_user_agent(
    value v_user_agent) {
  CAMLparam1(v_user_agent);
  CAMLreturn(Val_bool(robots_is_valid_user_agent(
      String_val(v_user_agent), caml_string_length(v_user_agent))));
}

extern "C" CAMLprim value ocaml_robotstxt_content_signal_supported(
    value v_unit) {
  CAMLparam1(v_unit);
  CAMLreturn(Val_bool(robots_content_signal_supported()));
}

extern "C" CAMLprim value ocaml_robotstxt_version(value v_unit) {
  CAMLparam1(v_unit);
  CAMLreturn(caml_copy_string(robots_version()));
}
