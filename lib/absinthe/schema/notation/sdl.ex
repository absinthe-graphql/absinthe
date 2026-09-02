defmodule Absinthe.Schema.Notation.SDL do
  @moduledoc false

  @doc """
  Parse definitions from SDL source
  """

  alias Absinthe.{Blueprint, Language.Source}

  @spec parse(sdl :: Source.t() | Blueprint.t(), module(), map(), Keyword.t()) ::
          {:ok, [Blueprint.Schema.t()]} | {:error, String.t()}
  def parse(sdl, module, ref, opts) do
    with {:ok, doc} <- Absinthe.Phase.Parse.run(sdl) do
      definitions =
        Enum.flat_map(doc.input.definitions, fn node ->
          case Absinthe.Blueprint.Draft.convert(node, doc) do
            # Comments are converted to `nil` values to be ignored
            nil ->
              []

            converted ->
              type = put_ref(converted, ref, opts)
              [%{type | module: module}]
          end
        end)

      {:ok, definitions}
    else
      {:error, %Blueprint{execution: %{validation_errors: [_ | _] = errors}}} ->
        error =
          errors
          |> Enum.map(&"#{&1.message} (#{inspect(&1.locations)})")
          |> Enum.join("\n")

        {:error, error}

      other ->
        other
    end
  end

  defp put_ref(%{fields: fields, directives: directives} = node, ref, opts) do
    %{
      node
      | fields: Enum.map(fields, &put_ref(&1, ref, opts)),
        directives: Enum.map(directives, &put_ref(&1, ref, opts))
    }
    |> do_put_ref(ref, opts)
  end

  defp put_ref(%{fields: fields} = node, ref, opts) do
    %{node | fields: Enum.map(fields, &put_ref(&1, ref, opts))}
    |> do_put_ref(ref, opts)
  end

  defp put_ref(%{arguments: args, directives: directives} = node, ref, opts) do
    %{
      node
      | arguments: Enum.map(args, &put_ref(&1, ref, opts)),
        directives: Enum.map(directives, &put_ref(&1, ref, opts))
    }
    |> do_put_ref(ref, opts)
  end

  defp put_ref(%{arguments: args} = node, ref, opts) do
    %{node | arguments: Enum.map(args, &put_ref(&1, ref, opts))}
    |> do_put_ref(ref, opts)
  end

  defp put_ref(%{definition: definition} = node, ref, opts) do
    %{node | definition: put_ref(definition, ref, opts)}
    |> do_put_ref(ref, opts)
  end

  defp put_ref(%{directives: directives} = node, ref, opts) do
    %{node | directives: Enum.map(directives, &put_ref(&1, ref, opts))}
    |> do_put_ref(ref, opts)
  end

  defp put_ref(node, ref, opts), do: do_put_ref(node, ref, opts)

  defp do_put_ref(%{__reference__: nil} = node, ref, opts) do
    ref =
      case opts[:path] do
        nil ->
          ref

        path ->
          put_in(ref.location, %{
            file: {:unquote, [], [path]},
            line: node.source_location.line,
            column: node.source_location.column
          })
      end

    %{node | __reference__: ref}
  end

  defp do_put_ref(node, _ref, _opts), do: node
end
