defmodule Absinthe.Logger do
  @moduledoc """
  Handles logging of various instrumentation events.

  ## Variable filtering

  Absinthe can filter out sensitive information like tokens and passwords
  during logging. Variables can be filtered via the `:filter_variables`
  configuration setting for this module. For example:

      config :absinthe, Absinthe.Logger,
        filter_variables: ["token", "password", "secret"]

  With the configuration above, Absinthe will filter any variable whose name
  includes the terms `token`, `password`, or `secret`. The match is case
  sensitive.

  The default is `["token", "password"]`.

  ## Pipeline display

  Absinthe can optionally display the list of pipeline phases for each processed
  document when logging. To enable this feature, set the `:pipeline`
  configuration option for this module:

      config :absinthe, Absinthe.Logger,
        pipeline: true

  The default is equivalent to `false`.

  ## Disabling

  To display Absinthe logging, set the `:log` configuration option to `false`:

      config :absinthe,
        log: false

  The default is `true`.

  """
  require Logger

  @doc """
  Log a document being processed.
  """
  @spec log_run(level :: Logger.level, {doc :: Absinthe.Pipeline.data_t, schema :: Absinthe.Schema.t, pipeline :: Absinthe.Pipeline.t, opts :: Keyword.t}) :: :ok
  def log_run(level, {doc, schema, pipeline, opts}) do
    if Application.get_env(:absinthe, :log, true) do
      Logger.log level, fn ->
        [
          "ABSINTHE",
          " schema=", inspect(schema),
          " variables=", variables_body(opts),
          pipeline_section(pipeline),
          "---", ?\n, document(doc), ?\n, "---"
        ]
      end
    end
    :ok
  end

  @doc false
  @spec document(Absinthe.Pipeline.data_t) :: iolist
  def document(value) when value in ["", nil] do
    "[EMPTY]"
  end
  def document(%Absinthe.Blueprint{name: nil}) do
    "[COMPILED]"
  end
  def document(%Absinthe.Blueprint{name: name}) do
    "[COMPILED#<#{name}>]"
  end
  def document(%Absinthe.Language.Source{body: body}) do
    document(body)
  end
  def document(document) when is_binary(document) do
    String.trim(document)
  end
  def document(other) do
    inspect(other)
  end

  @default_filtering ~w(token password)

  @spec variables_to_filter() :: [String.t]
  defp variables_to_filter do
    Application.get_env(:absinthe, __MODULE__, [])
    |> Keyword.get(:filter_variables, @default_filtering)
  end

  @spec filter_variables(map) :: map
  def filter_variables(data, filter_variables \\ variables_to_filter())
  def filter_variables(%{__struct__: mod} = struct, _filter_variables) when is_atom(mod) do
    struct
  end
  def filter_variables(%{} = map, filter_variables) do
    Enum.into map, %{}, fn {k, v} ->
      if is_binary(k) and String.contains?(k, filter_variables) do
        {k, "[FILTERED]"}
      else
        {k, filter_variables(v, filter_variables)}
      end
    end
  end
  def filter_variables([_|_] = list, filter_variables) do
    Enum.map(list, &filter_variables(&1, filter_variables))
  end
  def filter_variables(other, _filter_variables), do: other

  defp variables_body(opts) do
    Keyword.get(opts, :variables, %{})
    |> filter_variables()
    |> inspect()
  end

  @spec pipeline_section(Absinthe.Pipeline.t) :: iolist
  defp pipeline_section(pipeline) do
    case Application.get_env(:absinthe, __MODULE__, [])[:pipeline] do
      true ->
        do_pipeline_section(pipeline)
      _ ->
        ?\n
    end
  end

  def do_pipeline_section(pipeline) do
    [
      " pipeline=",
      pipeline
      |> Enum.map(fn
        {mod, _} -> mod
        mod -> mod
      end)
      |> inspect,
      ?\n
    ]
  end


end