#ifndef ROBOTSTXT_OCAML_ABSL_STRINGS_ASCII_H_
#define ROBOTSTXT_OCAML_ABSL_STRINGS_ASCII_H_

#include "absl/strings/string_view.h"

namespace absl {

inline bool ascii_islower(unsigned char c) { return c >= 'a' && c <= 'z'; }
inline bool ascii_isupper(unsigned char c) { return c >= 'A' && c <= 'Z'; }
inline bool ascii_isalpha(unsigned char c) {
  return ascii_islower(c) || ascii_isupper(c);
}
inline bool ascii_isxdigit(unsigned char c) {
  return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') ||
         (c >= 'A' && c <= 'F');
}
inline char ascii_toupper(unsigned char c) {
  return ascii_islower(c) ? static_cast<char>(c - 'a' + 'A')
                          : static_cast<char>(c);
}
inline char ascii_tolower(unsigned char c) {
  return ascii_isupper(c) ? static_cast<char>(c - 'A' + 'a')
                          : static_cast<char>(c);
}

inline bool ascii_isspace(unsigned char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

inline string_view StripAsciiWhitespace(string_view value) {
  while (!value.empty() && ascii_isspace(value.front())) value.remove_prefix(1);
  while (!value.empty() && ascii_isspace(value.back())) value.remove_suffix(1);
  return value;
}

}  // namespace absl

#endif  // ROBOTSTXT_OCAML_ABSL_STRINGS_ASCII_H_
