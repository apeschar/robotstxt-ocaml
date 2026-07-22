#ifndef ROBOTSTXT_OCAML_ABSL_STRINGS_MATCH_H_
#define ROBOTSTXT_OCAML_ABSL_STRINGS_MATCH_H_

#include <algorithm>
#include <cstddef>

#include "absl/strings/ascii.h"
#include "absl/strings/string_view.h"

namespace absl {

inline bool StartsWith(string_view value, string_view prefix) {
  return value.size() >= prefix.size() &&
         value.substr(0, prefix.size()) == prefix;
}

inline bool EqualsIgnoreCase(string_view left, string_view right) {
  return left.size() == right.size() &&
         std::equal(left.begin(), left.end(), right.begin(),
                    [](unsigned char a, unsigned char b) {
                      return ascii_tolower(a) == ascii_tolower(b);
                    });
}

inline bool StartsWithIgnoreCase(string_view value, string_view prefix) {
  return value.size() >= prefix.size() &&
         EqualsIgnoreCase(value.substr(0, prefix.size()), prefix);
}

inline string_view ClippedSubstr(string_view value, std::size_t position) {
  return value.substr(std::min(position, value.size()));
}

}  // namespace absl

#endif  // ROBOTSTXT_OCAML_ABSL_STRINGS_MATCH_H_
