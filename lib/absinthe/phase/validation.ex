defmodule Absinthe.Phase.Validation do

  alias Absinthe.{Blueprint, Phase}

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

    @spec put_error(Blueprint.node_t, Phase.Error.t) :: Blueprint.node_t
    def put_error(%{errors: errors} = node, error) do
      %{node | errors: [error | errors]}
    end

    def flag_invalid(node, flag) do
      %{node | flags: [flag | with_invalid(node.flags)]}
    end
    def with_invalid(flags) do
      if Enum.member?(flags, :invalid) do
        flags
      else
        [:invalid | flags]
      end
    end

  end

end
