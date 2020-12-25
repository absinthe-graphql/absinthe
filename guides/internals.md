
### How it works inside

#### Schema

Defining the schema

* `import_sdl()`
  * `Absinthe.Schema.Notation.do_import_sdl`
    * `Absinthe.Schema.Notation.SDL.parse()`
      * `Absinthe.Phase.Parse.run(sdl)`
        * `toenize`
        * `parse`
        < `definitions`
      * `&Absinthe.Blueprint.Draft.convert()`
        * `Absinthe.Language` -> `Absinthe.Blueprint`
        - Blueprint _does_ have TypeSystemDirectives
          ? are they there in a resolver?
    * Store in `@__absinthe_sdl_definitions__`
* `Absinthe.Schema.Notation.__before_compile__`
  * define `def __absinthe_blueprint__`
* `Absinthe.Schema.__after_compile__`
  * `Absinthe.Pipeline.run`




#### `Absinthe.Lexer.tokenize()`

```graphql
type MyType {

}
```

2) Parser

* absinthe_parser.yrl

The Parser generates AST nodes of `Absinthe.Language` structs


3) `Absinthe.Language`

```elixir
%Absinthe.Language.ObjectTypeDefinition{
  name: "MyType"
}
```

Language structs are `convert`ed into `Blueprint.Schema` structs

4) `Absinthe.Blueprint`

```elixir
%Blueprint.Schema.ObjectTypeDefinition{
  name: "MyType",
  identifier: :my_type
}
```

Blueprints `build` final types

5) `Absinthe.Type`

```elixir
%Absinthe.Type.Object{
  name: "MyType",
  identifier: :my_type
}
```

#### Query

1) `Absinthe.Lexer.tokenize()`

* in `Absinthe.Phase.Parse`

2) `:absinthe_parser.parse(tokens)`

* in `Absinthe.Phase.Parse`
