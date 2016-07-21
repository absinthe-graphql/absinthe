defmodule Support.Harness.Validation.Schema do
  use Absinthe.Schema

  interface :being do
    field :name, :string do
      arg :surname, :boolean
    end
  end

  interface :pet do
    field :name, :string do
      arg :surname, :boolean
    end
  end

  interface :canine do
    field :name, :string do
      arg :surname, :boolean
    end
  end

  enum :dog_command do
    value :sit, as: 0
    value :heel, as: 1
    value :down, as: 2
  end

  # ...

end
