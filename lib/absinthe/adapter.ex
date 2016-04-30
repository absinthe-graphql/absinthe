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
    adapter: Absinthe.Adapter.TheAdapterName
  ```

  Or, you can provide it as an option to `Absinthe.run/3`:

  ```
    Absinthe.run(query, MyApp.Schema,
             adapter: Absinthe.Adapter.TheAdapterName)
  ```

  Notably, this means you're able to switch adapters on case-by-case basis.
  In a Phoenix application, this means you could even support using different
  adapters for different clients.

  A custom adapter module must merely implement the `Absinthe.Adapter` protocol,
  in many cases with `use Absinthe.Adapter` and only overriding the desired
  functions.

  ## Writing Your Own

  Considering the default implementation of the callbacks handle traversing
  ASTs for you, there's a good chance all you may need to implement in your
  adapter is `to_internal_name/2` and `to_external_name/2`.

  Check out `Absinthe.Adapter.LanguageConventions` for a good example.

  Note that types that are defined external to your application (including
  the introspection types) may not be compatible if you're using a different
  adapter.
  """

  alias Absinthe.Execution

  @type t :: atom

  defmacro __using__(_) do
    quote do
      require Logger

      @behaviour unquote(__MODULE__)

      alias Absinthe.Execution
      alias Absinthe.Language

      def load_variables(variables) do
        variables
        |> map_var
      end

      defp do_load_variables(item) when is_map(item) do
        item |> map_var
      end
      defp do_load_variables(item) when is_list(item) do
        item |> list_var
      end
      defp do_load_variables(item) do
        item
      end

      defp list_var(items) do
        items |> list_var([])
      end
      defp list_var([], acc), do: :lists.reverse(acc)
      defp list_var([item | rest], acc) do
        list_var(rest, [do_load_variables(item) | acc])
      end

      defp map_var(items) do
        items
        |> Map.to_list
        |> map_var([])
      end
      defp map_var([], acc), do: :maps.from_list(acc)
      defp map_var([{k, v} | rest], acc) do
        item = {to_internal_name(k, :key_name), do_load_variables(v)}
        map_var(rest, [item | acc])
      end

      def load_document(node), do: adapt(node, :load)
      def dump_document(node), do: adapt(node, :dump)

      @ignore_nodes [
        Language.EnumTypeDefinition,
        Language.UnionTypeDefinition,
        Language.ScalarTypeDefinition,
        Language.StringValue,
        Language.BooleanValue,
        Language.IntValue,
        Language.FloatValue,
        Language.EnumValue
      ]

      # Rename a AST node and traverse children
      def adapt(%Language.Document{definitions: definitions} = node, adaptation) do
        %{
          node |
          definitions: definitions |> Enum.map(&adapt(&1, adaptation)),
         }
      end
      def adapt(%Language.VariableDefinition{variable: variable} = node, adaptation) do
        %{
          node |
          variable: Map.update!(variable, :name, &do_adapt(&1, :variable, adaptation))
         }
      end
      def adapt(%Language.Directive{} = node, adaptation) do
        %{node |
          arguments: Enum.map(node.arguments, &adapt(&1, adaptation))
        }
      end
      def adapt(%Language.Variable{} = node, adaptation) do
        %{node | name: do_adapt(node.name, :variable, adaptation)}
      end
      def adapt(%Language.OperationDefinition{} = node, adaptation) do
        %{node |
          name: node.name |> do_adapt(:operation, adaptation),
          selection_set: adapt(node.selection_set, adaptation),
          variable_definitions: node.variable_definitions |> Enum.map(&adapt(&1, adaptation))
        }
      end
      def adapt(%Language.ObjectDefinition{} = node, adaptation) do
        %{node |
          fields: Enum.map(node.fields, &adapt(&1, adaptation))
         }
      end
      def adapt(%Language.InputObjectDefinition{} = node, adaptation) do
        %{node |
          fields: Enum.map(node.fields, &adapt(&1, adaptation))
         }
      end
      def adapt(%Language.Fragment{} = node, adaptation) do
        %{node |
          directives: node.directives |> Enum.map(&adapt(&1, adaptation)),
          selection_set: adapt(node.selection_set, adaptation),
        }
      end
      def adapt(%Language.InlineFragment{} = node, adaptation) do
        %{node |
          directives: node.directives |> Enum.map(&adapt(&1, adaptation)),
          selection_set: adapt(node.selection_set, adaptation)}
      end
      def adapt(%Language.FragmentSpread{} = node, adaptation) do
        %{node |
          directives: node.directives |> Enum.map(&adapt(&1, adaptation))}
      end
      def adapt(%Language.SelectionSet{} = node, adaptation) do
        %{node |
          selections: node.selections |> Enum.map(&adapt(&1, adaptation))}
      end
      def adapt(%Language.Field{} = node, adaptation) do
        %{node |
          name: node.name |> do_adapt(:field, adaptation),
          selection_set: adapt(node.selection_set, adaptation),
          arguments: node.arguments |> Enum.map(&adapt(&1, adaptation)),
          directives: node.directives |> Enum.map(&adapt(&1, adaptation)),
        }
      end
      def adapt(%Language.FieldDefinition{} = node, adaptation) do
        %{node |
          name: node.name |> do_adapt(:field, adaptation),
          arguments: node.arguments |> Enum.map(&adapt(&1, adaptation)),
         }
      end
      def adapt(%Language.InputValueDefinition{} = node, adaptation) do
        %{node |
          name: node.name |> do_adapt(:field, adaptation),
         }
      end
      def adapt(%Language.ObjectValue{} = node, adaptation) do
        %{node |
          fields: node.fields |> Enum.map(&adapt(&1, adaptation))}
      end
      def adapt(%Language.ObjectField{} = node, adaptation) do
        %{node |
          name: node.name |> do_adapt(:field, adaptation),
          value: adapt(node.value, adaptation)}
      end
      def adapt(%Language.Argument{} = node, adaptation) do
        %{node |
          name: node.name |> do_adapt(:argument, adaptation),
          value: adapt(node.value, adaptation)}
      end
      def adapt(%Language.ListValue{} = node, adaptation) do
        %{node | values: Enum.map(node.values, &adapt(&1, adaptation))}
      end
      def adapt(%Language.InterfaceDefinition{} = node, adaptation) do
        %{node |
          fields: node.fields |> Enum.map(&adapt(&1, adaptation))}
      end
      def adapt(%{__struct__: str} = node, _) when str in @ignore_nodes do
        node
      end
      def adapt(nil, _) do
        nil
      end
      def adapt(other, _) do
        Logger.warn "Absinthe: #{__MODULE__} could not adapt #{inspect other}"
        other
      end

      defp do_adapt(value, role, :load) do
        to_internal_name(value, role)
      end
      defp do_adapt(value, role, :dump) do
        to_external_name(value, role)
      end

      def dump_results(%{data: data} = results) do
        %{results | data: do_dump_results(data)}
      end
      def dump_results(results) do
        results
      end

      # Rename a result data value and traverse children
      defp do_dump_results(node) when is_map(node) do
        for {key, val} <- node, into: %{} do
          case key do
            name when is_binary(name) ->
              {to_external_name(name, :result), do_dump_results(val)}
            other ->
              {key, do_dump_results(val)}
          end
        end
      end
      defp do_dump_results([node|rest]) do
        [do_dump_results(node)|do_dump_results(rest)]
      end
      defp do_dump_results(node) do
        node
      end

      def to_internal_name(external_name, _role), do: external_name

      def to_external_name(internal_name, _role), do: internal_name

      def format_error(%{name: name, role: role, value: value}, locations) when is_function(value) do
        external_name = name |> to_external_name(role)
        %{
          message: value.(external_name) |> to_string,
          locations: locations
         }
      end
      def format_error(%{value: value, role: role} = error_info, locations) when is_binary(value) do
        role_name = role |> to_string |> String.capitalize
        %{error_info | value: &"#{role_name} `#{&1}': #{value}"}
        |> format_error(locations)
      end
      def format_error(%{value: value} = error_info, locations) do
        %{error_info | value: inspect(value)}
        |> format_error(locations)
      end

      def format_error(%{value: value} = error_info) when not is_function(value) do
        %{error_info | value: inspect(value)}
        |> format_error([])
      end
      def format_error(%{value: value} = error_info) do
        format_error(error_info, [])
      end

      defoverridable [load_document: 1,
                      dump_document: 1,
                      adapt: 2,
                      dump_results: 1,
                      format_error: 2,
                      format_error: 1,
                      to_internal_name: 2,
                      to_external_name: 2]

    end
  end

  @doc """
  Convert the incoming (external) parsed document to the canonical (internal)
  representation that matches the schema.

  ## Examples

  ```
  def load_document(%{definitions: definitions} = document) do
    %{document | definitions: definitions |> Enum.map(&your_custom_transformation/1)}
  end
  ```
  """
  @callback load_document(Absinthe.Language.Document.t) :: Absinthe.Language.Document.t


  @doc """
  Convert an AST node to/from a representation.

  Called by `load_document/1`.

  ## Examples

  ```
  def adapt(%{definitions: definitions} = document, :load) do
    %{document | definitions: definitions |> Enum.map(&your_custom_loader/1)}
  end
  ```
  """
  @callback adapt(Absinthe.Language.t, :load | :dump) :: Absinthe.Language.t

  @doc """
  Convert the canonical (internal) results to the output (external)
  representation.

  ## Examples

  ```
  def dump_results(%{data: data} = results) do
    %{results | data: your_custom_transformation(data)}
  end
  ```
  """
  @callback dump_results(Absinthe.Execution.result_t) :: any

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

  @doc """
  Format an error using `value` for `name` located at the provided line/column
  locations.

  ## Examples

  Here's what the default implementation does:

      iex> format_error(%{name: "foo", role: :field, value: &"missing value '\#{&1}'"}, [%{line: 2, column: 4}])
      %{message: "missing value `foo'", locations: [%{line: 2, column: 4}]}

      iex> format_error(%{name: "foo", role: :field, value: "missing value"}, [%{line: 2, column: 4}])
      %{message: "Field `foo': missing value", locations: [%{line: 2, column: 4}]}

      # Without locations
      iex> format_error(%{name: "foo", role: :field, value: "missing value"})
      %{message: "Field `foo': missing value"}

  """
  @callback format_error(Execution.error_info_t, [Execution.error_location_t]) :: Execution.error_t
  @callback format_error(Execution.error_info_t) :: Execution.error_t
end
