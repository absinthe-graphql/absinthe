defmodule Absinthe.Schema.Experimental do
  defmacro __using__(_opt) do
    quote do
      use Absinthe.Schema.Notation.Experimental
      @after_compile unquote(__MODULE__)

      defdelegate __absinthe_type__(name), to: __MODULE__.Compiled

      def __absinthe_lookup__(name) do
        __absinthe_type__(name)
      end

      @doc false
      def middleware(middleware, _field, _object) do
        middleware
      end

      @doc false
      def context(context) do
        context
      end

      defoverridable(context: 1, middleware: 3)
    end
  end

  def pipeline(opts \\ []) do
    alias Absinthe.Phase

    [
      Phase.Validation.KnownTypeNames,
      Phase.Validation.KnownDirectives,
      {Phase.Schema.Compile, opts}
    ]
  end

  def __after_compile__(env, _) do
    blueprint = env.module.__absinthe_blueprint__
    pipeline = pipeline(module: env.module)

    Absinthe.Pipeline.run(blueprint, pipeline)
    []
  end
end
