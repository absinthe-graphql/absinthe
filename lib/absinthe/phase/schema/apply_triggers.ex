defmodule Absinthe.Phase.Schema.RegisterTriggers do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema

  def run(blueprint, _opts) do
    %{schema_definitions: [schema]} = blueprint

    subscription_object =
      Enum.find(schema.type_definitions, fn type ->
        type.identifier == :subscription
      end)

    mutation_object =
      Enum.find(schema.type_definitions, fn type ->
        type.identifier == :mutation
      end)

    mutation_object =
      if subscription_object && mutation_object do
        register_triggers(mutation_object, subscription_object.fields)
      else
        # TODO: return errors if there isn't a mutation field that is on the
        # triggers list
        mutation_object
      end

    schema =
      Map.update!(schema, :type_definitions, fn definitions ->
        Enum.map(definitions, fn
          %{identifier: :subscription} -> subscription_object
          %{identifier: :mutation} -> mutation_object
          type -> type
        end)
      end)

    {:ok, %{blueprint | schema_definitions: [schema]}}
  end

  defp register_triggers(mutation_object, sub_fields) do
    Map.update!(mutation_object, :fields, fn mut_fields ->
      for mut_field <- mut_fields do
        triggers =
          for sub_field <- sub_fields,
              sub_triggers = Absinthe.Type.function(sub_field, :triggers),
              Map.has_key?(sub_triggers, mut_field.identifier),
              do: sub_field.identifier

        %{mut_field | triggers: triggers}
      end
    end)
  end
end
