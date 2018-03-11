defmodule Absinthe.Utils do
  @doc """
  Camelize a word, respecting underscore prefixes.

  ## Examples

  With an uppercase first letter:

  ```
  iex> camelize("foo_bar")
  "FooBar"
  iex> camelize("foo")
  "Foo"
  iex> camelize("__foo_bar")
  "__FooBar"
  iex> camelize("__foo")
  "__Foo"
  iex> camelize("_foo")
  "_Foo"
  ```

  With a lowercase first letter:
  ```
  iex> camelize("foo_bar", lower: true)
  "fooBar"
  iex> camelize("foo", lower: true)
  "foo"
  iex> camelize("__foo_bar", lower: true)
  "__fooBar"
  iex> camelize("__foo", lower: true)
  "__foo"
  iex> camelize("_foo", lower: true)
  "_foo"

  ```
  """
  @spec camelize(binary, Keyword.t()) :: binary
  def camelize(word, opts \\ [])

  def camelize("_" <> word, opts) do
    "_" <> camelize(word, opts)
  end

  def camelize(word, opts) do
    case opts |> Enum.into(%{}) do
      %{lower: true} ->
        {first, rest} = String.split_at(Macro.camelize(word), 1)
        String.downcase(first) <> rest

      _ ->
        Macro.camelize(word)
    end
  end

  @doc false
  def placement_docs([{_, placement} | _]) do
    placement
    |> do_placement_docs
  end

  defp do_placement_docs(toplevel: true) do
    """
    Top level in module.
    """
  end

  defp do_placement_docs(toplevel: false) do
    """
    Allowed under any block. Not allowed to be top level
    """
  end

  defp do_placement_docs(under: under) when is_list(under) do
    under =
      under
      |> Enum.sort_by(& &1)
      |> Enum.map(&"`#{&1}`")
      |> Enum.join(" ")

    """
    Allowed under: #{under}
    """
  end

  defp do_placement_docs(under: under) do
    do_placement_docs(under: [under])
  end

  @doc false
  def describe_builtin_module(module) do
    title =
      module
      |> Module.split()
      |> List.last()

    types =
      module.__absinthe_types__
      |> Map.keys()
      |> Enum.sort_by(& &1)
      |> Enum.map(fn identifier ->
        type = module.__absinthe_type__(identifier)

        """
        ## #{type.name}
        Identifier: `#{inspect(identifier)}`

        #{type.description}
        """
      end)

    directives =
      module.__absinthe_directives__
      |> Map.keys()
      |> Enum.sort_by(& &1)
      |> Enum.map(fn identifier ->
        directive = module.__absinthe_directive__(identifier)

        """
        ## #{directive.name}
        Identifier: `#{inspect(identifier)}`

        #{directive.description}
        """
      end)

    """
    # #{title}

    #{types ++ directives}
    """
  end
end
