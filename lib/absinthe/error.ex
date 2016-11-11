defmodule Absinthe.Error do

  @doc """
  Resolver error allowing to specify custom field to the GraphqL error object.

  To have extra fields in the GraphQL error object, resolver can return:

    ```
    {:error, Absinthe.Error.new("Error message", code: 42)}
    ```
  """

  alias __MODULE__, as: This

  defstruct [
    message: nil,
    extra: []
  ]

  @type t :: %This{
    message: binary,
    extra: Keyword.t
  }

  @spec new(binary) :: This.t
  @spec new(binary, Keyword.t) :: This.t
  def new(message, extra \\ []), do: %This{message: message, extra: extra}

end