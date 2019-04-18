defmodule Absinthe.Schema.Notation.SDL do
  @moduledoc false

  @doc """
  Parse definitions from SDL source
  """

  alias Absinthe.Blueprint

  @spec parse(sdl :: String.t(), Module.t(), map(), Keyword.t()) ::
          {:ok, [Absinthe.Blueprint.Schema.type_t()]} | {:error, String.t()}
  def parse(sdl, module, ref, opts) do
    with {:ok, doc} <- Absinthe.Phase.Parse.run(sdl) do
      definitions =
        doc.input.definitions
        |> Enum.map(&Absinthe.Blueprint.Draft.convert(&1, doc))
        |> Enum.map(&put_ref(&1, ref, opts))
        |> Enum.map(fn type -> %{type | module: module} end)

      {:ok, definitions}
    else
      {:error, %Absinthe.Blueprint{execution: %{validation_errors: [_ | _] = errors}}} ->
        error =
          errors
          |> Enum.map(&"#{&1.message} (#{inspect(&1.locations)})")
          |> Enum.join("\n")

        {:error, error}

      other ->
        other
    end
  end

  defp put_ref(%{fields: fields} = node, ref, opts) do
    %{node | fields: Enum.map(fields, &put_ref(&1, ref, opts))}
    |> do_put_ref(ref, opts)
  end

  defp put_ref(%{arguments: args} = node, ref, opts) do
    %{node | arguments: Enum.map(args, &put_ref(&1, ref, opts))}
    |> do_put_ref(ref, opts)
  end

  defp put_ref(%{directives: dirs} = node, ref, opts) do
    %{node | directives: Enum.map(dirs, &put_ref(&1, ref, opts))}
    |> do_put_ref(ref, opts)
  end

  defp put_ref(node, ref, opts), do: do_put_ref(node, ref, opts)

  @field_types [
    Blueprint.Schema.FieldDefinition,
    Blueprint.Schema.EnumValueDefinition,
    Blueprint.Schema.InputValueDefinition
  ]

  # TODO:  Which else of these need the conversions?
  # Blueprint.Schema.DirectiveDefinition,
  # Blueprint.Schema.EnumTypeDefinition,
  # Blueprint.Schema.InputObjectTypeDefinition,
  # Blueprint.Schema.InterfaceTypeDefinition,
  # Blueprint.Schema.ObjectTypeDefinition,
  # Blueprint.Schema.ScalarTypeDefinition,
  # Blueprint.Schema.UnionTypeDefinition
  # Blueprint.Schema.EnumValueDefinition
  # Blueprint.Schema.InputValueDefinition

  defp do_put_ref(%node_type{__reference__: nil, name: name} = node, ref, opts) do
    adapter = Keyword.get(opts, :adapter, Absinthe.Adapter.LanguageConventions)

    ref =
      case opts[:path] do
        nil ->
          ref

        path ->
          put_in(ref.location, %{file: {:unquote, [], [path]}, line: node.source_location.line})
      end

    %{node | __reference__: ref, name: name}
  end

  defp do_put_ref(node, _ref, _opts), do: node
end
