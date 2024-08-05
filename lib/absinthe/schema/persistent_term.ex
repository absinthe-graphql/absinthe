if Code.ensure_loaded?(:persistent_term) do
  defmodule Absinthe.Schema.PersistentTerm do
    @moduledoc """
    Experimental: Persistent Term based Schema Backend

    By default, Absinthe schemas are stored in a generated module. If your schema
    is called `MyAppWeb.Schema`, Absinthe creates a `MyAppWeb.Schema.Compiled`
    module containing the structs and other data that Absinthe needs at runtime
    to execute GraphQL operations against that schema.

    OTP introduced the `:persistent_term` module to provide many of the same
    performance benefits of using compiled modules, without the downsides associated
    with manipulating complex structures at compile time.

    This module is an experimental effort at using the `:persistent_term` module
    as an Absinthe schema backend. This module has been tested against against
    the entire Absinthe test suite and shown to perform perhaps even better
    than the compiled module.

    To use:

    In your schema module:
    ```
    use Absinthe.Schema
    @schema_provider Absinthe.Schema.PersistentTerm
    ```

    In your application's supervision tree, prior to anywhere where you'd use
    the schema:
    ```
    {Absinthe.Schema, MyAppWeb.Schema}
    ```

    where MyAppWeb.Schema is the name of your schema.
    """

    @behaviour Absinthe.Schema.Provider

    def pipeline(pipeline) do
      Enum.map(pipeline, fn
        Absinthe.Phase.Schema.InlineFunctions ->
          {Absinthe.Phase.Schema.InlineFunctions, inline_always: true}

        {Absinthe.Phase.Schema.Compile, options} ->
          {Absinthe.Phase.Schema.PopulatePersistentTerm, options}

        phase ->
          phase
      end)
    end

    def __absinthe_type__(schema_mod, name) do
      schema_mod
      |> get()
      |> Map.fetch!(:__absinthe_type__)
      |> Map.get(name)
      |> __maybe_absinthe_type_from_prototype(name, schema_mod)
    end

    defp __maybe_absinthe_type_from_prototype(nil, name, schema_mod) do
      prototype_schema_mod = schema_mod.__absinthe_prototype_schema__()

      if prototype_schema_mod == Absinthe.Schema.Prototype do
        nil
      else
        prototype_schema_mod.__absinthe_type__(name)
      end
    end

    defp __maybe_absinthe_type_from_prototype(value, _, _), do: value

    def __absinthe_directive__(schema_mod, name) do
      schema_mod
      |> get()
      |> Map.fetch!(:__absinthe_directive__)
      |> Map.get(name)
    end

    def __absinthe_types__(schema_mod) do
      schema_mod
      |> get()
      |> Map.fetch!(:__absinthe_types__)
      |> Map.fetch!(:referenced)
      |> __maybe_merge_types_from_prototype(schema_mod, :referenced)
    end

    def __absinthe_types__(schema_mod, group) do
      schema_mod
      |> get()
      |> Map.fetch!(:__absinthe_types__)
      |> Map.fetch!(group)
      |> __maybe_merge_types_from_prototype(schema_mod, group)
    end

    defp __maybe_merge_types_from_prototype(types, schema_mod, group) do
      prototype_schema_mod = schema_mod.__absinthe_prototype_schema__()

      if prototype_schema_mod == Absinthe.Schema.Prototype do
        types
      else
        Map.merge(types, prototype_schema_mod.__absinthe_types__(group))
      end
    end

    def __absinthe_directives__(schema_mod) do
      schema_mod
      |> get()
      |> Map.fetch!(:__absinthe_directives__)
    end

    def __absinthe_interface_implementors__(schema_mod) do
      schema_mod
      |> get()
      |> Map.fetch!(:__absinthe_interface_implementors__)
    end

    def __absinthe_schema_declaration__(schema_mod) do
      schema_mod
      |> get()
      |> Map.fetch!(:__absinthe_schema_declaration__)
    end

    @dialyzer {:nowarn_function, [get: 1]}
    defp get(schema) do
      :persistent_term.get({__MODULE__, schema})
    end
  end
else
  defmodule Absinthe.Schema.PersistentTerm do
    @moduledoc false

    @error "Can't be used without OTP >= 21.2"

    def pipeline(_), do: raise(@error)

    def __absinthe_type__(_, _), do: raise(@error)
    def __absinthe_directive__(_, _), do: raise(@error)
    def __absinthe_types__(_), do: raise(@error)
    def __absinthe_types__(_, _), do: raise(@error)
    def __absinthe_directives__(_), do: raise(@error)
    def __absinthe_interface_implementors__(_), do: raise(@error)
    def __absinthe_prototype_schema__(), do: raise(@error)
    def __absinthe_schema_declaration__(_), do: raise(@error)
  end
end
