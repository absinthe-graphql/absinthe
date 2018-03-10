defmodule Absinthe.Phase.Document.Validation.UniqueFragmentNames do
  @moduledoc false

  # Validates document to ensure that all fragments have unique names.

  alias Absinthe.{Blueprint, Phase}

  use Absinthe.Phase
  use Absinthe.Phase.Validation

  @doc """
  Run the validation.
  """
  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, _options \\ []) do
    fragments =
      for fragment <- input.fragments do
        process(fragment, input.fragments)
      end

    result = %{input | fragments: fragments}
    {:ok, result}
  end

  @spec process(Blueprint.Document.Fragment.Named.t(), [Blueprint.Document.Fragment.Named.t()]) ::
          Blueprint.Document.Fragment.Named.t()
  defp process(fragment, fragments) do
    if duplicate?(fragments, fragment) do
      fragment
      |> flag_invalid(:duplicate_name)
      |> put_error(error(fragment))
    else
      fragment
    end
  end

  # Whether a duplicate fragment is present
  @spec duplicate?([Blueprint.Document.Fragment.Named.t()], Blueprint.Document.Fragment.Named.t()) ::
          boolean
  defp duplicate?(fragments, fragment) do
    Enum.count(fragments, &(&1.name == fragment.name)) > 1
  end

  # Generate an error for a duplicate fragment.
  @spec error(Blueprint.Document.Fragment.Named.t()) :: Phase.Error.t()
  defp error(node) do
    %Phase.Error{
      phase: __MODULE__,
      message: error_message(node.name),
      locations: [node.source_location]
    }
  end

  @doc """
  Generate an error message for a duplicate fragment.
  """
  @spec error_message(String.t()) :: String.t()
  def error_message(name) do
    ~s(There can only be one fragment named "#{name}".)
  end
end
