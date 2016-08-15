defmodule Absinthe.Schema.Notation.FieldImporter do
  def normalize_definitions(definitions) do
    definitions_map = definitions |> build_def_map
    errors = []
    acc = []

    import_context = %{
      mapping: definitions_map,
      parent: nil,
      graph: :digraph.new([:acyclic]),
    }

    normalize(definitions, import_context, errors, acc)
  end

  def normalize([], _ctx, errors, acc) do
    {:lists.reverse(acc), Enum.uniq(errors)}
  end
  def normalize([definition | rest], ctx, errors, acc) do
    case do_normalize(definition, put_in(ctx.parent, definition)) do
      {:ok, definition} ->
        normalize(rest, ctx, errors, [definition | acc])
      {:error, error} ->
        normalize(rest, ctx, [error | errors], acc)
    end
  end

  defp do_normalize(obj, ctx) do
    _ = :digraph.add_vertex(ctx.graph, ctx.parent.identifier)
    case obj.attrs[:field_imports] do
      []->
        {:ok, obj}
      nil ->
        {:ok, obj}
      imports ->
        with {:ok, fields} <- import_fields(imports, put_in(ctx.parent, obj), obj.attrs[:fields]) do
          {:ok, %{obj | attrs: Keyword.update!(obj.attrs, :fields, fn _ -> fields end)}}
        end
    end
  end

  # Walk through the items we want to import fields from, get their fields,
  # and walk to any objects THEY import to get their fields, etc.
  defp import_fields(nil, _ctx, fields), do: {:ok, fields}
  defp import_fields([], _ctx, fields), do: {:ok, fields}
  defp import_fields([{obj_ref, _opts} | rest], ctx, existing_fields) do
    with :ok <- ensure_no_circles(ctx, obj_ref),
    {:ok, %{attrs: attrs} = obj} <- find_obj(obj_ref, ctx),
    {:ok, fields} <- import_fields(attrs[:field_imports], put_in(ctx.parent, obj), attrs[:fields]) do
      import_fields(rest, ctx, fields ++ existing_fields)
    end
  end

  defp ensure_no_circles(ctx, ref) do
    _ = :digraph.add_vertex(ctx.graph, ref)
    case :digraph.add_edge(ctx.graph, ctx.parent.identifier, ref) do
      {:error, {:bad_edge, path}} ->
        # All just error generation logic
        deps = [ctx.parent.identifier | path]
        |> Enum.map(&"`#{&1}'")
        |> Enum.join(" => ")

        msg = """
        Field Import Cycle Error

        Type #{ctx.parent.identifier} has an import cycle via: (#{deps})
        """

        {:error, error(ctx.parent, msg)}
      _ ->
        :ok
    end
  end

  defp find_obj(obj_ref, ctx) do
    with :error <- Map.fetch(ctx.mapping, obj_ref) do
      {:error, error(ctx.parent, "Type #{inspect obj_ref} not found in schema")}
    end
  end

  defp error(definition, msg) do
    %{
      location: %{file: definition.file, line: definition.line},
      data: %{artifact: msg, value: definition.identifier}
    }
  end

  defp build_def_map(definitions) do
    definitions
    |> Enum.filter(&(&1.identifier))
    |> Map.new(&{&1.identifier, &1})
  end
end
