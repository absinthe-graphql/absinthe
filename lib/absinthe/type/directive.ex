defmodule Absinthe.Type.Directive do

  @moduledoc """
  Used by the GraphQL runtime as a way of modifying execution
  behavior.

  Type system creators will usually not create these directly.
  """

  alias Absinthe.Utils
  use Absinthe.Introspection.Kind

  @typedoc """
  A defined directive.

  * `:name` - The name of the directivee. Should be a lowercase `binary`. Set automatically when using `@absinthe :directive` from `Absinthe.Type.Definitions`.
  * `:description` - A nice description for introspection.
  * `:args` - A map of `Absinthe.Type.Argument` structs. See `Absinthe.Type.Definitions.args/1`.
  * `:on` - A list of places the directives can be used (can be `:operation`, `:fragment`, `:field`).
  * `:instruction` - A function that, given an argument, returns an instruction for the correct action to take

  The `:reference` key is for internal use.
  """
  @type t :: %{name: binary, description: binary, args: map, on: [atom], instruction: ((map) -> atom), reference: Type.Reference.t}
  defstruct name: nil, description: nil, args: nil, on: [], instruction: nil, reference: nil


  def build([{identifier, name}], blueprint) do
    args = args_ast(blueprint[:args])
    quote do
      %unquote(__MODULE__){
        name: unquote(name),
        args: unquote(args),
        description: unquote(blueprint[:description]) || @absinthe_doc,
        on: unquote(blueprint[:on]) || [],
        instruction: unquote(blueprint[:instruction]),
        reference: %{
          module: __MODULE__,
          identifier: unquote(identifier),
          location: %{
            file: __ENV__.file,
            line: __ENV__.line
          }
        }
      }
    end
  end

  defp args_ast(args) do
    ast = for {arg_name, arg_attrs} <- args do
      name = arg_name |> Atom.to_string |> Utils.camelize_lower
      arg_data = [name: name] ++ arg_attrs
      arg_ast = quote do
        %Absinthe.Type.Argument{
          unquote_splicing(arg_data)
        }
      end
      {arg_name, arg_ast}
    end

    quote do: %{unquote_splicing(ast)}
  end


end
