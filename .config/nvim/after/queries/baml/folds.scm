; Fold blocks
[
  (type_expression_block)
  (dynamic_type_expression_block)
  (value_expression_block)
  (type_builder_block)
  (expr_block)
  (class_constructor)
] @fold

; Fold function bodies
(expr_fn
  body: (_) @fold)

; Fold arrays and maps
[
  (array_expression)
  (map_expression)
] @fold

; Fold argument lists
(named_argument_list) @fold
(arguments_list) @fold

; Fold multiline comments
(block_comment) @fold
