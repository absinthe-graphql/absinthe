
## Input Union!

* [x] Can define `input_union`
* [x] Generate absinthe type in schema definion
* [ ] Can extract Input Union from query
* [ ] Can resolve a query with an Input Union

#### Defining the schema

This will probably be similar to defining a `Union` & `Input.Object`

* `input_object`
  > macro generates `Absinthe.Type.InputObject`
  > puts into `absinthe_definitions`
  > `Notation.Writer` maps through definitions writes `__absinthe_type*` functions

  - `absinthe/lib/absinthe/type/input_object.ex`
  - `absinthe/test/absinthe/type/input_object_test.exs`

* `union` macro generates `Absinthe.Type.Union`
  - `absinthe/lib/absinthe/type/union.ex`
  - `absinthe/test/absinthe/type/union_test.exs`

TRY:

* [x] A test like `union_test.exs`

  - `InputUnion` will need `resolve_type`
    - `InputObject` will need `is_type_of`


#### Defining a query

This will probably be similar to `Input.Object`

* query parsing generates `Blueprint.Input.Object`
  - defined `absinthe/lib/absinthe/blueprint/input/object.ex`
  - tested `absinthe/test/absinthe/language/input_object_test.exs`
  - referenced `absinthe/lib/absinthe/blueprint/input.ex`
