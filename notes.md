
## Input Union!

* [x] Can define `input_union`
* [x] Generate absinthe type in schema definion
* [x] Can extract Input Union from query
* [x] Can resolve a query with an Input Union
* [x] Use `__inputname` for automatic resolve_type
* [x] >> Try using `__typename` ---> Maybe possible, but messy. Going with `__inputname` for now
* [x] >> drop need for resolve_type / is_type_of
* [x] >> make `__inputname` implicit
* [ ] >> Verify that `__inputname` doesn't show up in introspection 
* [x] There must be a default input_object for the case that `__inputname` is not specified
* [ ] >> Make `default` macro strict to a single `type` defined in an `input_union`
* [ ] >> Make `default` required
* [ ] >> Test `default` behavior -> what if document object doesn't match default?

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

> query gets parsed in `Absinthe.Phase.Parse`, get AST
  -> `Absinthe.Language.ObjectValue`
> run Blueprint.Draft.convert, get AST
  -> `Absinthe.Blueprint.Input.Object`

* query parsing generates `Blueprint.Input.Object`
  - defined `absinthe/lib/absinthe/blueprint/input/object.ex`
  - tested `absinthe/test/absinthe/language/input_object_test.exs`
  - referenced `absinthe/lib/absinthe/blueprint/input.ex`


##### Walking the blueprint


Absinthe.Blueprint.Input.Argument
  name: unionArg
  input_value.schema_node: %Absinthe.Type.InputUnion{}
  schema_node.type: %Absinthe.Type.Argument{type: this_or_that}

Absinthe.Blueprint.Document.Field
  name: eitherOr
  schema_node: %Absinthe.Blueprint.Document.Field{
                  arguments: []
                  schema_node: %Absinthe.Type.Field{
                    args: %{union_arg: %Absinthe.Type.Argument{type: :this_or_that}}
                  }
                }

------

Absinthe.Blueprint
  input: Absinthe.Language.Document
    = raw parsed query document
    > no changes needed
  operations: list of operations extracted from input
    * schema_node:
        RootQueryType (Absinthe.Type.Object)
    * selections:
        [Absinthe.Blueprint.Document.Field]
        blueprint of items queried in the given operation




QUESTION:

* [-] Do we need to get a `Blueprint.Input.Union`?
* [ ] How do we use __typename & not get introspection logic
* [x] Make sure non_null, list are handled


