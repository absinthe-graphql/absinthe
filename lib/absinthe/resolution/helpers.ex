defmodule Absinthe.Resolution.Helpers do
  @moduledoc """
  Handy functions for returning async or batched resolution functions

  It is automatically imported into all modules using `Absinthe.Schema.Notation`
  or (by extension) `Absinthe.Schema`.
  """

  @doc """
  Execute resolution field asynchronously.

  This is a helper function for using the `Absinthe.Resolution.Plugin.Async`.

  Forbidden in mutation fields. (TODO: actually enforce this)
  """
  def async(fun) do
    {:plugin, Absinthe.Resolution.Plugin.Async, Task.async(fun)}
  end

  @doc """
  ```elixir
  object :post do
    field :title, :string
    field :body, :string
    field :author, :user do
      resolve fn post, _, _ ->
        batch({EctoBatch, :by_id}, {User, post.author_id}, fn batch_results ->
          {:ok, batch_results[User][post.author_id]}
        end)
      end
    end
  end
  field
  resolve fn post, _, _
  batch({EctoBatch, :by_id}, [])
  ```
  """
  def batch(batch_fun, batch_data, post_batch_fun) do
    batch_config = {batch_fun, batch_data, post_batch_fun}
    {:plugin, Absinthe.Resolution.Plugin.Batch, batch_config}
  end
end
