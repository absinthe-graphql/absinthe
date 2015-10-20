defmodule ExGraphQL.Type do

  # ALL TYPES

  @type_modules [__MODULE__.Scalar, __MODULE__.Object, __MODULE__.Interface, __MODULE__.Union, __MODULE__.InputObject, __MODULE__.List, __MODULE__.NonNull]

  @doc "These are all of the possible kinds of types."
  @type t :: __MODULE__.Scalar.t | __MODULE__.Object.t | __MODULE__.Interface.t | __MODULE__.Union.t | __MODULE__.InputObject.t | __MODULE__.List.t | __MODULE__.NonNull.t

  @doc "Determine if a struct matches one of the types"
  @spec type?(any) :: boolean
  def type?(%{__struct__: mod}) when mod in @type_modules, do: true
  def type?(_), do: false

  # INPUT TYPES

  @input_type_modules [__MODULE__.Scalar, __MODULE__.Enum, __MODULE__.InputObject, __MODULE__.List, __MODULE__.NonNull]

  @doc "These types may be used as input types for arguments and directives."
  @type input_t :: __MODULE__.Scalar.t | __MODULE__.Enum.t | __MODULE__.InputObject.t | __MODULE__.List.t | __MODULE__.NonNull.t

  @doc "Determine if a term is an input type"
  @spec input_type?(any) :: boolean
  def input_type?(term) do
    term
    |> named_type
    |> do_input_type?
  end

  defp do_input_type?(%{__struct__: mod}) when mod in @input_type_modules, do: true
  defp do_input_type?(_), do: false

  # OUTPUT TYPES

  @output_type_modules [__MODULE__.Scalar, __MODULE__.Object, __MODULE__.Interface, __MODULE__.Union, __MODULE__.Enum]

  @doc "These types may be used as output types as the result of fields."
  @type output_t :: __MODULE__.Scalar.t | __MODULE__.Object.t | __MODULE__.Interface.t | __MODULE__.Union.t | __MODULE__.Enum.t

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

  @leaf_type_modules [__MODULE__.Scalar, __MODULE__.Enum]

  @doc "These types may describe types which may be leaf values."
  @type leaf_t :: __MODULE__.Scalar.t | __MODULE__.Enum.t

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

  @composite_type_modules [__MODULE__.Object, __MODULE__.Interface, __MODULE__.Union]

  @doc "These types may describe the parent context of a selection set."
  @type composite_t :: __MODULE__.Object.t | __MODULE__.Interface.t | __MODULE__.Union.t

  @doc "Determine if a term is a composite type"
  @spec composite_type?(any) :: boolean
  def composite_type?(%{__struct__: mod}) when mod in @composite_type_modules, do: true
  def composite_type?(_), do: false

  # ABSTRACT TYPES

  @abstract_type_modules [__MODULE__.Interface, __MODULE__.Union]

  @doc "These types may describe the parent context of a selection set."
  @type abstract_t :: __MODULE__.Interface.t | __MODULE__.Union.t

  @doc "Determine if a term is an abstract type"
  @spec abstract_type?(any) :: boolean
  def abstract_type?(%{__struct__: mod}) when mod in @abstract_type_modules, do: true
  def abstract_type?(_), do: false

  # NULLABLE TYPES

  @nullable_type_modules [__MODULE__.Scalar, __MODULE__.Object, __MODULE__.Interface, __MODULE__.Union, __MODULE__.Enum, __MODULE__.InputObject, __MODULE__.List]

  @doc "These types can all accept null as a value."
  @type nullable_t :: __MODULE__.Scalar.t | __MODULE__.Object.t | __MODULE__.Interface.t | __MODULE__.Union.t | __MODULE__.Enum.t | __MODULE__.InputObject.t | __MODULE__.List.t

  @doc "Unwrap the underlying nullable type or return unmodified"
  @spec nullable(any) :: nullable_t | t # nullable_t is a subset of t, but broken out for clarity
  def nullable(%{__struct__: __MODULE__.NonNull, of_type: nullable}), do: nullable
  def nullable(term), do: term

  # NAMED TYPES

  @named_type_modules [__MODULE__.Scalar, __MODULE__.Object, __MODULE__.Interface, __MODULE__.Union, __MODULE__.Enum, __MODULE__.InputObject]

  @doc "These named types do not include modifiers like ExGraphQL.Type.List or ExGraphQL.Type.NonNull."
  @type named_t :: __MODULE__.Scalar.t | __MODULE__.Object.t | __MODULE__.Interface.t | __MODULE__.Union.t | __MODULE__.Enum.t | __MODULE__.InputObject.t

  @doc "Determine the underlying named type, if any"
  @spec named_type(any) :: nil | named_t
  def named_type(%{__struct__: mod, of_type: unmodified}) when mod in [__MODULE__.List, __MODULE__.NonNull] do
    named_type(unmodified)
  end
  def named_type(%{__struct__: mod} = term) when mod in @named_type_modules, do: term
  def named_type(_), do: nil

end
