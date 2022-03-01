defmodule Absinthe.Type do
  @moduledoc false

  alias __MODULE__

  alias Absinthe.Schema

  @type function_identifier :: {module, any}
  @type function_ref :: {:ref, module, function_identifier}

  # ALL TYPES

  @type_modules [
    Type.Scalar,
    Type.Object,
    Type.Interface,
    Type.Union,
    Type.Enum,
    Type.InputObject,
    Type.List,
    Type.NonNull
  ]

  @typedoc "The types that can be custom-built in a schema"
  @type custom_t ::
          Type.Scalar.t()
          | Type.Object.t()
          | Type.Field.t()
          | Type.Interface.t()
          | Type.Union.t()
          | Type.Enum.t()
          | Type.InputObject.t()

  @typedoc "All the possible types"
  @type t :: custom_t | wrapping_t

  @typedoc "A type identifier"
  @type identifier_t :: atom

  @typedoc "A type reference"
  @type reference_t :: identifier_t | binary | t

  def function(type, key) do
    case Map.fetch!(type, key) do
      {:ref, module, identifier} ->
        module.__absinthe_function__(identifier, key)

      function ->
        function
    end
  end

  @doc false
  # this is just for debugging
  def expand(%module{} = type) do
    module.functions()
    |> Enum.reduce(type, fn
      :middleware, type ->
        type

      attr, type ->
        Map.put(type, attr, Absinthe.Type.function(type, attr))
    end)
  end

  @doc "Lookup a custom metadata field on a type"
  @spec meta(custom_t, atom) :: nil | any
  def meta(%{__private__: store}, key) do
    get_in(store, [:meta, key])
  end

  @doc "Return all custom metadata on a type"
  @spec meta(custom_t) :: map
  def meta(%{__private__: store}) do
    Keyword.get(store, :meta, [])
    |> Enum.into(%{})
  end

  @doc "Determine if a struct matches one of the types"
  @spec type?(any) :: boolean
  def type?(%{__struct__: mod}) when mod in @type_modules, do: true
  def type?(_), do: false

  @doc "Determine whether a field/argument is deprecated"
  @spec deprecated?(Type.Field.t() | Type.Argument.t()) :: boolean
  def deprecated?(%{deprecation: nil}), do: false
  def deprecated?(%{deprecation: _}), do: true

  def equal?(%{name: name}, %{name: name}), do: true
  def equal?(_, _), do: false

  def built_in?(type) do
    type.definition
    |> built_in_module?()
  end

  def built_in_module?(module) do
    module
    |> Module.split()
    |> Enum.take(3)
    |> Module.concat() == Absinthe.Type.BuiltIns
  end

  # INPUT TYPES

  @input_type_modules [Type.Scalar, Type.Enum, Type.InputObject, Type.List, Type.NonNull]

  @typedoc "These types may be used as input types for arguments and directives."
  @type input_t ::
          Type.Scalar.t()
          | Type.Enum.t()
          | Type.InputObject.t()
          | Type.List.t()
          | Type.NonNull.t()

  @doc "Determine if a term is an input type"
  @spec input_type?(any) :: boolean
  def input_type?(term) do
    term
    |> named_type
    |> do_input_type?
  end

  defp do_input_type?(%{__struct__: mod}) when mod in @input_type_modules, do: true
  defp do_input_type?(_), do: false

  # OBJECT TYPE

  @doc "Determine if a term is an object type"
  @spec object_type?(any) :: boolean
  def object_type?(%Type.Object{}), do: true
  def object_type?(_), do: false

  @doc "Resolve a type for a value from an interface (if necessary)"
  @spec resolve_type(t, any) :: t
  def resolve_type(%{resolve_type: resolver}, value), do: resolver.(value)
  def resolve_type(type, _value), do: type

  # TYPE WITH FIELDS

  @doc "Determine if a type has fields"
  @spec fielded?(any) :: boolean
  def fielded?(%{fields: _}), do: true
  def fielded?(_), do: false

  # OUTPUT TYPES

  @output_type_modules [Type.Scalar, Type.Object, Type.Interface, Type.Union, Type.Enum]

  @typedoc "These types may be used as output types as the result of fields."
  @type output_t ::
          Type.Scalar.t() | Type.Object.t() | Type.Interface.t() | Type.Union.t() | Type.Enum.t()

  @doc "Determine if a term is an output type"
  @spec output_type?(any) :: boolean
  def output_type?(term) do
    term
    |> named_type
    |> do_output_type?
  end

  defp do_output_type?(%{__struct__: mod}) when mod in @output_type_modules, do: true
  defp do_output_type?(_), do: false

  # LEAF TYPES

  @leaf_type_modules [Type.Scalar, Type.Enum]

  @typedoc "These types may describe types which may be leaf values."
  @type leaf_t :: Type.Scalar.t() | Type.Enum.t()

  @doc "Determine if a term is a leaf type"
  @spec leaf_type?(any) :: boolean
  def leaf_type?(term) do
    term
    |> named_type
    |> do_leaf_type?
  end

  defp do_leaf_type?(%{__struct__: mod}) when mod in @leaf_type_modules, do: true
  defp do_leaf_type?(_), do: false

  # COMPOSITE TYPES

  @composite_type_modules [Type.Object, Type.Interface, Type.Union]

  @typedoc "These types may describe the parent context of a selection set."
  @type composite_t :: Type.Object.t() | Type.Interface.t() | Type.Union.t()

  @doc "Determine if a term is a composite type"
  @spec composite_type?(any) :: boolean
  def composite_type?(%{__struct__: mod}) when mod in @composite_type_modules, do: true
  def composite_type?(_), do: false

  # ABSTRACT TYPES

  @abstract_type_modules [Type.Interface, Type.Union]

  @typedoc "These types may describe the parent context of a selection set."
  @type abstract_t :: Type.Interface.t() | Type.Union.t()

  @doc "Determine if a term is an abstract type"
  @spec abstract?(any) :: boolean
  def abstract?(%{__struct__: mod}) when mod in @abstract_type_modules, do: true
  def abstract?(_), do: false

  # NULLABLE TYPES

  # @nullable_type_modules [Type.Scalar, Type.Object, Type.Interface, Type.Union, Type.Enum, Type.InputObject, Type.List]

  @typedoc "These types can all accept null as a value."
  @type nullable_t ::
          Type.Scalar.t()
          | Type.Object.t()
          | Type.Interface.t()
          | Type.Union.t()
          | Type.Enum.t()
          | Type.InputObject.t()
          | Type.List.t()

  @doc "Unwrap the underlying nullable type or return unmodified"
  # nullable_t is a subset of t, but broken out for clarity
  @spec nullable(any) :: nullable_t | t
  def nullable(%Type.NonNull{of_type: nullable}), do: nullable
  def nullable(term), do: term

  @doc "Determine if a type is non null"
  @spec non_null?(t) :: boolean
  def non_null?(%Type.NonNull{}), do: true
  def non_null?(_), do: false

  # NAMED TYPES

  @named_type_modules [
    Type.Scalar,
    Type.Object,
    Type.Interface,
    Type.Union,
    Type.Enum,
    Type.InputObject
  ]

  @typedoc "These named types do not include modifiers like Absinthe.Type.List or Absinthe.Type.NonNull."
  @type named_t ::
          Type.Scalar.t()
          | Type.Object.t()
          | Type.Interface.t()
          | Type.Union.t()
          | Type.Enum.t()
          | Type.InputObject.t()

  @doc "Determine the underlying named type, if any"
  @spec named_type(any) :: nil | named_t
  def named_type(%{__struct__: mod, of_type: unmodified}) when mod in [Type.List, Type.NonNull] do
    named_type(unmodified)
  end

  def named_type(%{__struct__: mod} = term) when mod in @named_type_modules, do: term
  def named_type(_), do: nil

  @doc "Determine if a type is named"
  @spec named?(t) :: boolean
  def named?(%{name: _}), do: true
  def named?(_), do: false

  # WRAPPERS

  @wrapping_modules [Type.List, Type.NonNull]

  @typedoc "A type wrapped in a List on NonNull"
  @type wrapping_t :: Type.List.t() | Type.NonNull.t()

  @spec wrapped?(t) :: boolean
  def wrapped?(%{__struct__: mod}) when mod in @wrapping_modules, do: true
  def wrapped?(_), do: false

  @doc "Unwrap a type from a List or NonNull"
  @spec unwrap(custom_t | wrapping_t | map) :: reference_t | map | nil
  def unwrap(%{of_type: t}), do: unwrap(t)
  def unwrap(type), do: type

  @doc "Unwrap a type from NonNull"
  @spec unwrap_non_null(Type.NonNull.t()) :: reference_t
  @spec unwrap_non_null(type) :: type when type: custom_t | Type.List.t()
  def unwrap_non_null(%Type.NonNull{of_type: t}), do: unwrap_non_null(t)
  def unwrap_non_null(type), do: type

  @doc """
  Get the GraphQL name for a (possibly wrapped) type, expanding
  any references if necessary using the provided schema.
  """
  @spec name(reference_t, Schema.t()) :: String.t()
  def name(ref, schema) do
    expanded = expand(ref, schema)
    name(expanded)
  end

  @doc """
  Get the GraphQL name for a (possibly wrapped) type.

  Note: Use `name/2` if the provided type reference needs to
  be expanded to resolve any atom type references.
  """
  @spec name(wrapping_t | t) :: String.t()
  def name(%Type.NonNull{of_type: contents}) do
    name(contents) <> "!"
  end

  def name(%Type.List{of_type: contents}) do
    "[" <> name(contents) <> "]"
  end

  def name(%{name: name}) do
    name
  end

  @doc "Expand any atom type references inside a List or NonNull"
  @spec expand(reference_t, Schema.t()) :: wrapping_t | t
  def expand(ref, schema) when is_atom(ref) or is_binary(ref) do
    schema.__absinthe_lookup__(ref)
  end

  def expand(%{of_type: contents} = ref, schema) do
    %{ref | of_type: expand(contents, schema)}
  end

  def expand(type, _) do
    type
  end

  # INTROSPECTION TYPE

  @spec introspection?(t) :: boolean
  def introspection?(%{name: "__" <> _}) do
    true
  end

  def introspection?(_) do
    false
  end

  # VALUE TYPE

  @spec value_type(t, Schema.t()) :: Type.t()
  def value_type(%Type.Field{} = node, schema) do
    Type.expand(node.type, schema)
  end

  def value_type(type, schema) do
    Type.expand(type, schema)
  end

  # VALID TYPE

  def valid_input?(%Type.NonNull{}, nil) do
    false
  end

  def valid_input?(%Type.NonNull{of_type: internal_type}, value) do
    valid_input?(internal_type, value)
  end

  def valid_input?(_type, nil) do
    true
  end

  def valid_input?(%{parse: parse}, value) do
    case parse.(value) do
      {:ok, _} -> true
      :error -> false
    end
  end

  def valid_input?(_, _) do
    true
  end
end
