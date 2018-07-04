defmodule Absinthe.Blueprint.Transform.Builder do
  # TODO figure out this bit
  # if :selections in children do
  #   def walk(%unquote(node_name){flags: %{flat: _}} = node, acc, pre, post) do
  #     node_with_children(node, unquote(children -- [:selections]), acc, pre, post)
  #   end
  # end
  defp build_kv_pairs(children) do
    for child <- children do
      quote do
        {unquote(child), unquote(Macro.var(child, nil))}
      end
    end
  end

  defp build_updates(children) do
    for child <- children do
      child = Macro.var(child, nil)

      quote do
        {unquote(child), acc} = walk(unquote(child), acc, pre, post)
      end
    end
  end

  defmacro build_walkers(nodes_with_children) do
    for {node_name, children} <- nodes_with_children, children do
      kv_pairs = build_kv_pairs(children)
      updates = build_updates(children)

      quote do
        def walk_children(
              %unquote(node_name){unquote_splicing(kv_pairs)} = node,
              acc,
              pre,
              post
            ) do
          unquote_splicing(updates)

          node = %{node | unquote_splicing(kv_pairs)}
          {node, acc}
        end
      end
    end
  end
end
