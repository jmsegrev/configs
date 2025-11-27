; Indent inside blocks
[
  (type_expression_block)
  (dynamic_type_expression_block)
  (value_expression_block)
  (type_builder_block)
  (expr_block)
  (class_constructor)
  (array_expression)
  (map_expression)
  (named_argument_list)
  (arguments_list)
  (type_expression_contents)
  (value_expression_contents)
  (type_builder_contents)
] @indent.begin

; Dedent closing brackets
[
  "}"
  "]"
  ")"
] @indent.branch @indent.dedent

; Dedent certain keywords
[
  (type_expression)
  (value_expression)
  (map_entry)
  (stmt)
] @indent.auto

; Align parameters and arguments
(named_argument_list
  (named_argument) @indent.align)

(arguments_list
  (_expression) @indent.align)

(class_constructor
  (class_field_value_pair) @indent.align)

; Preserve indentation for multiline strings
[
  (raw_string_literal)
  (quoted_string_literal)
  (block_comment)
] @indent.ignore
