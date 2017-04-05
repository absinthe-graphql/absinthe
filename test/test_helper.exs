Code.require_file("test/lib/absinthe/type/fixtures.exs")

ExUnit.configure(exclude: [pending: true], timeout: 30_000)
ExUnit.start()
