defmodule Absinthe.Schema.Compiled do
  @moduledoc false

  @behaviour Absinthe.Schema.Provider

  def pipeline(pipeline) do
    pipeline
  end

  def __absinthe_type__(schema_mod, name) do
    Module.concat([schema_mod, Compiled]).__absinthe_type__(name)
  end

  def __absinthe_directive__(schema_mod, name) do
    Module.concat([schema_mod, Compiled]).__absinthe_directive__(name)
  end

  def __absinthe_types__(schema_mod) do
    Module.concat([schema_mod, Compiled]).__absinthe_types__
  end

  def __absinthe_types__(schema_mod, group) do
    Module.concat([schema_mod, Compiled]).__absinthe_types__(group)
  end

  def __absinthe_directives__(schema_mod) do
    Module.concat([schema_mod, Compiled]).__absinthe_directives__
  end

  def __absinthe_interface_implementors__(schema_mod) do
    Module.concat([schema_mod, Compiled]).__absinthe_interface_implementors__
  end

  def __absinthe_prototype_schema__(schema_mod) do
    Module.concat([schema_mod, Compiled]).__absinthe_prototype_schema__
  end
end
