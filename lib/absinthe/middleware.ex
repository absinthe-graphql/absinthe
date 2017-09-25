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

  Resolution happens by reducing a list of middleware spec onto an `%Absinthe.Resolution{}`
  struct.

  ## Example

  ```
  defmodule MyApp.Web.Authentication do
    @behaviour Absinthe.Middleware

    def call(resolution, _config) do
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

  Our `call/2` function simply checks the context to see if there is a current
  user. If there is, we pass the resolution onward. If there is not, we update
  the resolution state to `:resolved` and place an error result.

  Middleware can be placed on a field in three different ways:

  1. Using the `Absinthe.Schema.Notation.middleware/2` macro used inside a field definition
  2. Using the `middleware/3` callback in your schema.
  3. Returning a `{:middleware, middleware_spec, config}` tuple from a resolution function.

  ## The `middleware/2` macro

  For placing middleware on a particular field, it's handy to use
  the `middleware/2` macro.

  Middleware will be run in the order in which they are specified.
  The `middleware/3` callback has final say on what middleware get
  set.

  Examples

  `MyApp.Web.Authentication` would run before resolution, and `HandleError` would run after.
  ```
  field :hello, :string do
    middleware MyApp.Web.Authentication
    resolve &get_the_string/2
    middleware HandleError, :foo
  end
  ```

  Anonymous functions are a valid middleware spec. A nice use case
  is altering the context in a logout mutation. Mutations are the
  only time the context should be altered. This is not enforced.
  ```
  field :logout, :query do
    middleware fn res, _ ->
      %{res |
        context: Map.delete(res.context, :current_user),
        value: "logged out",
        state: :resolved
      }
    end
  end
  ```

  `middleware/2` even accepts local public function names. Note
  that `middleware/2` is the only thing that can take local function
  names without an associated module. If not using macros, use
  `{{__MODULE__, :function_name}, []}`
  ```
  def auth(res, _config) do
    # auth logic here
  end

  query do
    field :hello, :string do
      middleware :auth
      resolve &get_the_string/2
    end
  end
  ```

  ## The `middleware/3` callback.

  `middleware/3` is a function callback on a schema. When you `use Absinthe.Schema`
  a default implementation of this function is placed in your schema. It is passed
  the existing middleware for a field, the field itself, and the object
  that the field is a part of.

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

  def middleware(middleware, field, object) do
    middleware |> IO.inspect
    field |> IO.inspect
    object |> IO.inspect

    middleware
  end
  ```

  Given a document like:
  ```
  { lookupUser { name }}
  ```

  `object` is each object that is accessed while executing the document. In our
  case that is the `:user` object and the `:query` object. `field` is every
  field on that object, and middleware is a list of whatever middleware
  spec have been configured by the schema on that field. Concretely
  then, the function is called 3 times for that document, with the following arguments:

  ```
  YourSchema.middleware([{Absinthe.Resolution, #Function<20.52032458/0>}], lookup_user_field_of_root_query_object, root_query_object)
  YourSchema.middleware([], name_field_of_user, user_object)
  YourSchema.middleware([], age_field_of_user, user_object)
  ```

  In the latter two cases we see that the middleware list is empty. In the first
  case we see one middleware spec, which is placed by the `resolve` macro used in the
  `:lookup_user` field.

  ### Default Middleware

  One use of `middleware/3` is setting the default middleware on a field,
  replacing the `default_resolver` macro. By default middleware is placed on a
  field that looks up a field by its snake case identifier, ie `:resource_name`.
  Here is an example of how to change the default to use a camel cased string,
  IE, "resourceName".

  ```
  def middleware([], %{identifier: identifier}, _object) do
    camelized =
      identifier
      |> Atom.to_string
      |> Macro.camelize

    [{{__MODULE__, :get_camelized_key}, camelized}]
  end
  def middleware(middleware, _field, _object) do
    middleware
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
  options is the camelized key we generated. We get the camelized string from
  the parent map, and set it as the value of the resolution struct. Finally we
  mark the resolution state `:resolved`.

  Side note: This `middleware/3` function is called whenever we pull
  the type out of the schema. The middleware itself is run every time
  we get a field on an object. If we have 1000 objects and we were
  doing the camelization logic INSIDE the middleware, we would compute
  the camelized string 1000 times. By doing it in the `def middleware`
  callback we do it just once.

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

    def middleware(middleware, _field, %Absinthe.Type.Object{identifier: identifier})
    when identifier in [:query, :subscription, :mutation] do
      [MyApp.Web.Authentication | middleware]
    end
    def middleware(middleware, _field, _object) do
      middleware
    end
  end
  ```

  **It is important to note that we are matching for the `:query`, `:subscription` or
  `:mutation` identifier types. We do this because the middleware function will be
  called for each field in the schema. It is also important to provide a fallback so
  that the default `Absinthe.Middleware.MapGet` is configured.**

  ## Main Points

  - Middleware functions take a `%Absinthe.Resolution{}` struct, and return one.
  - All middleware on a field are always run, make sure to pattern match on the
    state if you care.
  """

  @type function_name :: atom

  @type spec :: module | {module, term} | {{module, function_name}, term} | ((Absinthe.Resolution.t, term) -> Absinthe.Resolution.t)

  @doc """
  This is the main middleware callback.

  It receives an `%Absinthe.Resolution{}` struct and it needs to return an
  `%Absinthe.Resolution{}` struct. The second argument will be whatever value
  was passed to the `plug` call that setup the middleware.
  """
  @callback call(Absinthe.Resolution.t, term) :: Absinthe.Resolution.t
end
