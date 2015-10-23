defmodule ExGraphQL.Type.Creation do

  defmodule Error do
    defexception type: nil, message: "could not create"
  end

  defmacro __using__(options) do
    quote do
      def create(values) do
        Kernel.struct(__MODULE__, values)
        |> __MODULE__.setup
      end
      def create!(values) do
        case create(values) do
          {:ok, result} -> result
          {:error, error} -> raise unquote(__MODULE__).Error, type: __MODULE__, message: error
        end
      end
    end
  end

end
