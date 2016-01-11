# Changelog

## v0.3.0

The following changes are required if you're upgrading from the previous version:

- Adapters
  - If using `Absinthe.Adapters.Passthrough`, you must manually configure it,
  [as explained in the README](./README.md#adapters), now that the default has
  changed to `Absinthe.Adapters.LanguageConventions`.
