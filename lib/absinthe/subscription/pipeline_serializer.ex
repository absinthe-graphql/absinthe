defmodule Absinthe.Subscription.PipelineSerializer do
  @moduledoc """
  Serializer responsible for packing and unpacking pipeline stored in the Elixir registry.

  The purpose of this logic is saving memory by deduplicating repeating options - (ETS
  backed registry stores them flat in the memory).
  """

  @packed_keys [:variables, :context]

  alias Absinthe.{Phase, Pipeline}

  @type options_label :: {:options, non_neg_integer()}

  @type packed_phase_config :: Phase.t() | {Phase.t(), options_label()}

  @type options_map :: %{options_label() => Keyword.t()}

  @type packed_pipeline :: {:packed, [packed_phase_config()], options_map()}

  @spec pack(Pipeline.t() | {module(), atom, list()}) :: packed_pipeline()
  def pack({module, function, args})
      when is_atom(module) and is_atom(function) and is_list(args) do
    {module, function, args}
  end

  def pack(pipeline) do
    {packed_pipeline, reverse_map} =
      pipeline
      |> List.flatten()
      |> Enum.map_reduce(%{}, &maybe_pack_phase/2)

    options_map = Map.new(reverse_map, fn {options, label} -> {label, options} end)

    {:packed, packed_pipeline, options_map}
  end

  @spec unpack(Pipeline.t() | packed_pipeline()) :: Pipeline.t()
  def unpack({:packed, pipeline, pack_map}) do
    Enum.map(pipeline, fn
      {phase, [:pack | index]} ->
        {phase, pack_map |> Map.fetch!(index) |> maybe_unpack_options(pack_map)}

      phase ->
        phase
    end)
  end

  def unpack({module, function, args}) do
    apply(module, function, args)
  end

  def unpack([_ | _] = pipeline) do
    pipeline
  end

  defp maybe_pack_phase({phase, options}, reverse_map) do
    {options, reverse_map} = maybe_pack_options(options, reverse_map)
    {packed, reverse_map} = pack_value(options, reverse_map)
    {{phase, packed}, reverse_map}
  end

  defp maybe_pack_phase(phase, reverse_map) do
    {phase, reverse_map}
  end

  defp maybe_pack_options(options, reverse_map) do
    for key <- @packed_keys, reduce: {options, reverse_map} do
      {options, reverse_map} ->
        value = Keyword.get(options, key, %{})

        if value == %{} do
          {options, reverse_map}
        else
          {packed, reverse_map} = pack_value(value, reverse_map)
          {Keyword.put(options, key, packed), reverse_map}
        end
    end
  end

  defp pack_value(key, reverse_map) do
    case reverse_map do
      %{^key => index} ->
        {[:pack | index], reverse_map}

      %{} ->
        new_index = map_size(reverse_map)
        reverse_map = Map.put(reverse_map, key, new_index)
        {[:pack | new_index], reverse_map}
    end
  end

  defp maybe_unpack_options(options, pack_map) do
    for key <- @packed_keys, reduce: options do
      options ->
        case Keyword.get(options, key) do
          [:pack | index] -> Keyword.put(options, key, Map.fetch!(pack_map, index))
          _ -> options
        end
    end
  end
end
