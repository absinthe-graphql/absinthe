defmodule Absinthe.Phase.Document.Validation do

  @type rule_t :: module

  alias Absinthe.{Blueprint, Phase}

  @structural_rules [
    Phase.Document.Validation.NoFragmentCycles,
  ]

  @data_rules [
    Phase.Validation.KnownDirectives,
    Phase.Document.Validation.ArgumentsOfCorrectType,
    Phase.Document.Validation.KnownArgumentNames,
    Phase.Document.Validation.ProvidedNonNullArguments,
    Phase.Document.Validation.UniqueArgumentNames,
    Phase.Document.Validation.UniqueInputFieldNames,
  ]

  def structural_pipeline do
    @structural_rules
  end

  def data_pipeline do
    @data_rules
  end

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__).Helpers
    end
  end

  defmodule Helpers do

    @spec any_invalid?([Blueprint.node_t]) :: boolean
    def any_invalid?(nodes) do
      nodes
      |> Enum.any?(&(Enum.member?(&1.flags, :invalid)))
    end

    @doc """
    If any of the provided sources are invalid, flag the node as
    invalid (and any other extra, dictated flags)
    """
    @spec inherit_invalid(Blueprint.node_t, [Blueprint.node_t], atom | [atom]) :: Blueprint.node_t
    @spec inherit_invalid(Blueprint.node_t, [Blueprint.node_t]) :: Blueprint.node_t
    def inherit_invalid(node, sources, extras \\ []) do
      if any_invalid?(sources) do
        %{node | flags: [:invalid] ++ List.wrap(extras) ++ node.flags}
      else
        node
      end
    end

  end

end
