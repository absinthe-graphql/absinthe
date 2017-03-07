defmodule Absinthe.Middleware do
  @moduledoc """
  Middleware enables custom resolution behaviour on a field.

  All resolution happens through middleware. Even `resolve` functions are middleware,
  as the `resolve` macro is just

  ```
  quote do
    middleware Absinthe.Resolution, unquote(function_ast)
  end
  ```

  Resolution happens by reducing a list of middleware onto an `%Absinthe.Resolution{}`
  struct.

  ## Example

  ```
  defmodule MyApp.Web.Authentication do
    @behaviour Absinthe.Middleware

    def call(resolution, _opts) do
      case resolution.context do
        %{current_user: _} ->
          resolution
        _ ->
          resolution
          |> Absinthe.Resolution.put_result({:error, "unauthenticated"})
      end
    end
  end
  ```

  By specifying `@behaviour Absinthe.Middleware` the compiler will ensure that
  we provide a `def call` callback. This function takes an `%Absinthe.Resolution{}`
  struct and will also need to return one such struct.

  On that struct there is a `context` key which holds the absinthe context. This
  is generally where things like the current user are placed. For more information
  on how the current user ends up in the context please see our full authentication
  guide on the website.

  Our `def call` function simply checks the context to see if there is a current
  user. If there is, we pass the resolution onward. If there is not, we update
  the resolution state to `:resolved` and place an error result.

  Middleware can be placed on a field in three different ways:

  1) Using the `set_middleware/2` callback in your schema.
  2) Using the `Absinthe.Schema.Notation.middleware/2` macro used inside a field definition
  3) Returning a `{:middleware, SomeMiddleware, opts}` tuple from a resolution function.

  ## The `set_middleware/2` callback.

  `set_middleware/2` is a function callback on a schema. When you `use Absinthe.Schema`
  a default implementation of this function is placed in your schema. It is passed
  the an Absinthe.Type.Field struct, as well as the Absinthe.Type.Object struct
  that the field is a part of. The middleware for a field exists as a list on
  the `Field` struct under the `:middleware` key.

  So for example if your schema contained:

  ```
  object :user do
    field :name, :string
    field :age, :integer
  end

  query do
    field :lookup_user, :user do
      resolve fn _, _ ->
        {:ok, %{name: "Bob"}}
      end
    end
  end

  def set_middleware(field, object) do
    # what is field?
    # what is object?
    field.middleware |> IO.inspect
    field
  end
  ```

  Given a document like:
  ```
  { lookupUser { name }}
  ```

  `object` is each object that is accessed while executing the document. In our
  case that is the `:user` object and the `:query` object. `field` is every
  field on that object. Concretely then, the function is called 3 times for that
  document, with the following arguments:

  ```
  YourSchema.set_middleware(lookup_user_field_of_root_query_object, root_query_object)
  # IO.inspect output: [{Absinthe.Resolution, #Function<20.52032458/0>}]
  YourSchema.set_middleware(name_field_of_user, user_object)
  # IO.inspect output: []
  YourSchema.set_middleware(age_field_of_user, user_object)
  # IO.inspect output: []
  ```

  In the latter two cases we see that the middleware list is empty. In the first
  case we see one middleware, which is placed by the `resolve` macro used in the
  `:lookup_user` field.

  ### Default Middleware

  One use of `set_middleware/2` is setting the default middleware on a field,
  replacing the `default_resolver` macro. By default middleware is placed on a
  field that looks up a field by its snake case identifier, ie `:resource_name`.
  Here is an example of how to change the default to use a camel cased string,
  IE, "resourceName".

  ```
  def set_middleware(%{middleware: []} = field, _object) do
    camelized =
      field.identifier
      |> Atom.to_string
      |> Macro.camelize

    middleware = [{{__MODULE__, :get_camelized_key}, camelized}]

    %{field | middleware: middleware}
  end
  def set_middleware(field, _object) do
    field
  end

  def get_camelized_key(%{source: source} = res, key) do
    %{res | state: :resolved, value: Map.get(source, key)}
  end
  ```

  There's a lot going on here so let's unpack it. The first thing to note
  is that we're using two clauses. We only want to set this middleware if there
  is not already middleware defined (by a resolve function or otherwise), so we
  pattern match on an empty list. Generating the camelized key is a simple matter
  of camelizing the field identifier.

  Next we need to build a list that defines what middleware we want to use. The
  form we're using is `{{MODULE, :function_to_call}, options_of_middleware}`. For
  our purposes we're simply going to use a function in the schema module itself
  `get_camelized_key`.

  Like all middleware functions, it takes a resolution struct, and options. The
  options is the caemlized key we generated. We get the camelized string from
  the parent map, and set it as the value of the resolution struct. Finally we
  mark the resolution state `:resolved`.

  ### Object Wide Authentication

  Let's use our authentication middleware from earlier, and place it on every
  field in the query object.

  ```
  defmodule MyApp.Web.Schema do
    use Absinthe.Schema

    query do
      field :private_field, :string do
        resolve fn _, _ ->
          {:ok, "this can only be viewed if authenticated"}
        end
      end
    end

    def set_middleware(field, %Absinthe.Type.Object{identifier: :query}) do
      field
      |> Map.update!(:middleware, [MyApp.Web.Authentication | &1])
    end
    def set_middleware(field, _object) do
      field
    end
  end
  ```

  ## TL;DR:

  - Middleware functions take a `%Absinthe.Resolution{}` struct, and return one.
  - All middleware on a field are always run, make sure to pattern match on the
    state if you care.
  """

  alias Absinthe.Blueprint.Document

  @typedoc """
  Any module that implements this behaviour
  """
  @type t :: atom

  @doc """
  This is the main middleware callback.

  It receives an `%Absinthe.Resolution{}` struct and it needs to return an
  `%Absinthe.Resolution{}` struct. The second argument will be whatever value
  was passed to the `plug` call that setup the middleware.
  """
  @callback call(Absinthe.Resolution.t, term) :: Absinthe.Resolution.t

  @doc """
  Optional callback to setup the resolution accumulator prior to resolution.

  NOTE: This function is given the full accumulator. Namespacing is suggested to
  avoid conflicts.
  """
  @callback before_resolution(resolution_acc :: Document.Resolution.acc) :: Document.Resolution.acc

  @doc """
  Optional callback to do something with the resolution accumulator after
  resolution.

  NOTE: This function is given the full accumulator. Namespacing is suggested to
  avoid conflicts.
  """
  @callback after_resolution(resolution_acc :: Document.Resolution.acc) :: Document.Resolution.acc

  @doc """
  Optional callback used to specify additional phases to run.

  Plugins may require additional resolution phases to be run. This function should
  use values set in the resolution accumulator to determine
  whether or not additional phases are required.

  NOTE: This function is given the whole pipeline to be inserted after the current
  phase completes.
  """
  @callback pipeline(next_pipeline :: Absinthe.Pipeline.t, resolution_acc :: map) :: Absinthe.Pipeline.t

  @optional_callbacks [
    before_resolution: 1,
    after_resolution: 1,
    pipeline: 2,
  ]

  @doc """
  Returns the list of default plugins.
  """
  def defaults() do
    [Absinthe.Middleware.Batch, Absinthe.Middleware.Async]
  end

  @doc """
  Returns the list of phases necessary to run resolution again.
  """
  def resolution_phases() do
    [
      Absinthe.Phase.Document.Execution.BeforeResolution,
      Absinthe.Phase.Document.Execution.Resolution,
      Absinthe.Phase.Document.Execution.AfterResolution,
    ]
  end

  @doc false
  def pipeline(plugins, resolution_acc) do
    Enum.reduce(plugins, [], fn plugin, pipeline ->
      plugin.pipeline(pipeline, resolution_acc)
    end)
    |> Enum.dedup
    |> List.flatten
  end
end
