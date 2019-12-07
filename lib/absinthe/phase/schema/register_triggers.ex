defmodule Absinthe.Phase.Schema.RegisterTriggers do
  @moduledoc false

  use Absinthe.Phase

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
        mutation_object
        |> register_triggers(subscription_object.fields)
        |> setup_middleware
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
    update_fields(mutation_object, fn mut_field ->
      triggers =
        for sub_field <- sub_fields,
            sub_triggers = Absinthe.Type.function(sub_field, :triggers),
            is_map(sub_triggers),
            Map.has_key?(sub_triggers, mut_field.identifier),
            do: sub_field.identifier

      %{mut_field | triggers: triggers}
    end)
  end

  defp setup_middleware(mutation_object) do
    update_fields(mutation_object, fn field ->
      Map.update!(field, :middleware, &Absinthe.Subscription.add_middleware/1)
    end)
  end

  defp update_fields(mutation_object, fun) do
    Map.update!(mutation_object, :fields, fn fields ->
      Enum.map(fields, fun)
    end)
  end
end
