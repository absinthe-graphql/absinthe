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

  defmodule Schema do
    use Absinthe.Schema

    import_types Absinthe.Fixtures.ImportTypes.{AccountTypes, OrderTypes}
    import_types Absinthe.Fixtures.ImportTypes.ReceiptTypes

    alias Absinthe.Fixtures.ImportTypes
    import_types ImportTypes.ScheduleTypes
    import_types ImportTypes.{ProfileTypes, AuthTypes, Shared.AvatarTypes}

    query do
      field :orders, list_of(:order)
      field :employees, list_of(:employee)
      field :customers, list_of(:customer)
    end
  end
end
