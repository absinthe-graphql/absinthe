defmodule Absinthe.Validation do
  @moduledoc false

  @validations [
    Absinthe.Validation.PreventCircularFragments
  ]

  # Not all errors result in an `:error` status.
  # :error status indicates that validation has failed in an unrecoverable manner
  # and the document should not be executed at all.
  #
  # Errors can include deprecation warnings and problems on individual fields
  def run(doc) do
    {status, errors} = Enum.reduce(@validations, {:ok, []}, fn module, {status, acc} ->
      case module.validate(doc, {status, acc}) do
        {:error, errors} -> {:error, errors}
        {_, errors} -> {status, errors}
      end
    end)

    {status, errors, doc}
  end

end
