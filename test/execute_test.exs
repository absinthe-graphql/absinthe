#  Copyright (c) 2015, Facebook, Inc.
#  All rights reserved.
#
#  This source code is licensed under the BSD-style license found in the
#  LICENSE file in the root directory of this source tree. An additional grant
#  of patent rights can be found in the PATENTS file in the same directory.

defmodule ExecuteTest do
  use ExUnit.Case
  doctest ExGraphQL

  test "Correctly identifies R2-D2 as the hero of the Star Wars Saga" do
    query = """
      query HeroNameQuery {
        hero {
          name
        }
      }
    """
    assert ExGraphQL.execute(Fixtures.StarWarsSchema.schema, query) == %{hero: %{name: "R2-D2"}}
  end
end
