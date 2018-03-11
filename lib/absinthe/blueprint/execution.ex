defmodule Absinthe.Blueprint.Execution do
  @moduledoc """
  Blueprint Execution Data

  The `%Absinthe.Blueprint.Execution{}` struct holds on to the core values that
  drive a document's execution.

  Here's how the execution flow works. Given a document like:
  ```
  {
    posts {
      title
      author { name }
    }
  }
  ```

  After all the validation happens, and we're actually going to execute this document,
  an `%Execution{}` struct is created. This struct is passed to each plugin's
  `before_resolution` callback, so that plugins can set initial values in the accumulator
  or context.

  Then the resolution phase walks the document until it hits the `posts` field.
  To resolve the posts field, an `%Absinthe.Resolution{}` struct is created from
  the `%Execution{}` struct. This resolution struct powers the normal middleware
  resolution process. When a field has resolved, the `:acc`, `:context`, and `:field_cache`
  values within the resolution struct are pulled out and used to update the execution.
  """

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
    root_value: %{}
  ]

  @type t :: %__MODULE__{
          validation_errors: [Phase.Error.t()],
          result: nil | Result.Object.t(),
          acc: acc
        }

  @type node_t ::
          Result.Object
          | Result.List
          | Result.Leaf

  def get(%{execution: %{result: nil} = exec} = bp_root, operation) do
    result = %Absinthe.Blueprint.Result.Object{
      root_value: exec.root_value,
      emitter: operation
    }

    %{
      exec
      | result: result,
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
      emitter: operation
    }
  end

  def get_result(%{result: result}, _, _) do
    result
  end

  def update(resolution, result, context, acc) do
    %{resolution | context: context, result: result, acc: acc}
  end
end
