Code.require_file("test/lib/absinthe/type/fixtures.exs")

Absinthe.Test.prime(Things)

ExUnit.configure(exclude: [pending: true], timeout: 5_000)
ExUnit.start()
