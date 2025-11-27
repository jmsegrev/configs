; Keywords
[
  "function"
  "test"
  "client"
  "client<llm>"
  "generator"
  "retry_policy"
  "type_builder"
  "template_string"
  "string_template"
  "type"
  "dynamic"
  "map"
  "fn"
  "let"
] @keyword

; "as" and "is" keywords removed - not in grammar

; Operators
[
  "="
  "=>"
  "->"
  "|"
  ".."
] @operator

; Variables and identifiers
(identifier) @variable

; Built-in types
(map_type
  "map" @type.builtin)

; Type definitions
(type_alias
  name: (identifier) @type.definition)

(type_alias
  target: (field_type_with_attr
    (field_type) @type))

(type_expression_block
  block_keyword: (identifier) @keyword.type
  name: (identifier) @type.definition)

(dynamic_type_expression_block
  (type_expression_block
    name: (identifier) @type.definition))

; Functions
(expr_fn
  name: (identifier) @function.definition)

(value_expression_block
  keyword: (_) @keyword.function
  name: (identifier) @function.definition)

(fn_app
  function_name: (identifier) @function.call)

(template_declaration
  name: (identifier) @function.definition)

; Parameters
(named_argument
  name: (identifier) @variable.parameter)

(lambda
  params: (named_argument_list
    (named_argument
      name: (identifier) @variable.parameter)))

; Properties/Fields
(type_expression
  name: (identifier) @property)

(value_expression
  name: (identifier) @property)

(map_entry
  key: (map_key
    (identifier) @property))

(map_entry
  key: (map_key
    (quoted_string_literal) @property))

(class_field_value_pair
  field_name: (identifier) @property)

; Attributes
(block_attribute
  "@@" @attribute
  (identifier) @attribute)

(field_attribute
  "@" @attribute
  (identifier) @attribute)

; Constants - removed boolean/null as they don't exist in BAML grammar

; Numbers
(numeric_literal) @number

; Strings
(quoted_string_literal) @string
(raw_string_literal) @string.special
(unquoted_string_literal) @string

; No escape sequences in BAML grammar

; Template/Jinja expressions
(jinja_expression) @embedded

; Comments
(doc_comment) @comment.documentation
(comment) @comment
(block_comment) @comment.block
(trailing_comment) @comment

; Punctuation
[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
  "<"
  ">"
] @punctuation.bracket

[
  ","
  ";"
  ":"
  "::"
  "."
] @punctuation.delimiter

; Special
(ERROR) @error
