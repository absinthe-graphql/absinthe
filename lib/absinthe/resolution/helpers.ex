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
  @spec async(( -> term)) :: {:middleware, Middleware.Async, term}
  @spec async(( -> term), Keyword.t) :: {:middleware, Middleware.Async, term}
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
    field :name, :string
    field :author, :user do
      resolve fn post, _, _ ->
        batch({__MODULE__, :users_by_id}, post.author_id, fn batch_results ->
          {:ok, Map.get(batch_results, post.author_id)}
        end)
      end
    end
  end

  def users_by_id(_, user_ids) do
    users = Repo.all from u in User, where: u.id in ^user_ids
    Map.new(users, fn user -> {user.id, user} end)
  end
  ```
  """
  @spec batch(Middleware.Batch.batch_fun, term, Middleware.Batch.post_batch_fun) :: {:plugin, Middleware.Batch, term}
  @spec batch(Middleware.Batch.batch_fun, term, Middleware.Batch.post_batch_fun, opts :: Keyword.t):: {:plugin, Middleware.Batch, term}
  def batch(batch_fun, batch_data, post_batch_fun, opts \\ []) do
    batch_config = {batch_fun, batch_data, post_batch_fun, opts}
    {:middleware, Middleware.Batch, batch_config}
  end

  if Code.ensure_loaded?(Dataloader) do
    def on_load(loader, fun) do
      {:middleware, Absinthe.Middleware.Dataloader, {loader, fun}}
    end

    defp use_parent(loader, source, key, parent, args, opts) do
      with true <- Keyword.get(opts, :use_parent, false),
     {:ok, val} <- is_map(parent) && Map.fetch(parent, key) do
       Dataloader.put(loader, source, {key, args}, parent, val)
     else
       _ -> loader
     end
    end

    defp do_dataloader(parent, args, loader, source, key, opts) do
      loader
      |> use_parent(source, key, parent, args, opts)
      |> Dataloader.load(source, {key, args}, parent)
      |> on_load(fn loader ->
        result = Dataloader.get(loader, source, {key, args}, parent)
        {:ok, result}
      end)
    end

    @type dataloader_tuple :: {:middleware, Absinthe.Middleware.Dataloader, term}

    @spec dataloader(Dataloader.source_name) :: dataloader_tuple
    def dataloader(source) do
      fn parent, args, %{context: %{loader: loader}} = res ->
        key = res.definition.schema_node.identifier
        do_dataloader(parent, args, loader, source, key, [])
      end
    end

    @spec dataloader(Dataloader.source_name, [use_parent: true | false]) :: dataloader_tuple
    def dataloader(source, opts) when opts when is_list(opts) do
      fn parent, args, %{context: %{loader: loader}} = res ->
        key = res.definition.schema_node.identifier
        do_dataloader(parent, args, loader, source, key, opts)
      end
    end
    @spec dataloader(Dataloader.source_name, any, [use_parent: true | false]) :: dataloader_tuple
    def dataloader(source, key, opts \\ []) do
      fn parent, args, %{context: %{loader: loader}} ->
        do_dataloader(parent, args, loader, source, key, opts)
      end
    end
  end
end
