defmodule Absinthe.Blueprint.Execution do

  @moduledoc false

  alias Absinthe.Phase

  @type acc :: map

  defstruct [
    :adapter,
    :root_value,
    :schema,
    fragments: %{},
    fields_cache: %{},
    validation_errors: [],
    result: nil,
    acc: %{},
    context: %{},
    root_value: %{},
  ]

  @type t :: %__MODULE__ {
    validation_errors: [Phase.Error.t],
    result: nil | Result.Object.t,
    acc: acc,
  }

  @type node_t ::
      Result.Object
    | Result.List
    | Result.Leaf

  def get(%{execution: %{result: nil} = exec} = bp_root, operation) do
    result = %Absinthe.Blueprint.Result.Object{
      root_value: exec.root_value,
      emitter: operation,
    }

    %{exec |
      result: result,
      adapter: bp_root.adapter,
      schema: bp_root.schema,
      fragments: Map.new(bp_root.fragments, &{&1.name, &1})
    }
  end
  def get(%{execution: exec}, _) do
    exec
  end

  def get_result(%__MODULE__{result: nil, root_value: root_value}, operation) do
    %Absinthe.Blueprint.Result.Object{
      root_value: root_value,
      emitter: operation,
    }
  end
  def get_result(%{result: result}, _, _) do
    result
  end

  def update(resolution, result, context, acc) do
    %{resolution |
      context: context,
      result: result,
      acc: acc
    }
  end

end
