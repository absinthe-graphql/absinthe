defmodule BadInterfaceSchema do
  use Absinthe.Schema

  query do
    field :foo, :foo
    field :quux, :quux
    field :span, :spam
  end

  object :foo do
    field :not_name, :string
    interface :named
    is_type_of fn
      _ ->
        true
    end
  end

  object :quux do
    field :not_name, :string
    interface :foo
    is_type_of fn
      _ ->
        true
    end
  end

   object :spam do
     field :name, :string
     interface :named
   end

   interface :named do
     field :name, :string
   end

end
