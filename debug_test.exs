#!/usr/bin/env elixir

# Simple script to debug directive processing

defmodule DebugSchema do
  use Absinthe.Schema
  
  query do
    field :test, :string do
      resolve fn _, _ -> {:ok, "test"} end
    end
  end
end

# Test query with defer directive
query = """
{
  test
  ... @defer(label: "test") {
    test
  }
}
"""

IO.puts("Testing defer directive processing...")

# Skip standard pipeline test - it crashes on defer flags
# This is expected behavior - the standard pipeline can't handle defer flags
IO.puts("\n=== Standard Pipeline ===")
IO.puts("Skipping standard pipeline - defer flags require streaming resolution")

# Test with incremental pipeline
IO.puts("\n=== Incremental Pipeline ===")
pipeline_modifier = fn pipeline, _options ->
  IO.puts("Pipeline before modification:")
  IO.inspect(pipeline |> Enum.map(fn 
    {phase, _opts} -> phase
    phase when is_atom(phase) -> phase
    phase -> inspect(phase)
  end), label: "Pipeline phases")
  
  modified = Absinthe.Pipeline.Incremental.enable(pipeline, 
    enabled: true,
    enable_defer: true,
    enable_stream: true
  )
  
  IO.puts("Pipeline after modification:")
  IO.inspect(modified |> Enum.map(fn 
    {phase, _opts} -> phase
    phase when is_atom(phase) -> phase
    phase -> inspect(phase)
  end), label: "Modified pipeline phases")
  
  modified
end

result2 = Absinthe.run(query, DebugSchema, pipeline_modifier: pipeline_modifier)
IO.inspect(result2, label: "Incremental result")

IO.puts("\nDone!")