defmodule Absinthe.Phase.Schema.ImportPrototypeDirectives do
  @moduledoc false

  # Imports directives from the prototype schema into the current schema.
  # This ensures the type system directives such as `deprecated` are available
  # for introspection as per the spec.
  #
  # Note that this does import the (type system) directives themselves, this
  # is already done in an earlier phase.

  @behaviour Absinthe.Phase
  alias Absinthe.Blueprint

  @spec run(Blueprint.t(), Keyword.t()) :: {:ok, Blueprint.t()}
  def run(blueprint, _options \\ []) do
    prototype_directives = Absinthe.Schema.directives(blueprint.prototype_schema)

    %{schema_definitions: [schema]} = blueprint

    schema = %{schema | directive_artifacts: prototype_directives}

    blueprint = %{blueprint | schema_definitions: [schema]}

    {:ok, blueprint}
  end
end
