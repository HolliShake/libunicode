# libunicode (Zig)

A Zig implementation of the Unicode utilities and regular-expression helpers formerly implemented in C. The generated Unicode tables are embedded in `libunicode.zig`; the library does not need the C sources or table header at build time.

## Attribution

The original C implementation was authored by Fabrice Bellard (copyright 2017–2018). The original C utility code also credits Charlie Gordon (copyright 2018). This Zig port is based on that code and retains its MIT license; see [LICENSE](LICENSE).

## Build and test

Requires Zig 0.16.0 or a compatible development build, plus the platform C runtime for `realloc` and the C ABI.

```powershell
zig build-lib libunicode.zig -lc -static
zig test libunicode.zig -lc
```

Import the module directly from Zig with `@import("libunicode.zig")`. The `pub export` declarations retain the C ABI names and types. `CharRange` interval endpoints and normalization inputs are Unicode code points represented as `u32` values.

## API reference

Unless noted otherwise, range-producing functions expect an initialized, empty `CharRange`. A return of `0` means success, `-1` means allocation or processing failure, and `-2` means an unrecognized name. Ranges store sorted half-open intervals as endpoint pairs `[start, end)`. `CharRange.len` counts `u32` endpoints, not intervals.

### Character ranges

- `cr_init(cr, opaque, realloc_func)` initializes an empty range and installs the supplied realloc-compatible callback. Passing a null callback selects the system allocator. `opaque` is passed to the callback.
- `cr_free(cr)` releases the range storage through its configured callback. Do not use the range afterward unless reinitialized.
- `cr_realloc(cr, endpoint_capacity)` ensures room for the requested number of endpoints; returns `0` or `-1`.
- `cr_copy(dst, src)` copies the endpoint list into `dst`; returns `0` or `-1`.
- `cr_add_point(cr, point)` appends one endpoint. This is a low-level builder; use `cr_add_interval` for normal set construction.
- `cr_add_interval(cr, start, end)` appends a half-open interval. Intervals supplied directly must be in increasing order and should not overlap.
- `cr_op(dst, a, a_len, b, b_len, op)` writes the union, intersection, symmetric difference, or subtraction of two endpoint lists. `op` is one of `CR_OP_UNION`, `CR_OP_INTER`, `CR_OP_XOR`, or `CR_OP_SUB`. The destination must be initialized and empty.
- `cr_op1(cr, b, b_len, op)` applies the selected operation to the current range and `b`, replacing the current range.
- `cr_union_interval(cr, start, inclusive_end)` unions an inclusive interval into the range. Internally it converts the final endpoint to exclusive form.
- `cr_invert(cr)` complements the range over the `u32` endpoint domain.
- `cr_regexp_canonicalize(cr, is_unicode)` applies the JavaScript regular-expression case-canonicalization rules to the set in place. A nonzero `is_unicode` selects Unicode case folding.

### Normalization

`UnicodeNormalizationEnum` provides `UNICODE_NFC`, `UNICODE_NFD`, `UNICODE_NFKC`, and `UNICODE_NFKD`.

`unicode_normalize(dst, src, src_len, mode, opaque, realloc_func)` normalizes `src_len` code points and returns the output code-point count, or `-1` on allocation failure. On failure, `*dst` is null. The returned buffer is allocated by the provided realloc-compatible callback (or the system allocator when null); the caller owns it and must release it with the matching allocator, passing size zero. The callback has the form `void *callback(void *opaque, void *ptr, size_t new_size)`.

### Unicode names and sequences

- `unicode_script(cr, script_name, is_ext)` builds the named Unicode Script range; a nonzero `is_ext` includes Script_Extensions. Returns `0`, `-1`, or `-2` as described above.
- `unicode_general_category(cr, category_name)` builds a general-category range. Names include the standard category abbreviations and aggregate categories supported by the embedded Unicode tables.
- `unicode_prop(cr, property_name)` builds a binary Unicode property range. Property names are matched exactly against the generated property-name table.
- `unicode_sequence_prop(property_name, callback, opaque, scratch_range)` emits the named Unicode sequence property through `callback(opaque, codepoints, length)`. `scratch_range` is temporary workspace and must be initialized. Returns `0`, `-1`, or `-2`.

### Case conversion and predicates

- `lre_case_conv(result, codepoint, conv_type)` writes a case mapping to `result` and returns the number of output code points (one to three). `conv_type` is `0` for uppercase, `1` for lowercase, or `2` for case folding.
- `lre_canonicalize(codepoint, is_unicode)` returns the JavaScript regular-expression canonicalized code point; nonzero selects Unicode mode.
- `lre_is_cased(codepoint)` and `lre_is_case_ignorable(codepoint)` return zero or nonzero according to the corresponding Unicode property.
- `lre_is_id_start(codepoint)` and `lre_is_id_continue(codepoint)` test Unicode identifier-start and identifier-continue membership.
- `lre_is_space_non_ascii(codepoint)` tests the regular-expression whitespace set for code points at or above 256.
- `lre_is_space(codepoint)` tests whitespace for any code point, using the byte table below for values below 256.
- `lre_js_is_ident_first(codepoint)` and `lre_js_is_ident_next(codepoint)` apply the JavaScript identifier rules; the latter accepts ZWNJ and ZWJ.
- `lre_ctype_bits[256]` exposes the byte classification flags. Flags are `UNICODE_C_SPACE`, `UNICODE_C_DIGIT`, `UNICODE_C_UPPER`, `UNICODE_C_LOWER`, `UNICODE_C_UNDER`, `UNICODE_C_DOLLAR`, and `UNICODE_C_XDIGIT`.
- `lre_is_space_byte(byte)`, `lre_is_id_start_byte(byte)`, `lre_is_id_continue_byte(byte)`, and `lre_is_word_byte(byte)` are inline-style byte predicates. They return the matching bit mask (zero means false), not a normalized boolean.

Boolean parameters use `FALSE` (`0`) and `TRUE` (`1`). Predicate functions return zero or nonzero unless explicitly noted.
