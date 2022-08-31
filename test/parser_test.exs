defmodule QueryParser.ParserTest do
  use ExUnit.Case

  alias QueryParser.JsParser
  alias QueryParser.Parser

  @doc """
  This macro will exec the Elixir parser and JS parser and check that both are equal.
  """
  defmacro supported(query) do
    quote do
      assert Parser.parse(Jason.encode!(unquote(query))) ==
               JsParser.parse(Poison.encode!(unquote(query)))
    end
  end

  @doc """
  This macro will check that the JSParser feature does work but elixir does not.
  These features are "not supported" by the elixir parser.
  """
  defmacro not_supported(query) do
    quote do
      assert {:error, _} = Parser.parse(Jason.encode!(unquote(query)))
      assert {:ok, _} = JsParser.parse(Poison.encode!(unquote(query)))
    end
  end

  defmacro custom(expected, query, params \\ %{}) do
    quote do
      assert unquote(expected) = Parser.parse(Jason.encode!(unquote(query)), unquote(params))
    end
  end

  # defmacro not_compatible(query) do
  #   quote do
  #     assert%{:error, _} = Parser.parse(Jason.encode!(unquote(query)))
  #     assert%{:error, _} = JsParser.parse(Jason.encode!(unquote(query)))
  #   end
  # end

  describe "custom behaviors" do
    test "should replace param-ref node when @foo.bar is set as value" do
      custom(
        {:ok,
         %{
           "pos" => "expression",
           "clauses" => [
             %{
               "key" => "stuff",
               "pos" => "leaf-clause",
               "value" => %{
                 "pos" => "leaf-value",
                 "value" => 42
               }
             }
           ]
         }},
        %{"stuff" => "@foo.bar"},
        %{"foo" => %{"bar" => 42}}
      )
    end

    test "should replace param-ref node when @foo is set as value" do
      custom(
        {:ok,
         %{
           "pos" => "expression",
           "clauses" => [
             %{
               "key" => "stuff",
               "pos" => "leaf-clause",
               "value" => %{
                 "pos" => "leaf-value",
                 "value" => 1337
               }
             }
           ]
         }},
        %{"stuff" => "@foo"},
        %{"foo" => 1337}
      )
    end

    test "should replace multiple param-ref nodes if refs are in an array" do
      custom(
        {:ok,
         %{
           "pos" => "expression",
           "clauses" => [
             %{
               "key" => "stuff",
               "pos" => "leaf-clause",
               "value" => %{
                 "pos" => "operator-expression",
                 "operators" => [
                   %{
                     "operator" => "$in",
                     "pos" => "list-operator",
                     "values" => [
                       %{
                         "pos" => "leaf-value",
                         "value" => 1337
                       },
                       %{
                         "pos" => "leaf-value",
                         "value" => "Nice"
                       }
                     ]
                   }
                 ]
               }
             }
           ]
         }},
        %{"stuff" => %{"$in" => ["@foo.bar", "@foo.baz"]}},
        %{"foo" => %{"bar" => 1337, "baz" => "Nice"}}
      )
    end
  end

  describe "Errors on parsing" do
    test "should return an error on an invalid query",
      do: supported(%{foo: %{"$bar" => "stuff"}})
  end

  describe "General Acceptance" do
    test "should accept an empty query", do: supported(%{})
    test "should accept a simple query", do: supported(%{foo: "bar"})
    test "should accept a dotted field name", do: supported(%{"foo.bar" => true})
  end

  describe "Simple Leaf Values" do
    test "should accept a number value", do: supported(%{"foo" => 1})
    test "should accept a decimal number value", do: supported(%{"foo" => 1.23})
    test "should accept a negative number value", do: supported(%{"foo" => -8})
    test "should accept a string value", do: supported(%{"foo" => "bar"})
    test "should accept a nil value", do: supported(%{"foo" => nil})
    test "should accept a boolean value", do: supported(%{"foo" => false})
  end

  describe "Extended JSON Leaf Values" do
    test "should accept a regular expression" do
      not_supported(%{"foo" => %{"$regex" => "^bar"}})
      not_supported(%{"foo" => %{"$regex" => "^bar", "$options" => "gi"}})
    end

    test "should reject a regular expression with invalid options" do
      supported(%{"foo" => %{"$regex" => "^bar", "$options" => "uvw"}})
    end

    test "should accept ObjectIds" do
      not_supported(%{"_id" => %{"$oid" => "57d64ffce97e2f2f90f37ccd"}})
    end

    test "should reject ObjectIds with invalid id length" do
      supported(%{"_id" => %{"$oid" => "5f37ccd"}})
    end

    test "should accept Undefined" do
      not_supported(%{"_id" => %{"$undefined" => true}})
    end

    test "should accept MinKey" do
      not_supported(%{"lower" => %{"$minKey" => 1}})
    end

    test "should accept MaxKey" do
      not_supported(%{"upper" => %{"$maxKey" => 1}})
    end

    test "should accept NumberLong values" do
      not_supported(%{"epoch" => %{"$numberLong" => "12345678901234567890"}})
    end

    test "should reject NumberLong values that are unquoted" do
      supported(%{"epoch" => %{"$numberLong" => 1_234_567_890}})
    end

    test "should accept negative NumberLong values" do
      not_supported(%{"epoch" => %{"$numberLong" => "-23434"}})
    end

    test "should accept NumberDecimal values" do
      not_supported(%{"epoch" => %{"$numberDecimal" => "1.234"}})
    end

    test "should accept negative NumberDecimal values" do
      not_supported(%{"epoch" => %{"$numberDecimal" => "-1.234"}})
    end

    test "should reject empty NumberDecimal values" do
      supported(%{"epoch" => %{"$numberDecimal" => ""}})
    end

    test "should reject NumberDecimal values that are unquoted" do
      supported(%{"epoch" => %{"$numberDecimal" => 1.234}})
    end

    test "should accept Timestamp values" do
      # Seems that the "i" and "t" should be ordred.
      # Elixir map are not ordered, js map are. This cause the query to fail using the js query.
      not_supported(%{"ts" => %{"$timestamp" => %{"i" => 0, "t" => 5}}})
    end

    test "should reject incomplete Timestamp values" do
      supported(%{"ts" => %{"$timestamp" => %{"t" => 5}}})
      supported(%{"ts" => %{"$timestamp" => %{"i" => 5}}})
    end

    test "should accept Dates in ISO-8601 form" do
      not_supported(%{"_id" => %{"$date" => "1978-09-29T03:04:05.006Z"}})
    end

    test "should accept Dates in $numberLong form" do
      not_supported(%{"_id" => %{"$date" => %{"$numberLong" => "1473838623000"}}})
    end

    # test "should accept Binary values" do
    #   not_supported(%{"payload" => %{"$binary" => "1234==", "$type" => "3"}})
    # end

    test "should reject Binary values without a type" do
      supported(%{"payload" => %{"$binary" => "1234=="}})
    end

    test "should accept DBRef values" do
      not_supported(%{
        "link" => %{"$ref" => "foo.bar", "$id" => %{"$oid" => "57d64ffce97e2f2f90f37ccd"}}
      })
    end
  end

  describe "Value Operators" do
    test "should accept $gt / $gte operator" do
      supported(%{"foo" => %{"$gt" => 20}})
      supported(%{"foo" => %{"$gt" => 20}})
    end

    test "should accept $lt / $lte operator" do
      supported(%{"foo" => %{"$lt" => 20}})
      supported(%{"foo" => %{"$lte" => 20}})
    end

    test "should accept $eq / $ne operator" do
      supported(%{"foo" => %{"$eq" => 20}})
      supported(%{"foo" => %{"$ne" => 20}})
    end

    test "should accept $exists operator" do
      supported(%{"foo" => %{"$exists" => true}})
      supported(%{"foo" => %{"$exists" => false}})
    end

    test "should accept $type operator" do
      not_supported(%{"foo" => %{"$type" => 3}})
      not_supported(%{"foo" => %{"$type" => "string"}})
    end

    test "should accept $size operator" do
      not_supported(%{"foo" => %{"$size" => 10}})
    end

    test "should accept $regex operator without options (via leaf value)" do
      not_supported(%{"foo" => %{"$regex" => "^foo"}})
    end

    test "should accept $regex operator with options (via leaf value)" do
      not_supported(%{"foo" => %{"$regex" => "^foo", "$options" => "ig"}})
    end
  end

  describe "List Operators" do
    test "should accept $in operator" do
      supported(%{"foo" => %{"$in" => [1, 2, 3]}})
      supported(%{"foo" => %{"$in" => []}})
      supported(%{"foo" => %{"$in" => ["a", nil, false, 4.35]}})
    end

    test "should reject $in operator without an array" do
      supported(%{"foo" => %{"$in" => "bar"}})
      supported(%{"foo" => %{"$in" => 3}})
      supported(%{"foo" => %{"$in" => %{"a" => 1}}})
    end

    test "should accept $nin operator" do
      supported(%{"foo" => %{"$nin" => [1, 2, 3]}})
      supported(%{"foo" => %{"$nin" => []}})
      supported(%{"foo" => %{"$nin" => ["a", nil, false, 4.35]}})
    end

    test "should accept $all operator" do
      supported(%{"tags" => %{"$all" => ["ssl", "security"]}})
      supported(%{"tags" => %{"$all" => [["ssl", "security"]]}})
    end
  end

  describe "Operator Expression Operators" do
    test "should accept $elemMatch in its expression form" do
      not_supported(%{
        "results" => %{"$elemMatch" => %{"product" => "xyz", "score" => %{"$gte" => 8}}}
      })
    end

    test "should accept $elemMatch in its operator form" do
      not_supported(%{"results" => %{"$elemMatch" => %{"$gte" => 8, "$lt" => 20}}})
    end

    test "should reject $elemMatch in a top-level operator position" do
      supported(%{"$elemMatch" => %{"name" => %{"$exists" => true}}})
    end

    test "should reject $elemMatch in a value-operator position" do
      supported(%{"name" => %{"$elemMatch" => true}})
    end

    test "should accept $not with an operator object as its value" do
      not_supported(%{"names" => %{"$exists" => true, "$not" => %{"$size" => 0}}})
    end

    test "should accept $not with a complex operator object as its value" do
      not_supported(%{"names" => %{"$not" => %{"$exists" => true, "$size" => 0}}})
    end

    test "should accept $not in combination with a $regex operator without options" do
      not_supported(%{"name" => %{"$not" => %{"$regex" => "^Th"}}})
    end

    test "should accept $not in combination with a $regex operator with options" do
      not_supported(%{"name" => %{"$not" => %{"$regex" => "^Th", "$options" => "g"}}})
    end

    test "should reject $not in combination with an invalid $regex operator" do
      supported(%{"name" => %{"$not" => %{"$regex" => "^Th", "$legitimate" => "false"}}})
    end

    test "should reject $elemMatch in combination with a $regex operator" do
      supported(%{"name" => %{"$elemMatch" => %{"$regex" => "^Th"}}})
    end

    test "should reject $not in a top-level operator position" do
      supported(%{"$not" => %{"name" => %{"$exists" => true}}})
    end

    test "should reject $not as a value-operator position" do
      supported(%{"name" => %{"$not" => true}})
    end
  end

  describe "Geo operators $geoWithin" do
    test "should accept a $geoWithin query with $centerSphere legacy shape" do
      not_supported(%{"loc" => %{"$geoWithin" => %{"$centerSphere" => [[-87.71, 38.64], 0.03]}}})
    end

    test "should accept a $geoWithin query with $center legacy shape" do
      not_supported(%{"loc" => %{"$geoWithin" => %{"$center" => [[-87.71, 38.64], 0.03]}}})
    end

    test "should accept a $geoWithin query with $box legacy shape" do
      not_supported(%{"loc" => %{"$geoWithin" => %{"$box" => [[0, 0], [100, 100]]}}})
    end

    test "should accept a $geoWithin query with $polygon legacy shape" do
      not_supported(%{
        "loc" => %{"$geoWithin" => %{"$polygon" => [[0, 0], [100, 100], [1, 4], [1, 5]]}}
      })
    end

    test "should accept a $geoWithin query with Polygon $geometry without hole" do
      not_supported(%{
        "loc" => %{
          "$geoWithin" => %{
            "$geometry" => %{
              "type" => "Polygon",
              "coordinates" => [
                [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]]
              ]
            }
          }
        }
      })
    end

    test "should accept a $geoWithin query with Polygon $geometry with hole" do
      not_supported(%{
        "loc" => %{
          "$geoWithin" => %{
            "$geometry" => %{
              "type" => "Polygon",
              "coordinates" => [
                [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]],
                [[100.2, 0.2], [100.8, 0.2], [100.8, 0.8], [100.2, 0.8], [100.2, 0.2]]
              ]
            }
          }
        }
      })
    end

    test "should accept a $geoWithin query with MultiPolygon $geometry" do
      not_supported(%{
        "loc" => %{
          "$geoWithin" => %{
            "$geometry" => %{
              "type" => "MultiPolygon",
              "coordinates" => [
                [
                  [[102.0, 2.0], [103.0, 2.0], [103.0, 3.0], [102.0, 3.0], [102.0, 2.0]]
                ],
                [
                  [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]],
                  [[100.2, 0.2], [100.8, 0.2], [100.8, 0.8], [100.2, 0.8], [100.2, 0.2]]
                ]
              ]
            }
          }
        }
      })
    end
  end

  describe "Geo operators $geoIntersects" do
    test "should reject a $geoIntersects query with $centerSphere legacy shape" do
      supported(%{
        "loc" => %{"$geoIntersects" => %{"$centerSphere" => [[-87.71, 38.64], 0.03]}}
      })
    end

    test "should reject a $geoIntersects query with $center legacy shape" do
      supported(%{"loc" => %{"$geoIntersects" => %{"$center" => [[-87.71, 38.64], 0.03]}}})
    end

    test "should reject a $geoIntersects query with $box legacy shape" do
      supported(%{"loc" => %{"$geoIntersects" => %{"$box" => [[0, 0], [100, 100]]}}})
    end

    test "should reject a $geoIntersects query with $polygon legacy shape" do
      supported(%{
        "loc" => %{"$geoIntersects" => %{"$polygon" => [[0, 0], [100, 100], [1, 4], [1, 5]]}}
      })
    end

    test "should accept a $geoIntersects query with Polygon $geometry without hole" do
      not_supported(%{
        "loc" => %{
          "$geoIntersects" => %{
            "$geometry" => %{
              "type" => "Polygon",
              "coordinates" => [
                [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]]
              ]
            }
          }
        }
      })
    end

    test "should accept a $geoIntersects query with Polygon $geometry with hole" do
      not_supported(%{
        "loc" => %{
          "$geoIntersects" => %{
            "$geometry" => %{
              "type" => "Polygon",
              "coordinates" => [
                [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]],
                [[100.2, 0.2], [100.8, 0.2], [100.8, 0.8], [100.2, 0.8], [100.2, 0.2]]
              ]
            }
          }
        }
      })
    end

    test "should accept a $geoIntersects query with MultiPolygon $geometry" do
      not_supported(%{
        "loc" => %{
          "$geoIntersects" => %{
            "$geometry" => %{
              "type" => "MultiPolygon",
              "coordinates" => [
                [
                  [[102.0, 2.0], [103.0, 2.0], [103.0, 3.0], [102.0, 3.0], [102.0, 2.0]]
                ],
                [
                  [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]],
                  [[100.2, 0.2], [100.8, 0.2], [100.8, 0.8], [100.2, 0.8], [100.2, 0.2]]
                ]
              ]
            }
          }
        }
      })
    end
  end

  describe "Geo operators $near" do
    test "should accept a $near query with Point $geometry coordinates specifying valid longitude and latitude values" do
      not_supported(%{
        "loc" => %{
          "$near" => %{
            "$geometry" => %{
              "type" => "Point",
              "coordinates" => [-87.71, 38.64]
            }
          }
        }
      })
    end

    test "should reject a $near query with an invalid $geometry type" do
      supported(%{
        "loc" => %{
          "$near" => %{
            "$geometry" => %{
              "type" => "Polygon",
              "coordinates" => [-87.71, 38.64]
            }
          }
        }
      })
    end

    test "should reject a $near query with Point $geometry coordinates specifying invalid longitude and latitude values" do
      supported(%{
        "loc" => %{
          "$near" => %{
            "$geometry" => %{
              "type" => "Point",
              "coordinates" => [180.71, -91.1]
            }
          }
        }
      })
    end

    # test "should accept a $near query with Point $geometry with $minDistance limit" do
    #   not_supported(%{
    #     "loc" => %{
    #       "$near" => %{
    #         "$geometry" => %{
    #           "type" => "Point",
    #           "coordinates" => [-87.71, 38.64]
    #         },
    #         "$minDistance" => 1000
    #       }
    #     }
    #   })
    # end

    # test "should accept a $near query with Point $geometry with $maxDistance limit" do
    #   not_supported(%{
    #     "loc" => %{
    #       "$near" => %{
    #         "$geometry" => %{
    #           "type" => "Point",
    #           "coordinates" => [-87.71, 38.64]
    #         },
    #         "$maxDistance" => 5000
    #       }
    #     }
    #   })
    # end

    # test "should accept a $near query with Point $geometry with $minDistance and $maxDistance limits" do
    #   not_supported(%{
    #     "loc" => %{
    #       "$near" => %{
    #         "$geometry" => %{
    #           "type" => "Point",
    #           "coordinates" => [-87.71, 38.64]
    #         },
    #         "$minDistance" => 1000,
    #         "$maxDistance" => 5000
    #       }
    #     }
    #   })

    #   # Test with the order of the limits flipped ($maxDistance then $minDistance)
    #   not_supported(%{
    #     "loc" => %{
    #       "$near" => %{
    #         "$geometry" => %{
    #           "type" => "Point",
    #           "coordinates" => [-87.71, 38.64]
    #         },
    #         "$maxDistance" => 5000,
    #         "$minDistance" => 1000
    #       }
    #     }
    #   })
    # end

    test "should accept a $near query with legacy coordinates specifying valid longitude and latitude values" do
      not_supported(%{
        "loc" => %{
          "$near" => [-87.71, 38.64]
        }
      })
    end

    test "should reject a $near query with legacy coordinates specifying invalid longitude and latitude values" do
      supported(%{
        "loc" => %{
          "$near" => [180.71, -91.1]
        }
      })
    end

    test "should accept a $near query with legacy coordinates with $minDistance limit" do
      not_supported(%{
        "loc" => %{
          "$near" => [-87.71, 38.64],
          "$minDistance" => 1000
        }
      })
    end

    test "should accept a $near query with legacy coordinates with $maxDistance limit" do
      not_supported(%{
        "loc" => %{
          "$near" => [-87.71, 38.64],
          "$maxDistance" => 5000
        }
      })
    end

    test "should accept a $near query with legacy coordinates with $minDistance and $maxDistance limits" do
      not_supported(%{
        "loc" => %{
          "$near" => [-87.71, 38.64],
          "$minDistance" => 1000,
          "$maxDistance" => 5000
        }
      })

      # Test with the order of the limits flipped ($maxDistance then $minDistance)
      not_supported(%{
        "loc" => %{
          "$near" => [-87.71, 38.64],
          "$maxDistance" => 5000,
          "$minDistance" => 1000
        }
      })
    end
  end

  describe "Geo operators $nearSphere" do
    test "should accept a $nearSphere query with Point $geometry coordinates specifying valid longitude and latitude values" do
      not_supported(%{
        "loc" => %{
          "$nearSphere" => %{
            "$geometry" => %{
              "type" => "Point",
              "coordinates" => [-87.71, 38.64]
            }
          }
        }
      })
    end

    test "should reject a $nearSphere query with an invalid $geometry type" do
      supported(%{
        "loc" => %{
          "$nearSphere" => %{
            "$geometry" => %{
              "type" => "Polygon",
              "coordinates" => [-87.71, 38.64]
            }
          }
        }
      })
    end

    test "should reject a $nearSphere query with Point $geometry coordinates specifying invalid longitude and latitude values" do
      supported(%{
        "loc" => %{
          "$nearSphere" => %{
            "$geometry" => %{
              "type" => "Point",
              "coordinates" => [180.71, -91.1]
            }
          }
        }
      })
    end

    # test "should accept a $nearSphere query with Point $geometry with $minDistance limit" do
    #   not_supported(%{
    #     "loc" => %{
    #       "$nearSphere" => %{
    #         "$geometry" => %{
    #           "type" => "Point",
    #           "coordinates" => [-87.71, 38.64]
    #         },
    #         "$minDistance" => 1000
    #       }
    #     }
    #   })
    # end

    # test "should accept a $nearSphere query with Point $geometry with $maxDistance limit" do
    #   not_supported(%{
    #     "loc" => %{
    #       "$nearSphere" => %{
    #         "$geometry" => %{
    #           "type" => "Point",
    #           "coordinates" => [-87.71, 38.64]
    #         },
    #         "$maxDistance" => 5000
    #       }
    #     }
    #   })
    # end

    # test "should accept a $nearSphere query with Point $geometry with $minDistance and $maxDistance limits" do
    #   not_supported(%{
    #     "loc" => %{
    #       "$nearSphere" => %{
    #         "$geometry" => %{
    #           "type" => "Point",
    #           "coordinates" => [-87.71, 38.64]
    #         },
    #         "$minDistance" => 1000,
    #         "$maxDistance" => 5000
    #       }
    #     }
    #   })
    #   # Test with the order of the limits flipped ($maxDistance then $minDistance)
    #   not_supported(%{
    #     "loc" => %{
    #       "$nearSphere" => %{
    #         "$geometry" => %{
    #           "type" => "Point",
    #           "coordinates" => [-87.71, 38.64]
    #         },
    #         "$maxDistance" => 5000,
    #         "$minDistance" => 1000
    #       }
    #     }
    #   })
    # end

    test "should accept a $nearSphere query with legacy coordinates specifying valid longitude and latitude values" do
      not_supported(%{
        "loc" => %{
          "$nearSphere" => [-87.71, 38.64]
        }
      })
    end

    test "should reject a $nearSphere query with legacy coordinates specifying invalid longitude and latitude values" do
      supported(%{
        "loc" => %{
          "$nearSphere" => [180.71, -91.1]
        }
      })
    end

    test "should accept a $nearSphere query with legacy coordinates with $minDistance limit" do
      not_supported(%{
        "loc" => %{
          "$nearSphere" => [-87.71, 38.64],
          "$minDistance" => 1000
        }
      })
    end

    test "should accept a $nearSphere query with legacy coordinates with $maxDistance limit" do
      not_supported(%{
        "loc" => %{
          "$nearSphere" => [-87.71, 38.64],
          "$maxDistance" => 5000
        }
      })
    end

    test "should accept a $nearSphere query with legacy coordinates with $minDistance and $maxDistance limits" do
      not_supported(%{
        "loc" => %{
          "$nearSphere" => [-87.71, 38.64],
          "$minDistance" => 1000,
          "$maxDistance" => 5000
        }
      })

      # Test with the order of the limits flipped ($maxDistance then $minDistance)
      not_supported(%{
        "loc" => %{
          "$nearSphere" => [-87.71, 38.64],
          "$maxDistance" => 5000,
          "$minDistance" => 1000
        }
      })
    end
  end

  describe "Expressions as top level operator" do
    test "should accept simple $expr operator" do
      not_supported(%{"$expr" => %{"$gt" => ["$sold", "$total"]}})
    end
  end

  describe "Expressions as nested operator" do
    test "should accept simple $expr operator" do
      not_supported(%{"$and" => [%{"foo" => 1}, %{"$expr" => %{"$gt" => ["$sold", "$total"]}}]})
    end
  end

  describe "Logical Expression Trees" do
    test "should accept simple $and expressions" do
      supported(%{"$and" => [%{"foo" => 1}, %{"bar" => 1}]})
      supported(%{"$and" => [%{"foo" => %{"$gt" => 1}}]})
      supported(%{"$and" => []})
    end

    test "should accept simple $or expressions" do
      supported(%{"$or" => [%{"foo" => 1}, %{"bar" => 1}]})
      supported(%{"$or" => [%{"foo" => %{"$gt" => 1}}]})
      supported(%{"$or" => []})
    end

    test "should accept simple $nor expressions" do
      supported(%{"$nor" => [%{"foo" => 1}, %{"bar" => 1}]})
      supported(%{"$nor" => [%{"foo" => %{"$gt" => 1}}]})
      supported(%{"$nor" => []})
    end

    test "should accept mixed, nested expression trees" do
      supported(%{
        "$or" => [
          %{"a" => 1, "b" => 2},
          %{
            "$or" => [
              %{
                "$nor" => [
                  %{"c" => true},
                  %{"d" => %{"$exists" => false}}
                ]
              },
              %{
                "e" => 1
              }
            ]
          }
        ]
      })
    end

    test "should accept simple OR" do
      supported(%{
        "$or" => [
          %{"a" => 1, "b" => 2}
        ]
      })
    end
  end

  describe "Where Clauses" do
    test "should accept a single $where clause with a string value" do
      not_supported(%{"$where" => "this.age > 60;"})
    end

    test "should accept a $where clause combined with a leaf-clause" do
      not_supported(%{"$where" => "this.age > 60;", "membership_status" => "ACTIVE"})
    end
  end

  describe "Special queries" do
    test "accepts $bitsAllClear queries with arrays" do
      not_supported(%{"a" => %{"$bitsAllClear": [1, 5]}})
    end

    test "accepts $bitsAllClear queries with bitmasks" do
      not_supported(%{"a" => %{"$bitsAllClear": 35}})
    end

    test "accepts $bitsAnyClear queries with arrays" do
      not_supported(%{"a" => %{"$bitsAnyClear": [1, 5]}})
    end

    test "accepts $bitsAnyClear queries with bitmasks" do
      not_supported(%{"a" => %{"$bitsAnyClear": 35}})
    end

    test "accepts $bitsAllSet queries with arrays" do
      not_supported(%{"a" => %{"$bitsAllClear": [1, 5]}})
    end

    test "accepts $bitsAllSet queries with bitmasks" do
      not_supported(%{"a" => %{"$bitsAllClear": 35}})
    end

    test "accepts $bitsAnySet queries with arrays" do
      not_supported(%{"a" => %{"$bitsAnyClear": [1, 5]}})
    end

    test "accepts $bitsAnySet queries with bitmasks" do
      not_supported(%{"a" => %{"$bitsAnyClear": 35}})
    end

    test "accepts $text queries with $search" do
      not_supported(%{"$text" => %{"$search": "coffee"}})
    end

    test "accepts $text queries with $search & $language" do
      not_supported(%{"$text" => %{"$search": "coffee", "$language": "es"}})
    end

    test "accepts $text queries with $search and $caseSensitive" do
      not_supported(%{"$text" => %{"$search": "coffee", "$caseSensitive": true}})
    end

    test "accepts $mod queries" do
      not_supported(%{"qty" => %{"$mod": [4, 0]}})
    end
  end

  describe "Parser.replace_params/2" do
    test "base param in a map" do
      assert %{"foo" => "bar"} = Parser.replace_params(%{"foo" => "@me"}, %{"me" => "bar"})
    end

    test "path param in a map" do
      assert %{"foo" => "bar"} =
               Parser.replace_params(%{"foo" => "@me.stuff"}, %{"me" => %{"stuff" => "bar"}})
    end

    test "multiple path param in a map" do
      assert %{"foo" => "bar", "bar" => "baz"} =
               Parser.replace_params(
                 %{"foo" => "@me.stuff", "bar" => "@user.name"},
                 %{
                   "me" => %{"stuff" => "bar"},
                   "user" => %{"name" => "baz"}
                 }
               )
    end

    test "double @ to escape" do
      assert %{"foo" => "@@me"} = Parser.replace_params(%{"foo" => "@@me"}, %{"me" => "bar"})
    end

    test "param name should accept _ letter and numbers to escape" do
      assert %{"foo" => "bar"} = Parser.replace_params(%{"foo" => "@me_42"}, %{"me_42" => "bar"})
    end

    test "param name should accept var starting with _" do
      assert %{"foo" => "bar"} = Parser.replace_params(%{"foo" => "@_me"}, %{"_me" => "bar"})
    end

    test "param name should NOT accept var starting with number" do
      assert %{"foo" => "@42"} = Parser.replace_params(%{"foo" => "@42"}, %{"42" => "bar"})
    end

    test "param name should put null if param does not exist" do
      assert %{"foo" => nil} = Parser.replace_params(%{"foo" => "@me"}, %{})
    end
  end
end
