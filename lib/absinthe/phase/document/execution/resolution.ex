defmodule Absinthe.Phase.Document.Execution.Resolution do

  @moduledoc false

  # Runs resolution functions in a blueprint.
  #
  # Blueprint results are placed under `blueprint.result.resolution`. This is
  # because the results form basically a new tree from the original blueprint.

  alias Absinthe.{Blueprint, Type, Phase}
  alias Absinthe.Resolution.Plugin
  alias Blueprint.Document.Resolution

  alias Absinthe.Phase
  use Absinthe.Phase

  @resultdoc """
  ## For a data result

  `{:ok, any}` result will do.

  ### Examples:

  A simple integer result:
  
      {:ok, 1}

  Something more complex:
  
      {:ok, %Model.Thing{some: %{complex: :data}}}
  
  ## For an error result

  One or more errors for a field can be returned in a single `{:error, error_value}` tuple.

  `error_value` can be:
  - A simple error message string.
  - A map containing `:message` key, plus any additional serializable metadata.
  - A keyword list containing a `:message` key, plus any additional serializable metadata.
  - A list containing multiple of any/all of these.

  ### Examples

  A simple error message:

      {:error, "Something bad happened"}

  Multiple error messages:

      {:error, ["Something bad", "Even worse"]

  Single custom errors (note the required `:message` keys):

      {:error, message: "Unknown user", code: 21}
      {:error, %{message: "A database error occurred", details: format_db_error(some_value)}}

  Three errors of mixed types:

      {:error, ["Simple message", [message: "A keyword list error", code: 1], %{message: "A map error"}]}
      
  """

  @typedoc @resultdoc
  @type result :: {:ok, any} | {:error, error_value}

  @typedoc """
  An error message is a human-readable string describing the error that occurred.
  """
  @type error_message :: String.t

  @typedoc """
  Any serializable value.
  """
  @type serializable :: any  

  @typedoc """
  A custom error may be a `map` or a `Keyword.t`, but must contain a `:message` key.

  Note that the values that make up a custom error must be serializable.
  """
  @type custom_error :: %{required(:message) => error_message, optional(atom) => serializable} | Keyword.t

  @typedoc """
  An error value is a simple error message, a custom error, or a list of either/both of them.
  """
  @type error_value :: error_message | custom_error | [error_message | custom_error]

  @spec run(Blueprint.t, Keyword.t) :: Phase.result_t
  def run(bp_root, options \\ []) do
    case Blueprint.current_operation(bp_root) do
      nil -> {:ok, bp_root}
      op -> resolve_current(bp_root, op, options)
    end
  end

  defp resolve_current(bp_root, operation, options) do
    resolution = perform_resolution(bp_root, operation, options)

    blueprint = %{bp_root | resolution: resolution}

    bp_root.schema.resolution_plugins
    |> Plugin.pipeline(resolution)
    |> case do
      [] ->
        {:ok, blueprint}
      pipeline ->
        {:insert, blueprint, pipeline}
    end
  end

  defp perform_resolution(bp_root, operation, options) do
    root_value = Keyword.get(options, :root_value, %{})

    info   = build_info(bp_root, root_value, options)
    acc    = bp_root.resolution.acc
    result = bp_root.resolution |> Resolution.get_result(operation, root_value)

    acc = bp_root.schema |> before_resolution(acc)

    {result, acc} = walk_result(result, acc, operation, operation.schema_node, info)

    acc = bp_root.schema |> after_resolution(acc)

    Resolution.update(bp_root.resolution, result, acc)
  end

  defp before_resolution(schema, acc) do
    schema.resolution_plugins |> Enum.reduce(acc, &(&1.before_resolution(&2)))
  end

  defp after_resolution(schema, acc) do
    schema.resolution_plugins |> Enum.reduce(acc, &(&1.after_resolution(&2)))
  end

  defp build_info(bp_root, root_value, options) do
    context = Keyword.get(options, :context, %{})

    %Absinthe.Resolution{
      adapter: bp_root.adapter,
      context: context,
      root_value: root_value,
      schema: bp_root.schema,
      source: root_value,
    }
  end

  @doc """
  This function walks through any existing results. If no results are found at a
  given node, it will call the requisite function to expand and build those results
  """
  def walk_result(%{fields: nil} = result, acc, bp_node, _schema_type, info) do
    {fields, acc} = resolve_fields(bp_node, acc, info, result.root_value)
    {%{result | fields: fields}, acc}
  end
  def walk_result(%{fields: fields} = result, acc, bp_node, schema_type, info) do
    {fields, acc} = walk_results(fields, acc, bp_node, schema_type, info)

    {%{result | fields: fields}, acc}
  end
  def walk_result(%Resolution.Leaf{} = result, acc, _, _, _) do
    {result, acc}
  end
  def walk_result(%{values: values} = result, acc, bp_node, schema_type, info) do
    {values, acc} = walk_results(values, acc, bp_node, schema_type, info)
    {%{result | values: values}, acc}
  end
  def walk_result(%Resolution.PluginInvocation{} = node, acc, _bp_node, _schema_type, _info) do
    {result, acc} = Resolution.PluginInvocation.resolve(node, acc)

    build_result(result, acc, node.emitter, node.info, node.source)
  end

  def resolve_field(bp_field, acc, info, source) do
    info = %{info | definition: bp_field}

    bp_field.argument_data
    |> call_resolution_function(bp_field, info, source)
    |> build_result(acc, bp_field, info, source)
  end

  defp resolve_fields(parent, acc, info, source) do
    parent_type = case parent.schema_node do
      %Type.Field{} = schema_node ->
        schema_node.type
        |> Type.unwrap
        |> info.schema.__absinthe_type__
      other ->
        other
    end
    info = %{info | parent_type: parent_type, source: source}

    parent.fields
    |> Enum.filter(&field_applies?(&1, info, source, parent.schema_node))
    # Conceptually just |> Enum.map(&resolve_field/n)
    |> do_resolve_fields(acc, info, source, [])
  end

  # mechanical function for optimized field walking, ignore
  defp do_resolve_fields(fields, res_acc, info, source, acc)
  defp do_resolve_fields([], res_acc, _, _, acc), do: {:lists.reverse(acc), res_acc}
  defp do_resolve_fields([%{schema_node: nil} | fields], res_acc, info, source, acc) do
    do_resolve_fields(fields, res_acc, info, source, acc)
  end
  defp do_resolve_fields([field | fields], res_acc, info, source, acc) do
    {result, res_acc} = resolve_field(field, res_acc, info, source)
    do_resolve_fields(fields, res_acc, info, source, [result | acc])
  end

  # Normal :ok result
  defp build_result({:ok, result}, acc, bp_field, info, _) do
    full_type = Type.expand(bp_field.schema_node.type, info.schema)

    result
    |> to_result(bp_field, full_type)
    |> walk_result(acc, bp_field, full_type, info)
  end
  # Error result; force wrap of single, single-value Keyword.t errors
  defp build_result({:error, [{_, _}] = error_value} = err, acc, bp_field, info, source) do
    build_error_result(err, [error_value], acc, bp_field, info, source)
  end
  # Error result; force wrap of single, multiple-value Keyword.t errors
  defp build_result({:error, [{_, _} | _] = error_value} = err, acc, bp_field, info, source) do
    build_error_result(err, [error_value], acc, bp_field, info, source)
  end  
  # Error result; put errors
  defp build_result({:error, error_value} = err, acc, bp_field, info, source) do  
    build_error_result(err, List.wrap(error_value), acc, bp_field, info, source)
  end
  # Plugin result; init
  defp build_result({:plugin, plugin, data}, acc, emitter, info, source) do
    Resolution.PluginInvocation.init(plugin, data, acc, emitter, info, source)
  end
  # Everything else; raise
  defp build_result(other, _, field, _, source) do
    raise_result_error!(other, field, source)
  end

  defp raise_result_error!({:error, _} = value, field, source) do
    raise_result_error!(
      value, field, source,
      "You're returning an :error tuple, but did you forget to include a `:message`\nkey in every custom error (map or keyword list)?"
    )
  end
  defp raise_result_error!(value, field, source) do
    raise_result_error!(
      value, field, source,
      "Did you forget to return a valid `{:ok, any}` | `{:error, error_value}` tuple?"
    )    
  end

  defp raise_result_error!(value, field, source, guess) do
    raise Absinthe.ExecutionError, """    
    Invalid value returned from resolver.
    
    Resolving field:
    
        #{field.name}
        
    Defined at:
    
        #{field.schema_node.__reference__.location.file}:#{field.schema_node.__reference__.location.line}
    
    Resolving on:
    
        #{inspect source}

    Got value:
    
        #{inspect value}

    ...

    #{guess}

    ...

    The result must be one of the following...

    #{@resultdoc}
    """
  end

  defp build_error_result(original_value, error_values, acc, bp_field, info, source) do
    full_type = Type.expand(bp_field.schema_node.type, info.schema)
    result = to_result(nil, bp_field, full_type)
    result = Enum.reduce(Enum.reverse(error_values), result, &put_result_error_value(&1, &2, original_value, bp_field, source))
    {result, acc}
  end

  defp put_result_error_value(error_value, result, original_value, bp_field, source) do
    case split_error_value(error_value) do
      {[], _} ->
        raise_result_error!(original_value, bp_field, source)
      {[message: message], extra} ->
        message = ~s(In field "#{bp_field.name}": #{message})
        put_error(result, error(bp_field, message, extra))
    end
  end

  defp split_error_value(error_value) when is_list(error_value) or is_map(error_value) do
    Keyword.split(Enum.to_list(error_value), [:message])
  end
  defp split_error_value(error_value) when is_binary(error_value) do
    {[message: error_value], []}
  end

  # Introspection Field
  defp call_resolution_function(args, %{schema_node: %{name: "__" <> _}} = field, info, _) do
    field.schema_node.resolve.(args, info)
  end
  # Interface/Union Field
  defp call_resolution_function(args, field, %{parent_type: %abstract_mod{}} = info, source)
      when abstract_mod in [Type.Interface, Type.Union] do
    concrete_type = abstract_mod.resolve_type(info.parent_type, source, info)
    # Try again, using the concrete type
    call_resolution_function(args, field, put_in(info.parent_type, concrete_type), source)
  end
  defp call_resolution_function(args, field, %{parent_type: %Type.Object{} = concrete_type} = info, source) do
    concrete_schema_node = Map.fetch!(concrete_type.fields, field.schema_node.__reference__.identifier)
    Type.Field.resolve(concrete_schema_node, args, source, info)
  end

  @spec to_result(resolution_result :: term, blueprint :: Blueprint.t, schema_type :: Type.t) :: Resolution.t
  defp to_result(nil, blueprint, %Type.NonNull{} = schema_type) do
    raise Absinthe.ExecutionError, nil_value_error(blueprint, schema_type)
  end
  defp to_result(nil, blueprint, _) do
    %Resolution.Leaf{emitter: blueprint, value: nil}
  end
  defp to_result(root_value, blueprint, %Type.NonNull{of_type: inner_type}) do
    to_result(root_value, blueprint, inner_type)
  end
  defp to_result(root_value, blueprint, %Type.Scalar{} = schema_type) do
    %Resolution.Leaf{
      emitter: blueprint,
      value: Type.Scalar.serialize(schema_type, root_value)
    }
  end
  defp to_result(root_value, blueprint, %Type.Enum{} = schema_type) do
    %Resolution.Leaf{
      emitter: blueprint,
      value: Type.Enum.serialize(schema_type, root_value)
    }
  end
  defp to_result(root_value, blueprint, %Type.Object{}) do
    %Resolution.Object{root_value: root_value, emitter: blueprint}
  end
  defp to_result(root_value, blueprint, %Type.Interface{}) do
    %Resolution.Object{root_value: root_value, emitter: blueprint}
  end
  defp to_result(root_value, blueprint, %Type.Union{}) do
    %Resolution.Object{root_value: root_value, emitter: blueprint}
  end
  defp to_result(root_value, blueprint, %Type.List{of_type: inner_type}) do
    values =
      root_value
      |> List.wrap
      |> Enum.map(&to_result(&1, blueprint, inner_type))

    %Resolution.List{values: values, emitter: blueprint}
  end

  defp walk_results(values, res_acc, bp_node, inner_type, info, acc \\ [])
  defp walk_results([], res_acc, _, _, _, acc), do: {:lists.reverse(acc), res_acc}
  defp walk_results([value | values], res_acc, bp_node, inner_type, info, acc) do
    {result, res_acc} = walk_result(value, res_acc, bp_node, inner_type, info)
    walk_results(values, res_acc, bp_node, inner_type, info, [result | acc])
  end

  def field_applies?(%{name: _, type_conditions: []}, _, _, _) do
    true
  end
  def field_applies?(field, info, source, schema_type) do
    target_type = find_target_type(schema_type, info.schema)

    field.type_conditions
    |> Enum.map(&info.schema.__absinthe_type__(&1.name))
    |> Enum.all?(&passes_type_condition?(&1, target_type, source, info.schema))
  end

  # For fields
  def find_target_type(%{type: type}, schema) do
    find_target_type(type, schema)
  end
  # For lists and non-nulls
  def find_target_type(%{of_type: type}, schema) do
    find_target_type(type, schema)
  end
  def find_target_type(schema_type, schema) when is_atom(schema_type) or is_binary(schema_type) do
    schema.__absinthe_type__(schema_type)
  end
  def find_target_type(type, _schema) do
    type
  end

  def error(node, message, extra \\ []) do
    Phase.Error.new(
      __MODULE__,
      message,
      location: node.source_location,
      extra: extra
    )
  end

  @spec passes_type_condition?(Type.t, Type.t, any, Schema.t) :: boolean
  defp passes_type_condition?(%{name: name}, %{name: name}, _, _), do: true
  # The condition is an Object type and the current scope is a Union; Verify
  # that the Union has the Object type as a member and that the current source
  # object's concrete type matched the condition Object type.
  defp passes_type_condition?(%Type.Object{} = condition, %Type.Union{} = type, source, schema) do
    with true <- Type.Union.member?(type, condition) do
      concrete_type = Type.Union.resolve_type(type, source, %{schema: schema})
      passes_type_condition?(condition, concrete_type, source, schema)
    end
  end
  # The condition is an Object type and the current scope is an Interface; verify
  # that the Object type is a member of the Interface and that the current source
  # object's concrete type matched the condition Object type.
  defp passes_type_condition?(%Type.Object{} = condition, %Type.Interface{} = type, source, schema) do
    with true <- Type.Interface.member?(type, condition) do
      concrete_type = Type.Interface.resolve_type(type, source, %{schema: schema})
      passes_type_condition?(condition, concrete_type, source, schema)
    end
  end
  # The condition is an Interface type and the current scope is an Object type;
  # verify that the Object type is a member of the Interface.
  defp passes_type_condition?(%Type.Interface{} = condition, %Type.Object{} = type, _, _) do
    Type.Interface.member?(condition, type)
  end
  # The condition is an Interface type and the current scope is an abstract
  # (Union/Interface) type; Verify that the current source object's concrete
  # type is a member of the Interface.
  defp passes_type_condition?(%Type.Interface{} = condition, %abstract_mod{} = type, source, schema)
      when abstract_mod in [Type.Interface, Type.Union] do
    concrete_type = Type.Union.resolve_type(type, source, %{schema: schema})
    passes_type_condition?(condition, concrete_type, source, schema)
  end
  # Otherwise, nope.
  defp passes_type_condition?(_, _, _, _) do
    false
  end

  defp nil_value_error(blueprint, _schema_type) do
    """
    The field '#{blueprint.name}' resolved to nil, but it is marked non-null in your schema.
    Please ensure that '#{blueprint.name}' always resolves to a non-null value.

    The corresponding Absinthe blueprint is:
    #{inspect blueprint}
    """
  end
end
