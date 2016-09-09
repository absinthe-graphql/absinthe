defmodule Absinthe.Phase do

  @type t :: module
  @type result_t :: {:cont | :halt, any}

  alias __MODULE__

  defmacro __using__(_) do
    quote do
      @behaviour Phase

      def run(input), do: {:ok, input}

      defoverridable run: 1

      @spec flag_invalid(Blueprint.node_t) :: Blueprint.node_t
      def flag_invalid(%{flags: _} = node) do
        Absinthe.Blueprint.put_flag(node, :invalid, __MODULE__)
      end

      @spec flag_invalid(Blueprint.node_t, atom) :: Blueprint.node_t
      def flag_invalid(%{flags: _} = node, flag) do
        flagging = %{:invalid => __MODULE__, flag => __MODULE__}
        update_in(node.flags, &Map.merge(&1, flagging))
      end

      def put_flag(%{flags: _} = node, flag) do
        Absinthe.Blueprint.put_flag(node, flag, __MODULE__)
      end

      @spec put_error(Blueprint.node_t, Phase.Error.t) :: Blueprint.node_t
      def put_error(%{errors: _} = node, error) do
        update_in(node.errors, &[error | &1])
      end

      def any_invalid?(nodes) do
        Enum.any?(nodes, &match?(%{flags: %{invalid: _}}, &1))
      end

      def inherit_invalid(%{flags: _} = node, children, add_flag) do
        case any_invalid?(children) do
          true ->
            flag_invalid(node, add_flag)
          false ->
            node
        end
      end

    end
  end

  @callback run(any) :: {:ok, any} | {:error, Phase.Error.t}

end
