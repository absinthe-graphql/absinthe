defmodule Absinthe.Blueprint.Schema.DirectiveDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    :module,
    :identifier,
    description: nil,
    directives: [],
    arguments: [],
    locations: [],
    repeatable: false,
    source_location: nil,
    expand: nil,
    errors: [],
    __reference__: nil,
    __private__: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil,
          arguments: [Blueprint.Schema.InputValueDefinition.t()],
          locations: [String.t()],
          repeatable: boolean(),
          source_location: nil | Blueprint.SourceLocation.t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  def build(type_def, schema) do
    %Absinthe.Type.Directive{
      name: type_def.name,
      identifier: type_def.identifier,
      description: type_def.description,
      args: Blueprint.Schema.ObjectTypeDefinition.build_args(type_def, schema),
      locations: type_def.locations |> Enum.sort(),
      definition: type_def.module,
      repeatable: type_def.repeatable,
      expand: type_def.expand
    }
  end

  @doc false
  def functions(), do: [:expand]

  defimpl Inspect do
    defdelegate inspect(term, options),
      to: Absinthe.Schema.Notation.SDL.Render
  end
end
