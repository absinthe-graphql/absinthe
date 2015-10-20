defmodule ExGraphQL.Validation.Context do
  @type t :: %{schema: ExGraphQL.Type.Schema, document: ExGraphQL.Language.Document,
               type_info: nil, fragments: map}
  defstruct schema: nil, document: nil, type_info: nil, fragments: %{}

  @doc "Lookup fragment by name"
  @spec fragment(t, binary) :: nil | ExGraphQL.Language.FragmentDefinition.t
  def fragment(%{fragments: fragment}, name) do
    fragment |> Map.get(name)
  end

  @doc "Populate context with document fragments"
  @spec with_fragments(t) :: t
  def with_fragments(%{document: document} = context) do
    fragments = document |> ExGraphQL.Language.Document.fragments_by_name
    %{context | fragments: fragments}
  end

  def type(%{type_info: info}), do: info.type

  def parent_type(%{type_info: info}), do: info.parent_type

  def input_type(%{type_info: info}), do: info.input_type

  def field_def(%{type_info: info}), do: info.field_def

  def directive(%{type_info: info}), do: info.directive

  def argument(%{type_info: info}), do: info.argument

end
