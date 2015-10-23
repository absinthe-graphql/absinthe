defmodule ExGraphQL.Type.Creation do

  defmodule Error do
    defexception type: nil, message: "could not create"
  end

  defmacro __using__(mod, options) do
    quote do
      def create(values) do
        Kernel.struct(unquote(mod), values)
        |> unquote(mod).setup
      end
      def create!(values) do
        case create(values) do
          {:ok, result} -> result
          {:error, error} = raise ExGraphQL.Type.Creation.Error, type: unquote(mod), message: error
        end
      end
    end
  end

end
