defmodule Absinthe.Adapter do
  @moduledoc """
  Absinthe supports an adapter mechanism that allows developers to define their
  schema using one code convention (eg, `snake_cased` fields and arguments), but
  accept query documents and return results (including names in errors) in
  another (eg, `camelCase`).

  Adapters aren't a part of GraphQL, but a utility that Absinthe adds so that
  both client and server can use use conventions most natural to them.

  Absinthe ships with two adapters:

  * `Absinthe.Adapter.LanguageConventions`, which expects schemas to be defined
    in `snake_case` (the standard Elixir convention), translating to/from `camelCase`
    for incoming query documents and outgoing results. (This is the default as of v0.3.)
  * `Absinthe.Adapter.Passthrough`, which is a no-op adapter and makes no
    modifications. (Note at the current time this does not support introspection
    if you're using camelized conventions).

  To set an adapter, you can set an application configuration value:

  ```
  config :absinthe,
    adapter: YourApp.Adapter.TheAdapterName
  ```

  Or, you can provide it as an option to `Absinthe.run/3`:

  ```
  Absinthe.run(
    query,
    MyApp.Schema,
    adapter: YourApp.Adapter.TheAdapterName
  )
  ```

  Notably, this means you're able to switch adapters on case-by-case basis.
  In a Phoenix application, this means you could even support using different
  adapters for different clients.

  A custom adapter module must merely implement the `Absinthe.Adapter` protocol,
  in many cases with `use Absinthe.Adapter` and only overriding the desired
  functions.

  ## Writing Your Own

  All you may need to implement in your adapter is `to_internal_name/2` and
  `to_external_name/2`.

  Check out `Absinthe.Adapter.LanguageConventions` for a good example.

  Note that types that are defined external to your application (including
  the introspection types) may not be compatible if you're using a different
  adapter.
  """

  @type t :: module

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      def to_internal_name(external_name, _role) do
        external_name
      end

      def to_external_name(internal_name, _role) do
        internal_name
      end

      defoverridable to_internal_name: 2,
                     to_external_name: 2
    end
  end

  @typedoc "The lexical role of a name within the document/schema."
  @type role_t :: :operation | :field | :argument | :result | :type | :directive

  @doc """
  Convert a name from an external name to an internal name.

  ## Examples

  Prefix all names with their role, just for fun!

  ```
  def to_internal_name(external_name, role) do
    role_name = role |> to_string
    role_name <> "_" <> external_name
  end
  ```
  """
  @callback to_internal_name(binary, role_t) :: binary

  @doc """
  Convert a name from an internal name to an external name.

  ## Examples

  Remove the role-prefix (the inverse of what we did in `to_internal_name/2` above):

  ```
  def to_external_name(internal_name, role) do
    internal_name
    |> String.replace(~r/^\#{role}_/, "")
  end
  ```
  """
  @callback to_external_name(binary, role_t) :: binary
end
