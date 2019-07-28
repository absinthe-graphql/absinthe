defmodule Absinthe.Blueprint.Schema.ScalarTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name]
  defstruct [
    :name,
    :identifier,
    :module,
    description: nil,
    parse: nil,
    serialize: nil,
    directives: [],
    source_location: nil,
    # Added by phases
    flags: %{},
    errors: [],
    __reference__: nil,
    __private__: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          directives: [Blueprint.Directive.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  def build(type_def, _schema) do
    %Absinthe.Type.Scalar{
      identifier: type_def.identifier,
      name: type_def.name,
      description: type_def.description,
      definition: type_def.module,
      serialize: type_def.serialize,
      parse: type_def.parse
    }
  end

  @doc false
  def functions(), do: [:serialize, :parse]

  defimpl Inspect do
    defdelegate inspect(term, options),
      to: Absinthe.Schema.Notation.SDL.Render
  end
end
