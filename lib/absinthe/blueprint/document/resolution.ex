defmodule Absinthe.Blueprint.Document.Resolution do

  @moduledoc false

  alias Absinthe.Phase
  alias __MODULE__

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
    result: nil | Resolution.Object.t,
    acc: acc,
  }

  @type node_t ::
      Resolution.Object
    | Resolution.List
    | Resolution.Leaf

  def get_result(%__MODULE__{result: nil}, operation, root_value) do
    %Absinthe.Blueprint.Document.Resolution.Object{
      root_value: root_value,
      emitter: operation,
    }
  end
  def get_result(%{result: result}, _, _) do
    result
  end

  def update(resolution, result, acc) do
    %{resolution |
      result: result,
      acc: acc
    }
  end

end
