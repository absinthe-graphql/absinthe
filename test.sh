#!/bin/sh -e
if [ "${TEST_PERSISTENT_TERM}" = "true" ];
then
  mix test
  echo "Now testing with SCHEMA_PROVIDER=persistent_term"
  SCHEMA_PROVIDER=persistent_term mix test
else
  mix test
fi