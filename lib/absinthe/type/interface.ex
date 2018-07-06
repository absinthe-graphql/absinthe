defmodule Absinthe.Type.Interface do
  @moduledoc """
  A defined interface type that represent a list of named fields and their
  arguments.

  Fields on an interface have the same rules as fields on an
  `Absinthe.Type.Object`.

  If an `Absinthe.Type.Object` lists an interface in its `:interfaces` entry,
  it guarantees that it defines the same fields and arguments that the
  interface does.

  Because sometimes it's for the interface to determine the implementing type of
  a resolved object, you must either:

  * Provide a `:resolve_type` function on the interface
  * Provide a `:is_type_of` function on each implementing type

  ```
  interface :named_entity do
    field :name, :string
    resolve_type fn
      %{age: _}, _ -> :person
      %{employee_count: _}, _ -> :business
      _, _ -> nil
    end
  end

  object :person do
    field :name, :string
    field :age, :string

    interface :named_entity
  end

  object :business do
    field :name, :string
    field :employee_count, :integer

    interface :named_entity
  end
  ```
  """

  use Absinthe.Introspection.Kind

  alias Absinthe.Type
  alias Absinthe.Schema

  @typedoc """
  * `:name` - The name of the interface type. Should be a TitleCased `binary`. Set automatically.
  * `:description` - A nice description for introspection.
  * `:fields` - A map of `Absinthe.Type.Field` structs. See `Absinthe.Schema.Notation.field/1` and
  * `:args` - A map of `Absinthe.Type.Argument` structs. See `Absinthe.Schema.Notation.arg/2`.
  * `:resolve_type` - A function used to determine the implementing type of a resolved object. See also `Absinthe.Type.Object`'s `:is_type_of`.

  The `:resolve_type` function will be passed two arguments; the object whose type needs to be identified, and the `Absinthe.Execution` struct providing the full execution context.

  The `__private__` and `:__reference__` keys are for internal use.
  """
  @type t :: %__MODULE__{
          name: binary,
          description: binary,
          fields: map,
          identifier: atom,
          resolve_type: (any, Absinthe.Resolution.t() -> atom | nil),
          __private__: Keyword.t(),
          __reference__: Type.Reference.t()
        }

  defstruct name: nil,
            description: nil,
            fields: nil,
            identifier: nil,
            resolve_type: nil,
            __private__: [],
            __reference__: nil,
            field_imports: []

  def build(%{attrs: attrs}) do
    fields =
      (attrs[:fields] || [])
      |> Type.Field.build()
      |> Type.Object.handle_imports(attrs[:field_imports])

    attrs = Keyword.put(attrs, :fields, fields)

    quote do
      %unquote(__MODULE__){unquote_splicing(attrs)}
    end
  end

  @spec resolve_type(Type.Interface.t(), any, Absinthe.Resolution.t()) :: Type.t() | nil
  def resolve_type(type, obj, env, opts \\ [lookup: true])

  def resolve_type(
        %{resolve_type: nil, __reference__: %{identifier: ident}},
        obj,
        %{schema: schema},
        opts
      ) do
    implementors = Schema.implementors(schema, ident)

    type_name =
      Enum.find(implementors, fn
        %{is_type_of: nil} ->
          false

        type ->
          type.is_type_of.(obj)
      end)

    if opts[:lookup] do
      Absinthe.Schema.lookup_type(schema, type_name)
    else
      type_name
    end
  end

  def resolve_type(%{resolve_type: resolver}, obj, %{schema: schema} = env, opts) do
    case resolver.(obj, env) do
      nil ->
        nil

      ident when is_atom(ident) ->
        if opts[:lookup] do
          Absinthe.Schema.lookup_type(schema, ident)
        else
          ident
        end
    end
  end

  @doc """
  Whether the interface (or implementors) are correctly configured to resolve
  objects.
  """
  @spec type_resolvable?(Schema.t(), t) :: boolean
  def type_resolvable?(schema, %{resolve_type: nil} = iface) do
    Schema.implementors(schema, iface)
    |> Enum.all?(& &1.is_type_of)
  end

  def type_resolvable?(_, %{resolve_type: _}) do
    true
  end

  @doc false
  @spec member?(t, Type.t()) :: boolean
  def member?(%{__reference__: %{identifier: ident}}, %{interfaces: ifaces}) do
    ident in ifaces
  end

  def member?(_, _) do
    false
  end

  @spec implements?(Type.Interface.t(), Type.Object.t(), Type.Schema.t()) :: boolean
  def implements?(interface, type, schema) do
    covariant?(interface, type, schema)
  end

  defp covariant?(%wrapper{of_type: inner_type1}, %wrapper{of_type: inner_type2}, schema) do
    covariant?(inner_type1, inner_type2, schema)
  end

  defp covariant?(%{name: name}, %{name: name}, _schema) do
    true
  end

  defp covariant?(%Type.Interface{fields: ifields}, %{fields: type_fields}, schema) do
    Enum.all?(ifields, fn {field_ident, ifield} ->
      case Map.get(type_fields, field_ident) do
        nil ->
          false

        field ->
          covariant?(ifield.type, field.type, schema)
      end
    end)
  end

  defp covariant?(nil, _, _), do: false
  defp covariant?(_, nil, _), do: false

  defp covariant?(itype, type, schema) when is_atom(itype) do
    itype = schema.__absinthe_type__(itype)
    covariant?(itype, type, schema)
  end

  defp covariant?(itype, type, schema) when is_atom(type) do
    type = schema.__absinthe_type__(type)
    covariant?(itype, type, schema)
  end
end
