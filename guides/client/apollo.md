# Using with Apollo Client

An Apollo client manages its connection to the GraphQL server using [links](https://www.apollographql.com/docs/link/) -- which are essentially middleware that tell Apollo how to resolve each query. You can configure Apollo to connect to your Absinthe server via HTTP, websockets, or both.

## Using an HTTP link

Using Apollo with an HTTP link does not require any Absinthe-specific configuration. You can create an HTTP link pointed at your Absinthe server as follows:

```javascript
import { ApolloClient, InMemoryCache, createHttpLink } from "@apollo/client";

// Create an HTTP link to the Absinthe server.
const link = createHttpLink({
  uri: "http://localhost:4000/graphql"
});

// Apollo also requires you to provide a cache implementation
// for caching query results. The InMemoryCache is suitable
// for most use cases.
const cache = new InMemoryCache();

// Create the client.
const client = new ApolloClient({
  link,
  cache
});
```

You may find that you need to modify the HTTP request that Apollo makes -- for example, if you wish to send the value of a particular cookie in the `Authorization` header. The `setContext` helper allows you to do this, and also demonstrates how links in Apollo can be chained.

```javascript
import { ApolloClient, InMemoryCache, createHttpLink } from "@apollo/client";
import { setContext } from "@apollo/client/link/context";
import Cookies from "js-cookie";

// Create an HTTP link to the Absinthe server.
const httpLink = createHttpLink({
  uri: "http://localhost:4000/graphql"
});

// Use setContext to create a chainable link object that sets
// the token cookie to the Authorization header.
const authLink = setContext((_, { headers }) => {
  // Get the authentication token from the cookie if it exists.
  const token = Cookies.get("token");

  // Add the new Authorization header.
  return {
    headers: {
      ...headers,
      authorization: token ? `Bearer ${token}` : ""
    }
  };
});

// Chain the HTTP link and the authorization link.
const link = authLink.concat(httpLink);

// Apollo also requires you to provide a cache implementation
// for caching query results. The InMemoryCache is suitable
// for most use cases.
const cache = new InMemoryCache();

// Create the client.
const client = new ApolloClient({
  link,
  cache
});
```

## Using a websocket link

An HTTP link is suitable for many basic use cases, but if you require two-way communication between the server and the client, you will need to use a websocket link. The most common use case is a client that needs to use GraphQL subscriptions to receive updates from the server when particular events occur. To implement a websocket link, we will need to use the [`@absinthe/socket`](https://www.npmjs.com/package/@absinthe/socket) and [`@absinthe/socket-apollo-link`](https://www.npmjs.com/package/@absinthe/socket-apollo-link) packages.

```javascript
import { ApolloClient, InMemoryCache } from "@apollo/client";
import * as AbsintheSocket from "@absinthe/socket";
import { createAbsintheSocketLink } from "@absinthe/socket-apollo-link";
import { Socket as PhoenixSocket } from "phoenix";
import Cookies from "js-cookie";

// Create a standard Phoenix websocket connection. If you need
// to provide additional params, like an authentication token,
// you can configure them in the `params` option.
const phoenixSocket = new PhoenixSocket("ws://localhost:4000/socket", {
  params: () => {
    if (Cookies.get("token")) {
      return { token: Cookies.get("token") };
    } else {
      return {};
    }
  }
});

// Wrap the Phoenix socket in an AbsintheSocket.
const absintheSocket = AbsintheSocket.create(phoenixSocket);

// Create an Apollo link from the AbsintheSocket instance.
const link = createAbsintheSocketLink(absintheSocket);

// Apollo also requires you to provide a cache implementation
// for caching query results. The InMemoryCache is suitable
// for most use cases.
const cache = new InMemoryCache();

// Create the client.
const client = new ApolloClient({
  link,
  cache
});
```

### Reconnecting the websocket link

You may find that you periodically need to reconnect the websocket with different parameters. The most common case for this is when a user logs in or logs out; you will then want to refresh their subscriptions to reflect the new authentication state. You can accomplish this by invoking `phoenixSocket.conn.close();` from your application code whenever the reconnection needs to happen. Phoenix will notice the closed connection and automatically reconnect. It is important that you provide a function that returns the websocket parameters to the socket `params` option. If you provide the parameters directly as an object, the new parameters will not be picked up when the websocket reconnects, but if you provide a function, Phoenix invokes the function on each connection to obtain the parameters.

Note that this solution (reconnecting with `phoenixSocket.conn.close();`) is somewhat unstable because it relies upon an implementation detail of the Phoenix socket. Ideally, a future version of the Phoenix package might add a public API method to reconnect the websocket with new parameters.

```javascript
import { ApolloClient, InMemoryCache } from "@apollo/client";
import * as AbsintheSocket from "@absinthe/socket";
import { createAbsintheSocketLink } from "@absinthe/socket-apollo-link";
import { Socket as PhoenixSocket } from "phoenix";
import Cookies from "js-cookie";

// Create a standard Phoenix websocket connection. If you need
// to provide additional params, like an authentication token,
// you can configure them in the `params` option.
//
// If you plan to reconnect the socket with updated parameters,
// you must provide a function to the `params` option. If you
// provide the parameters directly as an object, the updated
// parameters will not be picked up when the socket reconnects.
const phoenixSocket = new PhoenixSocket("ws://localhost:4000/socket", {
  params: () => {
    if (Cookies.get("token")) {
      return { token: Cookies.get("token") };
    } else {
      return {};
    }
  }
});

// Wrap the Phoenix socket in an AbsintheSocket.
const absintheSocket = AbsintheSocket.create(phoenixSocket);

// Create an Apollo link from the AbsintheSocket instance.
const link = createAbsintheSocketLink(absintheSocket);

// Apollo also requires you to provide a cache implementation
// for caching query results. The InMemoryCache is suitable
// for most use cases.
const cache = new InMemoryCache();

// Create the client.
const client = new ApolloClient({
  link,
  cache
});

// Later in your application code, when you need to reconnect
// the socket.
phoenixSocket.conn.close();
```

## Using both HTTP and websocket links

A common configuration for Apollo client applications is to use both HTTP and websocket links -- HTTP for queries and mutations, and a websocket for subscriptions. We can implement this in our client using [directional composition with Apollo's `split` helper](https://www.apollographql.com/docs/react/api/link/introduction/#directional-composition).

```javascript
import {
  ApolloClient,
  InMemoryCache,
  createHttpLink,
  split
} from "@apollo/client";
import { getMainDefinition } from "@apollo/client/utilities";
import { setContext } from "@apollo/client/link/context";
import * as AbsintheSocket from "@absinthe/socket";
import { createAbsintheSocketLink } from "@absinthe/socket-apollo-link";
import { Socket as PhoenixSocket } from "phoenix";
import Cookies from "js-cookie";

// Create an HTTP link to the Absinthe server.
const httpLink = createHttpLink({
  uri: "http://localhost:4000/graphql"
});

// Use setContext to create a chainable link object that sets
// the token cookie to the Authorization header.
const authLink = setContext((_, { headers }) => {
  // Get the authentication token from the cookie if it exists.
  const token = Cookies.get("token");

  // Add the new Authorization header.
  return {
    headers: {
      ...headers,
      authorization: token ? `Bearer ${token}` : ""
    }
  };
});

// Chain the HTTP link and the authorization link.
const authedHttpLink = authLink.concat(httpLink);

// Create a standard Phoenix websocket connection. If you need
// to provide additional params, like an authentication token,
// you can configure them in the `params` option.
const phoenixSocket = new PhoenixSocket("ws://localhost:4000/socket", {
  params: () => {
    if (Cookies.get("token")) {
      return { token: Cookies.get("token") };
    } else {
      return {};
    }
  }
});

// Wrap the Phoenix socket in an AbsintheSocket.
const absintheSocket = AbsintheSocket.create(phoenixSocket);

// Create an Apollo link from the AbsintheSocket instance.
const websocketLink = createAbsintheSocketLink(absintheSocket);

// If the query contains a subscription, send it through the
// websocket link. Otherwise, send it through the HTTP link.
const link = split(
  (operation) => {
    const definition = getMainDefinition(query);

    return (
      definition.kind === "OperationDefinition" &&
      definition.operation === "subscription"
    );
  },
  websocketLink,
  authedHttpLink
);

// Apollo also requires you to provide a cache implementation
// for caching query results. The InMemoryCache is suitable
// for most use cases.
const cache = new InMemoryCache();

// Create the client.
const client = new ApolloClient({
  link,
  cache
});
```
