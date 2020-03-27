defmodule Absinthe.Blueprint do
  @moduledoc """
  Represents the graphql document to be executed.

  Please see the code itself for more information on individual blueprint sub
  modules.
  """

  alias __MODULE__

  defstruct operations: [],
            directives: [],
            fragments: [],
            name: nil,
            schema_definitions: [],
            schema: nil,
            prototype_schema: nil,
            adapter: nil,
            initial_phases: [],
            # Added by phases
            telemetry: %{},
            flags: %{},
            errors: [],
            input: nil,
            source: nil,
            execution: %Blueprint.Execution{},
            result: %{}

  @type t :: %__MODULE__{
          operations: [Blueprint.Document.Operation.t()],
          schema_definitions: [Blueprint.Schema.SchemaDefinition.t()],
          directives: [Blueprint.Schema.DirectiveDefinition.t()],
          name: nil | String.t(),
          fragments: [Blueprint.Document.Fragment.Named.t()],
          schema: nil | Absinthe.Schema.t(),
          prototype_schema: nil | Absinthe.Schema.t(),
          adapter: nil | Absinthe.Adapter.t(),
          # Added by phases
          telemetry: map,
          errors: [Absinthe.Phase.Error.t()],
          flags: flags_t,
          input: nil | Absinthe.Language.Document.t(),
          source: nil | String.t() | Absinthe.Language.Source.t(),
          execution: Blueprint.Execution.t(),
          result: result_t,
          initial_phases: [Absinthe.Phase.t()]
        }

  @type result_t :: %{
          optional(:data) => term,
          optional(:errors) => [term],
          optional(:extensions) => term
        }

  @type node_t ::
          t()
          | Blueprint.Directive.t()
          | Blueprint.Document.t()
          | Blueprint.Schema.t()
          | Blueprint.Input.t()
          | Blueprint.TypeReference.t()

  @type use_t ::
          Blueprint.Document.Fragment.Named.Use.t()
          | Blueprint.Input.Variable.Use.t()

  @type flags_t :: %{atom => module}

  defdelegate prewalk(blueprint, fun), to: Absinthe.Blueprint.Transform
  defdelegate prewalk(blueprint, acc, fun), to: Absinthe.Blueprint.Transform
  defdelegate postwalk(blueprint, fun), to: Absinthe.Blueprint.Transform
  defdelegate postwalk(blueprint, acc, fun), to: Absinthe.Blueprint.Transform

  def find(blueprint, fun) do
    {_, found} =
      Blueprint.prewalk(blueprint, nil, fn
        node, nil ->
          if fun.(node) do
            {node, node}
          else
            {node, nil}
          end

        node, found ->
          # Already found
          {node, found}
      end)

    found
  end

  @doc false
  # This is largely a debugging tool which replaces `schema_node` struct values
  # with just the type identifier, rendering the blueprint tree much easier to read
  def __compress__(blueprint) do
    prewalk(blueprint, fn
      %{schema_node: %{identifier: id}} = node ->
        %{node | schema_node: id}

      node ->
        node
    end)
  end

  @spec fragment(t, String.t()) :: nil | Blueprint.Document.Fragment.Named.t()
  def fragment(blueprint, name) do
    Enum.find(blueprint.fragments, &(&1.name == name))
  end

  @doc """
  Add a flag to a node.
  """
  @spec put_flag(node_t, atom, module) :: node_t
  def put_flag(node, flag, mod) do
    update_in(node.flags, &Map.put(&1, flag, mod))
  end

  @doc """
  Determine whether a flag has been set on a node.
  """
  @spec flagged?(node_t, atom) :: boolean
  def flagged?(node, flag) do
    Map.has_key?(node.flags, flag)
  end

  @doc """
  Get the currently selected operation.
  """
  @spec current_operation(t) :: nil | Blueprint.Document.Operation.t()
  def current_operation(blueprint) do
    Enum.find(blueprint.operations, &(&1.current == true))
  end

  @doc """
  Update the current operation.
  """
  @spec update_current(t, (Blueprint.Document.Operation.t() -> Blueprint.Document.Operation.t())) ::
          t
  def update_current(blueprint, change) do
    ops =
      Enum.map(blueprint.operations, fn
        %{current: true} = op ->
          change.(op)

        other ->
          other
      end)

    %{blueprint | operations: ops}
  end

  @doc """
  Append the given field or fields to the given type
  """
  def extend_fields(blueprint = %Blueprint{}, ext_blueprint = %Blueprint{}) do
    ext_types = types_by_name(ext_blueprint)

    schema_defs =
      for schema_def = %{type_definitions: type_defs} <- blueprint.schema_definitions do
        type_defs =
          for type_def <- type_defs do
            case ext_types[type_def.name] do
              nil ->
                type_def

              %{fields: new_fields} ->
                %{type_def | fields: type_def.fields ++ new_fields}
            end
          end

        %{schema_def | type_definitions: type_defs}
      end

    %{blueprint | schema_definitions: schema_defs}
  end

  def extend_fields(blueprint, ext_blueprint) when is_atom(ext_blueprint) do
    extend_fields(blueprint, ext_blueprint.__absinthe_blueprint__)
  end

  def add_field(blueprint = %Blueprint{}, type_def_name, new_field) do
    schema_defs =
      for schema_def = %{type_definitions: type_defs} <- blueprint.schema_definitions do
        type_defs =
          for type_def <- type_defs do
            if type_def.name == type_def_name do
              %{type_def | fields: type_def.fields ++ List.wrap(new_field)}
            else
              type_def
            end
          end

        %{schema_def | type_definitions: type_defs}
      end

    %{blueprint | schema_definitions: schema_defs}
  end

  def find_field(%{fields: fields}, name) do
    Enum.find(fields, fn %{name: field_name} -> field_name == name end)
  end

  @doc """
  Index the types by their name
  """
  def types_by_name(blueprint = %Blueprint{}) do
    for %{type_definitions: type_defs} <- blueprint.schema_definitions,
        type_def <- type_defs,
        into: %{} do
      {type_def.name, type_def}
    end
  end

  def types_by_name(module) when is_atom(module) do
    types_by_name(module.__absinthe_blueprint__)
  end

  defimpl Inspect do
    defdelegate inspect(term, options),
      to: Absinthe.Schema.Notation.SDL.Render
  end
end
