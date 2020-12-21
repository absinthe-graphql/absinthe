defmodule Absinthe.Fixtures.ImportTypes do
  defmodule AccountTypes do
    use Absinthe.Schema.Notation

    object :customer do
      field :id, non_null(:id)
      field :name, :string
      field :mailing_address, :mailing_address
      field :contact_methods, list_of(:contact_method)
    end

    object :employee do
      field :id, non_null(:id)
      field :name, :string
      field :avatar, :avatar
      field :weekly_schedules, list_of(:weekly_schedule)
    end
  end

  defmodule OrderTypes do
    use Absinthe.Schema.Notation

    object :order do
      field :id, non_null(:id)
      field :customer, non_null(:customer)
      field :receipt, non_null(:receipt)
    end
  end

  defmodule ReceiptTypes do
    use Absinthe.Schema.Notation

    object :receipt do
      field :id, non_null(:id)
      field :code, non_null(:string)
    end
  end

  defmodule ScheduleTypes do
    use Absinthe.Schema.Notation

    object :weekly_schedule do
      field :id, non_null(:id)
      field :employee, non_null(:employee)
    end
  end

  defmodule ProfileTypes do
    use Absinthe.Schema.Notation

    object :mailing_address do
      field :street, non_null(list_of(:string))
      field :city, non_null(:string)
      field :state, non_null(:string)
      field :postal_code, non_null(:string)
    end
  end

  defmodule AuthTypes do
    use Absinthe.Schema.Notation

    object :contact_method do
      field :kind, non_null(:contact_kind)
      field :value, non_null(:string)
    end

    enum :contact_kind, values: [:email, :phone]
  end

  defmodule Shared.AvatarTypes do
    use Absinthe.Schema.Notation

    object :avatar do
      field :height, non_null(:integer)
      field :width, non_null(:integer)
      field :url, non_null(:string)
    end
  end

  defmodule Schema.Types.Flag do
    use Absinthe.Schema.Notation

    object :flag do
      field :name, non_null(:string)
      field :key, non_null(:string)
      field :enabled, non_null(:boolean)
    end
  end

  defmodule Schema.Types.Enum.ValueType do
    use Absinthe.Schema.Notation

    enum :value_type_enum, values: [:number, :boolean, :string]
  end

  defmodule Schema do
    use Absinthe.Schema
    use Absinthe.Fixture

    import_types Absinthe.Fixtures.ImportTypes.{AccountTypes, OrderTypes}
    import_types Absinthe.Fixtures.ImportTypes.ReceiptTypes

    alias Absinthe.Fixtures.ImportTypes
    import_types ImportTypes.ScheduleTypes
    import_types ImportTypes.{ProfileTypes, AuthTypes, Shared.AvatarTypes}

    import_types __MODULE__.Types.{Flag, Enum.ValueType}

    query do
      field :orders, list_of(:order)
      field :employees, list_of(:employee)
      field :customers, list_of(:customer)
    end
  end

  defmodule SelfContainedSchema do
    use Absinthe.Schema
    use Absinthe.Fixture

    defmodule PaymentTypes do
      use Absinthe.Schema.Notation

      object :credit_card do
        field :number, non_null(:string)
        field :type, non_null(:credit_card_type)
        field :expiration_month, non_null(:integer)
        field :expiration_year, non_null(:integer)
        field :cvv, non_null(:string)
      end
    end

    defmodule CardTypes do
      use Absinthe.Schema.Notation

      enum :credit_card_type, values: [:visa, :mastercard, :amex]
    end

    defmodule Errors.DeclineReasons do
      use Absinthe.Schema.Notation

      enum :decline_reasons, values: [:insufficient_funds, :invalid_card]
    end

    defmodule Types.Category do
      use Absinthe.Schema.Notation

      object :category do
        field :name, non_null(:string)
        field :slug, non_null(:string)
        field :description, :string
      end
    end

    defmodule Types.Enums.Role do
      use Absinthe.Schema.Notation

      enum :role_enum, values: [:admin, :client]
    end

    import_types __MODULE__.Errors.DeclineReasons
    import_types __MODULE__.{PaymentTypes, CardTypes}
    import_types __MODULE__.Types.{Category, Enums.Role}

    query do
      field :credit_cards, list_of(:credit_card)
    end
  end

  defmodule SchemaWithFunctionEvaluationImports do
    use Absinthe.Schema.Notation
    @module_attribute "goodbye"

    defmodule NestedModule do
      def nested_function(arg1) do
        arg1
      end
    end

    def test_function(arg1) do
      arg1
    end

    input_object :example_input_object do
      field :normal_string, :string, description: "string"
      field :local_function_call, :string, description: test_function("red")

      field :function_call_using_absolute_path_to_current_module, :string,
        description:
          Absinthe.Fixtures.ImportTypes.SchemaWithFunctionEvaluationImports.test_function("red")

      field :standard_library_function, :string, description: String.replace("red", "e", "a")

      field :function_in_nested_module, :string,
        description: NestedModule.nested_function("hello")

      field :external_module_function_call, :string,
        description: Absinthe.Fixtures.FunctionEvaluationHelpers.external_function("hello")

      field :module_attribute_string_concat, :string, description: "hello " <> @module_attribute
      field :interpolation_of_module_attribute, :string, description: "hello #{@module_attribute}"
    end
  end

  defmodule SchemaWithFunctionEvaluation do
    use Absinthe.Schema

    import_types(SchemaWithFunctionEvaluationImports)

    query do
    end
  end
end
