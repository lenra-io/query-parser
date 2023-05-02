defmodule QueryParser.ExecTest do
  use ExUnit.Case

  alias LenraCommon.Errors.BusinessError

  def parse_and_exec(data, query, params \\ %{}) do
    ast =
      query
      |> Poison.encode!()
      |> QueryParser.Parser.parse!(params)

    QueryParser.Exec.find(data, ast)
  end

  def parse_and_match?(data, query, params \\ %{}) do
    ast =
      query
      |> Poison.encode!()
      |> QueryParser.Parser.parse!(params)

    QueryParser.Exec.match?(data, ast)
  end

  @doc """
  This generate a single data Map for test purpose.
  """
  def datum(idx) do
    even? = rem(idx, 2) == 0
    parity = if even?, do: "even", else: "odd"

    above5 = idx > 5
    prev = Enum.to_list(1..(idx - 1))

    %{
      "_id" => idx,
      "ids" => [idx],
      "name" => "test#{idx}",
      "parity" => parity,
      "even" => even?,
      "above5" => above5,
      "prev" => prev,
      "nested" => %{
        "name" => "test#{idx}",
        "parity" => parity,
        "even" => even?,
        "#{idx}" => "hello"
      }
    }
  end

  @doc """
  This will generate a list of 10 test data.
  """
  def data do
    Enum.map(1..10, &datum/1)
  end

  describe "match/2" do
    test "Empty match should return true" do
      assert parse_and_match?(%{"a" => "b"}, %{})
    end

    test "Simple match should return true" do
      assert parse_and_match?(%{"a" => "b"}, %{"a" => "b"})
    end

    test "nested match should return true" do
      assert parse_and_match?(%{"a" => %{"b" => "c"}}, %{"a.b" => "c"})
    end
  end

  describe "exec/2 custom features param-ref" do
    test "Simple param-ref @foo should be replaced by 1" do
      assert [%{"_id" => 1}] = parse_and_exec(data(), %{"_id" => "@foo"}, %{"foo" => 1})
    end

    test "Simple param-ref @foo.bar should be replaced by 1" do
      assert [%{"_id" => 1}] =
               parse_and_exec(data(), %{"_id" => "@foo.bar"}, %{"foo" => %{"bar" => 1}})
    end

    test "Simple param-ref @foo.bar and @foo.baz should be replaced by 1 and 2" do
      assert [%{"_id" => 1}, %{"_id" => 2}] =
               parse_and_exec(
                 data(),
                 %{"_id" => %{"$in" => ["@foo.bar", "@foo.baz"]}},
                 %{"foo" => %{"bar" => 1, "baz" => 2}}
               )
    end
  end

  describe "exec/2" do
    test "Empty query should return the all docs" do
      test_data = data()
      assert test_data == parse_and_exec(test_data, %{})
    end

    test "should return the _id == 1 doc" do
      assert [%{"_id" => 1}] = parse_and_exec(data(), %{"_id" => 1})
    end

    test "should return the name == 'test2' doc using implicit equal" do
      assert [%{"_id" => 2}] = parse_and_exec(data(), %{"name" => "test2"})
    end

    test "should return the name == 'test2' doc using $eq" do
      assert [%{"_id" => 2}] = parse_and_exec(data(), %{"name" => %{"$eq" => "test2"}})
    end

    test "should return the all _id < 3 doc using $lt" do
      assert [
               %{"_id" => 1},
               %{"_id" => 2}
             ] = parse_and_exec(data(), %{"_id" => %{"$lt" => 3}})
    end

    test "should return the all _id <= 3 doc using $lte" do
      assert [
               %{"_id" => 1},
               %{"_id" => 2},
               %{"_id" => 3}
             ] = parse_and_exec(data(), %{"_id" => %{"$lte" => 3}})
    end

    test "should return the all _id > 8 doc using $gt" do
      assert [
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"_id" => %{"$gt" => 8}})
    end

    test "should return the all _id >= 8 doc using $gte" do
      assert [
               %{"_id" => 8},
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"_id" => %{"$gte" => 8}})
    end

    test "should return the all docs using $exists" do
      assert [
               %{"_id" => 1},
               %{"_id" => 2},
               %{"_id" => 3},
               %{"_id" => 4},
               %{"_id" => 5},
               %{"_id" => 6},
               %{"_id" => 7},
               %{"_id" => 8},
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"_id" => %{"$exists" => true}})
    end

    test "should return the no doc using $exists false" do
      assert [] = parse_and_exec(data(), %{"_id" => %{"$exists" => false}})
    end

    test "should return the all but name == 'test2' doc using $ne" do
      assert [
               %{"_id" => 1},
               %{"_id" => 3},
               %{"_id" => 4},
               %{"_id" => 5},
               %{"_id" => 6},
               %{"_id" => 7},
               %{"_id" => 8},
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"name" => %{"$ne" => "test2"}})
    end

    test "should return the an empty doc" do
      assert [] = parse_and_exec(data(), %{"name" => "none"})
    end

    test "should return the even docs" do
      assert [%{"_id" => 2}, %{"_id" => 4}, %{"_id" => 6}, %{"_id" => 8}, %{"_id" => 10}] =
               parse_and_exec(data(), %{"even" => true})
    end

    test "should return the even AND above id 5 docs using multi clauses" do
      assert [
               %{"_id" => 6},
               %{"_id" => 8},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"even" => true, "above5" => true})
    end

    test "should return the test1 doc for nested element" do
      assert [
               %{"_id" => 1}
             ] = parse_and_exec(data(), %{"nested.name" => "test1"})
    end

    test "should return the test1 & test2 doc for nested element" do
      assert [
               %{"_id" => 1}
             ] =
               parse_and_exec(
                 data(),
                 %{"ids.0" => 1}
               )
    end

    test "should return the test1 doc interger in path" do
      assert [
               %{"_id" => 1}
             ] =
               parse_and_exec(
                 data(),
                 %{"nested.1" => "hello"}
               )
    end

    test "should return error if specify string for array" do
      assert [] =
               parse_and_exec(
                 data(),
                 %{"ids.test" => 1}
               )
    end

    test "should return the even AND above id 5 docs using $and" do
      assert [
               %{"_id" => 6},
               %{"_id" => 8},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"$and" => [%{"even" => true}, %{"above5" => true}]})
    end

    test "should return any _id $in [1, 2, 5]" do
      assert [
               %{"_id" => 1},
               %{"_id" => 2},
               %{"_id" => 5}
             ] = parse_and_exec(data(), %{"_id" => %{"$in" => [1, 2, 5]}})
    end

    test "should return objet if find in array" do
      assert [
               %{"_id" => 1}
             ] = parse_and_exec(data(), %{"ids" => 1})
    end

    test "should return objet if find in array with function" do
      assert [
               %{"_id" => 1}
             ] = parse_and_exec(data(), %{"ids" => %{"$lt" => 2}})
    end

    test "should return objet if find in array with many function" do
      assert [
               %{"_id" => 7},
               %{"_id" => 8},
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"prev" => %{"$lt" => 2, "$gt" => 5}})
    end

    test "should return objet if find in array with many function 2" do
      assert [
               %{"_id" => 4},
               %{"_id" => 5},
               %{"_id" => 6},
               %{"_id" => 7},
               %{"_id" => 8},
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"prev" => %{"$gt" => 2, "$lt" => 5}})
    end

    test "should return any _id NOT in [1, 2, 5]" do
      assert [
               %{"_id" => 3},
               %{"_id" => 4},
               %{"_id" => 6},
               %{"_id" => 7},
               %{"_id" => 8},
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"_id" => %{"$nin" => [1, 2, 5]}})
    end

    test "should return any _id NOT in [8,9]" do
      assert [
               %{"_id" => 1},
               %{"_id" => 2},
               %{"_id" => 3},
               %{"_id" => 4},
               %{"_id" => 5},
               %{"_id" => 6},
               %{"_id" => 7},
               %{"_id" => 8}
             ] = parse_and_exec(data(), %{"prev" => %{"$nin" => [8, 9]}})
    end

    test "should return all elem with 4 & 5 elem in the prev array" do
      assert [
               %{"_id" => 5},
               %{"_id" => 6},
               %{"_id" => 7},
               %{"_id" => 8},
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"prev" => %{"$in" => [4, 5]}})
    end

    test "should return all elem after _id 8 witch have $all [1, 2, 3] in the prev array" do
      assert [
               %{"_id" => 8},
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"prev" => %{"$all" => [1, 4, 7]}})
    end

    test "should return the even OR above id 5 docs" do
      assert [
               %{"_id" => 2},
               %{"_id" => 4},
               %{"_id" => 6},
               %{"_id" => 7},
               %{"_id" => 8},
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"$or" => [%{"even" => true}, %{"above5" => true}]})
    end

    test "should return the even Exclusive OR above id 5 docs using $nor" do
      assert [
               %{"_id" => 1},
               %{"_id" => 3},
               %{"_id" => 5}
             ] = parse_and_exec(data(), %{"$nor" => [%{"even" => true}, %{"above5" => true}]})
    end

    test "Complexe query with $and/$or and nested items and inverted one" do
      query = %{
        "$or" => [
          %{"_id" => %{"$in" => [1, 2]}},
          %{
            "$and" => [
              %{"_id" => %{"$gt" => 5, "$lte" => 8}},
              %{"even" => true}
            ]
          }
        ]
      }

      assert [
               %{"_id" => 1},
               %{"_id" => 2},
               %{"_id" => 6},
               %{"_id" => 8}
             ] = parse_and_exec(data(), query)

      assert [
               %{"_id" => 3},
               %{"_id" => 4},
               %{"_id" => 5},
               %{"_id" => 7},
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"$nor" => [query]})
    end

    test "should return all prv gretter than 5" do
      assert [
               %{"_id" => 6},
               %{"_id" => 7},
               %{"_id" => 8},
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"_id" => %{"$gt" => 5}})

      assert [
               %{"_id" => 5},
               %{"_id" => 6},
               %{"_id" => 7},
               %{"_id" => 8},
               %{"_id" => 9},
               %{"_id" => 10}
             ] = parse_and_exec(data(), %{"_id" => %{"$not" => %{"$lt" => 5}}})
    end

    test "size operator can only take array" do
      assert_raise ArgumentError, fn -> parse_and_exec(data(), %{"_id" => %{"$size" => 5}}) end
      assert [] = parse_and_exec(data(), %{"ids" => %{"$size" => 10}})
    end
  end
end
