if Code.ensure_loaded?(:persistent_term) do
  defmodule Absinthe.Schema.PersistentTerm do
    @moduledoc false

    @behaviour Absinthe.Schema.Provider

    def pipeline(pipeline) do
      Enum.map(pipeline, fn
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
    end

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
    end

    def __absinthe_types__(schema_mod, group) do
      schema_mod
      |> get()
      |> Map.fetch!(:__absinthe_types__)
      |> Map.fetch!(group)
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

    def __absinthe_prototype_schema__(schema_mod) do
      schema_mod
      |> get()
      |> Map.fetch!(:__absinthe_prototype_schema__)
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
  end
end
