defmodule Absinthe.Phase.Schema.Decorate do
  @moduledoc false
  @behaviour __MODULE__.Decorator

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  @impl Absinthe.Phase
  def run(blueprint, opts \\ []) do
    {:ok, schema} = Keyword.fetch(opts, :schema)
    decorator = Keyword.get(opts, :decorator, __MODULE__)
    blueprint = Blueprint.prewalk(blueprint, &handle_decorate(&1, schema, decorator))
    {:ok, blueprint}
  end

  @decorate_fields [
    Schema.ObjectTypeDefinition,
    Schema.InputObjectTypeDefinition
  ]
  @decorate_values [
    Schema.EnumTypeDefinition
  ]  
  @decorate_simple [
    Schema.DirectiveDefinition,
    Schema.InterfaceTypeDefinition,
    Schema.ScalarTypeDefinition,
    Schema.UnionTypeDefinition
  ]
  def handle_decorate(%node_module{} = node, schema, decorator) when node_module in @decorate_fields do
    # Apply field decorations
    node = update_in(node.fields, fn fields ->
      for field <- fields do
        decorations = schema.decorations(field, [node, schema])
        apply_decorations(field, decorations, decorator)
      end
    end)
    # Apply object type decorations
    decorations = schema.decorations(node, [schema])
    apply_decorations(node, decorations, decorator)
  end
  def handle_decorate(%node_module{} = node, schema, decorator) when node_module in @decorate_values do
    # Apply value decorations
    node = update_in(node.values, fn values ->
      for value <- values do
        decorations = schema.decorations(value, [node, schema])
        apply_decorations(value, decorations, decorator)
      end
    end)
    # Apply type decorations
    decorations = schema.decorations(node, [schema])
    apply_decorations(node, decorations, decorator)
  end  
  def handle_decorate(%node_module{} = node, schema, decorator) when node_module in @decorate_simple do
    decorations = schema.decorations(node, [schema])
    apply_decorations(node, decorations, decorator)
  end
  def handle_decorate(node, _schema, _decorator) do
    node
  end

  defp apply_decorations(node, decorations, decorator) do
    decorations
    |> List.wrap
    |> Enum.reduce(node, fn decoration, node ->
      decorator.apply_decoration(node, decoration)
    end) 
  end

  @impl __MODULE__.Decorator  
  def apply_decoration(node, {:description, text}) do
    %{node | description: text}
  end
  # TODO: This doesn't work yet.
  # def apply_decoration(node, {:resolve, resolver}) do    
  #   %{node |
  #     middleware: [{Absinthe.Resolution, resolver}]
  #   }
  # end

end
