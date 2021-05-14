# Using with JavaScript

You can interact with an Absinthe GraphQL server via HTTP (thanks to
`absinthe_plug`) and websockets (thanks to `absinthe_phoenix`):

We also have special support for configuring and working with specific
JavaScript frameworks. You can see the guides here:

- [Apollo Client](apollo.md)
- [Relay](relay.md)

## Over HTTP

To integrate a JavaScript application via HTTP, any standard GraphQL
HTTP request (GET/POST) will do.

Here's an example using
[isomorphic-fetch](https://www.npmjs.com/package/isomorphic-fetch):

``` javascript
require('isomorphic-fetch');

fetch('http://localhost:4000/graphql', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ query: '{ posts { title } }' }),
})
  .then(res => res.json())
  .then(res => console.log(res.data));
```

## Over Websockets

See the [@absinthe/socket](https://github.com/absinthe-graphql/absinthe-socket/tree/master/packages/socket) NPM package
for special support for Absinthe's use of Phoenix channels for GraphQL over websockets, including support for
[subscriptions](subscriptions.md).
