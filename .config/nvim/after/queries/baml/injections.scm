; Comments
(comment) @injection.content
(#set! injection.language "comment")

(doc_comment) @injection.content
(#set! injection.language "comment")

(block_comment) @injection.content
(#set! injection.language "comment")

; Raw string literals can contain various languages
; Common patterns for detecting language in raw strings
(raw_string_literal) @injection.content
(#match? @injection.content "^(?:[a-zA-Z][a-zA-Z0-9_-]*)?#*\"```\\s*(\\w+)")
(#set! injection.language "regex")

; SQL in raw strings
(raw_string_literal) @injection.content
(#match? @injection.content "(?i)(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER)\\s")
(#set! injection.language "sql")

; JSON in raw strings
(raw_string_literal) @injection.content
(#match? @injection.content "^\\s*[\\[\\{]")
(#set! injection.language "json")

; Template strings might contain code
(template_declaration
  value: (raw_string_literal) @injection.content)
(#set! injection.combined)
