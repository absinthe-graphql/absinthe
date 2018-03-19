defmodule Absinthe.Logger do
  @default_log true
  @default_filter_variables ~w(token password)
  @default_pipeline false
  @default_log_mode :multi_line

  @moduledoc """
  Handles logging of Absinthe-specific events.

  ## Variable filtering

  Absinthe can filter out sensitive information like tokens and passwords
  during logging. They are replaced by `"[FILTERED]"`.

  Use the `:filter_variables` configuration setting for this module.
  For example:

      config :absinthe, Absinthe.Logger,
        filter_variables: ["token", "password", "secret"]

  With the configuration above, Absinthe will filter any variable whose name
  includes the terms `token`, `password`, or `secret`. The match is case
  sensitive.

  The default is `#{inspect(@default_filter_variables)}`.

  ## Pipeline display

  Absinthe can optionally display the list of pipeline phases for each processed
  document when logging. To enable this feature, set the `:pipeline`
  configuration option for this module:

      config :absinthe, Absinthe.Logger,
        pipeline: true

  The default is `#{inspect(@default_pipeline)}`.

  ## Disabling

  To disable Absinthe logging, set the `:log` configuration option to `false`:

      config :absinthe,
        log: false

  The default is `#{inspect(@default_log)}`.

  ## Logging all output on a single line

  By default,this will log the requested query in a human-readable format,
  for example:

      [debug] ABSINTHE schema=MyApp.Schema variables=%{"id" => "9"}
      ---
      query ($id: ID!) {
        foo(id: $id) {
          id
          bar
          baz {
            id
            __typename
          }
          ....

  This is useful in many instances, but may not be useful for production
  logging. Consequently, use the following configuration to pull this all onto
  a single line:

      config :absinthe, Absinthe.Logger,
        log_mode: :single_line

  """
  require Logger

  @doc """
  Log a document being processed.
  """
  @spec log_run(
          level :: Logger.level(),
          {doc :: Absinthe.Pipeline.data_t(), schema :: Absinthe.Schema.t(),
           pipeline :: Absinthe.Pipeline.t(), opts :: Keyword.t()}
        ) :: :ok
  def log_run(level, {doc, schema, pipeline, opts}) do
    if Application.get_env(:absinthe, :log, @default_log) do
      Logger.log(level, fn ->
        [
          "ABSINTHE",
          " schema=",
          inspect(schema),
          " variables=",
          variables_body(opts),
          pipeline_section(pipeline),
          "---",
          separator(),
          document(doc),
          separator(),
          "---"
        ]
      end)
    end

    :ok
  end

  @doc false
  @spec document(Absinthe.Pipeline.data_t()) :: iolist
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
    Application.get_env(:absinthe, __MODULE__, [])
    |> Keyword.get(:log_mode, @default_log_mode)
    |> case do
      :single_line ->
        String.trim(document)
        |> String.replace("\n", "")

      _multi_line ->
        String.trim(document)
    end
  end

  def document(other) do
    inspect(other)
  end

  @doc false
  @spec filter_variables(map) :: map
  @spec filter_variables(map, [String.t()]) :: map
  def filter_variables(data, filter_variables \\ variables_to_filter())

  def filter_variables(%{__struct__: mod} = struct, _filter_variables) when is_atom(mod) do
    struct
  end

  def filter_variables(%{} = map, filter_variables) do
    Enum.into(map, %{}, fn {k, v} ->
      if is_binary(k) and String.contains?(k, filter_variables) do
        {k, "[FILTERED]"}
      else
        {k, filter_variables(v, filter_variables)}
      end
    end)
  end

  def filter_variables([_ | _] = list, filter_variables) do
    Enum.map(list, &filter_variables(&1, filter_variables))
  end

  def filter_variables(other, _filter_variables), do: other

  @spec variables_to_filter() :: [String.t()]
  defp variables_to_filter do
    Application.get_env(:absinthe, __MODULE__, [])
    |> Keyword.get(:filter_variables, @default_filter_variables)
  end

  @spec variables_body(Keyword.t()) :: String.t()
  defp variables_body(opts) do
    Keyword.get(opts, :variables, %{})
    |> filter_variables()
    |> inspect()
  end

  @spec pipeline_section(Absinthe.Pipeline.t()) :: iolist
  defp pipeline_section(pipeline) do
    Application.get_env(:absinthe, __MODULE__, [])
    |> Keyword.get(:pipeline, @default_pipeline)
    |> case do
      true ->
        do_pipeline_section(pipeline)

      false ->
        separator()
    end
  end

  @spec do_pipeline_section(Absinthe.Pipeline.t()) :: iolist
  defp do_pipeline_section(pipeline) do
    [
      " pipeline=",
      pipeline
      |> Enum.map(fn
        {mod, _} -> mod
        mod -> mod
      end)
      |> inspect,
      separator()
    ]
  end

  @spec separator() :: iolist
  defp separator do
    Application.get_env(:absinthe, __MODULE__, [])
    |> Keyword.get(:log_mode, @default_log_mode)
    |> case do
      :single_line ->
        " "

      _multi_line ->
        ?\n
    end
  end
end
