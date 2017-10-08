defmodule Absinthe.Blueprint.Execution do

  @moduledoc false

  alias Absinthe.Phase

  @type acc :: map

  defstruct [
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

  def get_result(%__MODULE__{result: nil}, operation, root_value) do
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
