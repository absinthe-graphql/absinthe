# Complex Arguments

In preparation for supporting comments on our blog, let's create users. We're building
a modern mobile first blog of course, and thus want to support either a phone number
or an email as the contact method for a user.

We want to support the following mutations.

```graphql
mutation CreateEmailUser {
  user(contact: {type: EMAIL, value: "foo@bar.com"}, password: "hunter2")
}
```

```graphql
mutation CreatePhoneUser {
  user(contact: {type: PHONE, value: "867-5309"}, password: "hunter2")
}
```

To do this we need the ability to create nested arguments. GraphQL has InputObjects
for this purpose. InputObjects are key value pairs just like regular Objects, but
designed for input (you can't do circular references with them for example).

Another notion we'll look at here is an Enum type. We only want to support contact
types `"email"` and `"phone"` at the moment, and GraphQL gives us the ability to
specify this in our schema.

Let's start with our `:contact_type` Enum. In `web/schema/types.ex`:

```graphql
enum :contact_type do
  value :phone
  value :email
end
```

Easy! Now if a user tries to send some other kind of contact type they'll get a
nice error without any extra effort on your part. Enum types are not a substitute
for modeling layer validations however, be sure to still enforce things like this
on that layer too.

Now for our contact input object.

In `web/schema/types.ex`:

```graphql
input_object :contact_input do
  field :type, non_null(:contact_type)
  field :value, non_null(:string)
end
```

Note that we name this type `:contact_input`. We may also want a regular `:contact`
object and types share a global namespace. In general it often makes sense to
suffix your input object type names with `_input`

Finally our schema, in `web/schema.ex`:

```elixir
mutation do

  #... other mutations

  field :user, :user do
    arg :contact, non_null(:contact_input)
    arg :password, :string

    resolve &Blog.PostResolver.create/2
  end

end
```

Suppose in our database that we store contact information in a different database
table. Our resolver would be used to create both rows in this case.

There does not need to be a one to one correspondence between how data is structured
in your underlying data store and how things are presented by your GraphQL api.

Our resolver, `web/resolvers/post_resolver.ex` might look something like this:

```elixir
def create(params, _info) do
  {contact_params, user_params} = Map.pop(params, :contact)

  with {:ok, contact} <- create_contact(contact_params),
  {:ok, user} <- create_user(user_params, contact) do
    {:ok, %{user | contact: contact}}
  end
end

defp create_contact(params) do
  params
  |> Contact.changeset
  |> Blog.Repo.insert
end

defp create_user(params, contact) do
  params
  |> Map.put(:contact_id, contact.id)
  |> User.changeset
  |> Blog.Repo.insert
end
```

Now let's [wrap things up](conclusion.html).
