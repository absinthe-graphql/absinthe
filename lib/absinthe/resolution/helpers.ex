defmodule Absinthe.Resolution.Helpers do
  @moduledoc """
  Handy functions for returning async or batched resolution functions

  It is automatically imported into all modules using `Absinthe.Schema.Notation`
  or (by extension) `Absinthe.Schema`.
  """

  alias Absinthe.Middleware

  @doc """
  Execute resolution field asynchronously.

  This is a helper function for using the `Absinthe.Middleware.Async`.

  Forbidden in mutation fields. (TODO: actually enforce this)
  """
  @spec async(( -> term)) :: {:plugin, Middleware.Async, term}
  @spec async(( -> term), Keyword.t) :: {:plugin, Middleware.Async, term}
  def async(fun, opts \\ []) do
    {:middleware, Middleware.Async, {fun, opts}}
  end

  @doc """
  Batch the resolution of several functions together.

  Helper function for creating `Absinthe.Middleware.Batch`

  # Example
  Raw usage:
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
  @spec batch(Middleware.Batch.batch_fun, term, Middleware.Batch.post_batch_fun) :: {:plugin, Middleware.Batch, term}
  @spec batch(Middleware.Batch.batch_fun, term, Middleware.Batch.post_batch_fun, opts :: Keyword.t):: {:plugin, Middleware.Batch, term}
  def batch(batch_fun, batch_data, post_batch_fun, opts \\ []) do
    batch_config = {batch_fun, batch_data, post_batch_fun, opts}
    {:middleware, Middleware.Batch, batch_config}
  end
end
