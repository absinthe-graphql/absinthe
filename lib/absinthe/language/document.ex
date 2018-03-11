defmodule Absinthe.Language.Document do
  @moduledoc false

  require Logger

  alias Absinthe.{Blueprint, Language}

  defstruct definitions: [],
            loc: %{start_line: nil}

  @typedoc false
  @type t :: %__MODULE__{
          definitions: [Absinthe.Traversal.Node.t()],
          loc: Language.loc_t()
        }

  @doc "Extract a named operation definition from a document"
  @spec get_operation(t, String.t()) :: nil | Absinthe.Language.OperationDefinition.t()
  def get_operation(%{definitions: definitions}, name) do
    definitions
    |> Enum.find(nil, fn
      %Language.OperationDefinition{name: ^name} ->
        true

      _ ->
        false
    end)
  end

  @doc false
  @spec fragments_by_name(Absinthe.Language.Document.t()) :: %{
          String.t() => Absinthe.Language.Fragment.t()
        }
  def fragments_by_name(%{definitions: definitions}) do
    definitions
    |> Enum.reduce(%{}, fn statement, memo ->
      case statement do
        %Absinthe.Language.Fragment{} ->
          memo |> Map.put(statement.name, statement)

        _ ->
          memo
      end
    end)
  end

  defimpl Blueprint.Draft do
    @operations [
      Language.OperationDefinition
    ]
    @types [
      Language.SchemaDefinition,
      Language.EnumTypeDefinition,
      Language.InputObjectTypeDefinition,
      Language.InputValueDefinition,
      Language.InterfaceTypeDefinition,
      Language.ObjectTypeDefinition,
      Language.ScalarTypeDefinition,
      Language.UnionTypeDefinition
    ]
    @directives [
      Language.DirectiveDefinition
    ]
    @fragments [
      Language.Fragment
    ]

    def convert(node, bp) do
      Enum.reduce(node.definitions, bp, &convert_definition(&1, node, &2))
    end

    defp convert_definition(%struct{} = node, doc, blueprint) when struct in @operations do
      update_in(blueprint.operations, &[Blueprint.Draft.convert(node, doc) | &1])
    end

    defp convert_definition(%struct{} = node, doc, blueprint) when struct in @types do
      update_in(blueprint.types, &[Blueprint.Draft.convert(node, doc) | &1])
    end

    defp convert_definition(%struct{} = node, doc, blueprint) when struct in @directives do
      update_in(blueprint.directives, &[Blueprint.Draft.convert(node, doc) | &1])
    end

    defp convert_definition(%struct{} = node, doc, blueprint) when struct in @fragments do
      update_in(blueprint.fragments, &[Blueprint.Draft.convert(node, doc) | &1])
    end
  end

  defimpl Absinthe.Traversal.Node do
    def children(%{definitions: definitions}, _schema), do: definitions
  end
end
