defmodule Absinthe.Test do
  def prime(schema_name) do
    :absinthe
    |> :code.priv_dir
    |> Path.join("introspection.graphql")
    |> Absinthe.run(schema_name)

    :ok
  end
end
