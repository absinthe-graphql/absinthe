defmodule Absinthe.Case do
  defmacro __using__(opts) do
    {ordered, opts} = Keyword.pop(opts, :ordered)
    {importRun, opts} = Keyword.pop(opts, :import_run, true)
    async = Keyword.get(opts, :async)

    if async and is_boolean(ordered) do
      IO.puts "\nWARNING: Module #{__CALLER__.module} has set option :ordered => it shouldn't be run with async:true"
    end 
    
    quote do
      use ExUnit.Case, unquote(opts)
      import ExUnit.Case, except: [describe: 2]
      import ExSpec
      unquote do
        if importRun do
          quote do
            import Absinthe.Case.Run
          end
        end
      end

      unquote do
        unless is_nil(ordered) do
          quote do
            setup_all do
              ordered = Application.get_env(:absinthe, :ordered)
              Application.put_env(:absinthe, :ordered, unquote(ordered))
              on_exit(nil, fn ->
                Application.put_env(:absinthe, :ordered, ordered)
              end)
              :ok
            end
          end
        end
      end

      Module.put_attribute(__MODULE__, :ex_spec_contexts, [])
    end
  end
end
