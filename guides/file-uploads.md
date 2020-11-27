# File Uploads

Absinthe provides a unique pattern to support file uploads in conjunction with normal GraphQL field arguments as part of the [absinthe_plug](https://hex.pm/packages/absinthe_plug) package.

## Example

The following schema includes a mutation field that accepts multiple uploaded files as arguments (`:users` and `:metadata`):

```elixir
defmodule MyAppWeb.Schema do
  use Absinthe.Schema

  # Important: Needed to use the `:upload` type
  import_types Absinthe.Plug.Types

  mutation do
    field :upload_file, :string do
      arg :users, non_null(:upload)
      arg :metadata, :upload

      resolve fn args, _ ->
        args.users # this is a `%Plug.Upload{}` struct.

        {:ok, "success"}
      end
    end
  end
end
```

To send a mutation that includes a file upload, you need to
use the `multipart/form-data` content type. For example, using `cURL`:

```shell
$ curl -X POST \
-F query="mutation { uploadFile(users: \"users_csv\", metadata: \"metadata_json\")}" \
-F users_csv=@users.csv \
-F metadata_json=@metadata.json \
localhost:4000/graphql
```

Note how there is a correspondence between the value of the `:users` argument
and the `-F` option indicating the associated file.

By treating uploads as regular arguments we get all the usual GraphQL argument
benefits (such as validation and documentation)---which we wouldn't get if
we were merely putting them in the context as in other implementations.

## Integration with Client-side GraphQL Frameworks

* Apollo: [apollo-absinthe-upload-link](https://www.npmjs.com/package/apollo-absinthe-upload-link)
* Apollo (v1): [apollo-absinthe-upload-client](https://www.npmjs.com/package/apollo-absinthe-upload-client) (Note: does not support Relay Native as of v1.0.1)
* Relay: _(None known. Please submit a pull request updating this information.)_
