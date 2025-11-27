; Scopes
[
  (source_file)
  (type_expression_block)
  (value_expression_block)
  (expr_fn)
  (expr_block)
  (lambda)
  (type_builder_block)
] @local.scope

; Definitions
(type_expression_block
  name: (identifier) @local.definition.type)

(dynamic_type_expression_block
  (type_expression_block
    name: (identifier) @local.definition.type))

(type_alias
  name: (identifier) @local.definition.type)

(expr_fn
  name: (identifier) @local.definition.function)

(value_expression_block
  name: (identifier) @local.definition.function)

(template_declaration
  name: (identifier) @local.definition.function)

(named_argument
  name: (identifier) @local.definition.parameter)

(let_expr
  name: (identifier) @local.definition.variable)

(type_expression
  name: (identifier) @local.definition.field)

(value_expression
  name: (identifier) @local.definition.field)

; References
(fn_app
  function_name: (identifier) @local.reference)
