#!/bin/sh -e
if [ "${TEST_PERSISTENT_TERM}" = "true" ];
then
  MIX_ENV=test mix clean
  mix test
  echo "Now testing with SCHEMA_PROVIDER=persistent_term"
  # This has to be done so that the test schemas recompile with the persistent
  # term environment variable set.
  MIX_ENV=test mix clean
  SCHEMA_PROVIDER=persistent_term mix test
else
  mix test
fi