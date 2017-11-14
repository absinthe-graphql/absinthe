# - because of Code.load_file in test\support\support_schemas.ex (Code.require_file blocks tests)
# - possible alternative would be to run tests with async:false and purge modules after their loading
Code.compiler_options(ignore_module_conflict: true)

Code.require_file("test/lib/absinthe/type/fixtures.exs")

ExUnit.configure(exclude: [pending: true], timeout: 30_000)
ExUnit.start()
