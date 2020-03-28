defmodule Absinthe.Schema.PersistentTerm do
  @moduledoc false

  def pipeline(pipeline) do
    Enum.map(pipeline, fn
      {Absinthe.Phase.Schema.Compile, options} ->
        {Absinthe.Phase.Schema.PopulatePersistentTerm, options}

      phase ->
        phase
    end)
  end

  def __absinthe_type__(schema_mod, name) do
    get({__MODULE__, schema_mod, :__absinthe_type__, name})
  end

  def __absinthe_directive__(schema_mod, name) do
    get({__MODULE__, schema_mod, :__absinthe_directive__, name})
  end

  def __absinthe_types__(schema_mod) do
    get({__MODULE__, schema_mod, :__absinthe_types__})
  end

  def __absinthe_types__(schema_mod, group) do
    get({__MODULE__, schema_mod, :__absinthe_types__, group})
  end

  def __absinthe_directives__(schema_mod) do
    get({__MODULE__, schema_mod, :__absinthe_directives__})
  end

  def __absinthe_interface_implementors__(schema_mod) do
    get({__MODULE__, schema_mod, :__absinthe_interface_implementors__})
  end

  def __absinthe_prototype_schema__(schema_mod) do
    get({__MODULE__, schema_mod, :__absinthe_prototype_schema__})
  end

  defp get(key, fallback \\ nil) do
    :persistent_term.get(key)
    # rescue
    #   _ ->
    #     fallback
  end
end
