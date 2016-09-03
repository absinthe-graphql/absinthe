Code.require_file("test/lib/absinthe/type/fixtures.exs")

ExUnit.configure(exclude: [pending: true, old_errors: true, idl: true])
ExUnit.start()
