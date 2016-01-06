defmodule ContactSchema do
  use Absinthe.Schema
  alias Absinthe.Type

  @bruce %{name: "Bruce", age: 35}

  def query do
    %Type.Object{
      fields: fields(
        person: [
          type: :person,
          resolve: fn
            _, _ ->
              {:ok, @bruce}
          end
        ],
        contact: [
          type: :contact,
          resolve: fn
            _, _ ->
              {:ok, %{entity: @bruce}}
          end
        ],
      )
    }
  end

  @absinthe :type
  def named_entity do
    %Type.Interface{
      fields: fields(
        name: [type: :string]
      ),
      resolve_type: fn
        %{age: _}, _ -> :person
        %{employee_count: _}, _ -> :business
      end
    }
  end

  @absinthe :type
  def person do
    %Type.Object{
      description: "A person",
      fields: fields(
        name: [type: :string],
        age: [type: :integer],
        address: deprecate([type: :string], reason: "change of privacy policy")
      ),
      interfaces: [:named_entity]
    }
  end

  @absinthe :type
  def business do
    %Type.Object{
      fields: fields(
        name: [type: :string],
        employee_count: [type: :integer]
      ),
      interfaces: [:named_entity]
    }
  end

  @absinthe :type
  def contact do
    %Type.Object{
      fields: fields(
        entity: [type: :named_entity],
        phone_number: [type: :string],
        address: [type: :string]
      )
    }
  end

end
