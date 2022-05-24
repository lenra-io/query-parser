defmodule QueryParser.ATS.EctoParserTest do
  use QueryParser.RepoCase

  alias QueryParser.AST.{
    EctoParser,
    Parser
  }

  alias QueryParser.{
    Data,
    DataReferences,
    Datastore,
    FakeLenraEnvironment,
    FakeLenraUser,
    Repo,
    UserData
  }

  setup do
    {:ok, %{id: user_id}} = FakeLenraUser.new() |> Repo.insert()
    {:ok, %{id: env_id}} = FakeLenraEnvironment.new() |> Repo.insert()

    # DatastoreServices.create(env_id, %{"name" => "_users"}) |> Repo.transaction()
    %{id: datastore_users_id} = Repo.insert!(Datastore.new(env_id, %{name: "_users"}))
    # DatastoreServices.create(env_id, %{"name" => "todoList"}) |> Repo.transaction()
    %{id: datastore_todo_list_id} = Repo.insert!(Datastore.new(env_id, %{name: "todoList"}))

    # DatastoreServices.create(env_id, %{"name" => "todos"}) |> Repo.transaction()
    %{id: datastore_todos_id} = Repo.insert!(Datastore.new(env_id, %{name: "todos"}))

    # # 1
    # {:ok, %{inserted_data: %{id: user_data_id}}} =
    #   DataServices.create(env_id, %{"_datastore" => "_users", "score" => 42})
    #   |> Repo.transaction()

    {:ok, %{id: user_data_id}} = Repo.insert(Data.new(datastore_users_id, %{"score" => 42}))

    # UserDataServices.create(%{user_id: user_id, data_id: user_data_id}) |> Repo.transaction()
    Repo.insert(UserData.new(%{user_id: user_id, data_id: user_data_id}))

    # # 2
    # {:ok, %{inserted_data: %{id: todolist1_id}}} =
    #   DataServices.create(env_id, %{
    #     "_datastore" => "todoList",
    #     "name" => "favorites",
    #     "_refBy" => [user_data_id]
    #   })
    #   |> Repo.transaction()
    {:ok, %{id: todolist1_id}} =
      Repo.insert(Data.new(datastore_todo_list_id, %{"name" => "favorites"}))

    Repo.insert(DataReferences.new(%{refs_id: todolist1_id, ref_by_id: user_data_id}))

    # # 3
    # {:ok, %{inserted_data: %{id: todolist2_id}}} =
    #   DataServices.create(env_id, %{
    #     "_datastore" => "todoList",
    #     "name" => "not fav",
    #     "_refBy" => [user_data_id]
    #   })
    #   |> Repo.transaction()
    {:ok, %{id: todolist2_id}} =
      Repo.insert(Data.new(datastore_todo_list_id, %{"name" => "not fav"}))

    Repo.insert(DataReferences.new(%{refs_id: todolist2_id, ref_by_id: user_data_id}))

    # # 4
    # {:ok, %{inserted_data: %{id: todo1_id}}} =
    #   DataServices.create(env_id, %{
    #     "_datastore" => "todos",
    #     "title" => "Faire la vaisselle",
    #     "_refBy" => [todolist1_id]
    #   })
    #   |> Repo.transaction()
    {:ok, %{id: todo1_id}} =
      Repo.insert(Data.new(datastore_todos_id, %{"title" => "Faire la vaisselle"}))

    Repo.insert(DataReferences.new(%{refs_id: todo1_id, ref_by_id: todolist1_id}))

    # # 5
    # {:ok, %{inserted_data: %{id: todo2_id}}} =
    #   DataServices.create(env_id, %{
    #     "_datastore" => "todos",
    #     "title" => "Faire la cuisine",
    #     "_refBy" => [todolist1_id]
    #   })
    #   |> Repo.transaction()
    {:ok, %{id: todo2_id}} =
      Repo.insert(Data.new(datastore_todos_id, %{"title" => "Faire la cuisine"}))

    Repo.insert(DataReferences.new(%{refs_id: todo2_id, ref_by_id: todolist1_id}))

    # # 6
    # {:ok, %{inserted_data: %{id: todo3_id}}} =
    #   DataServices.create(env_id, %{
    #     "_datastore" => "todos",
    #     "title" => "Faire le ménage",
    #     "nullField" => nil,
    #     "_refBy" => [todolist2_id]
    #   })
    #   |> Repo.transaction()
    {:ok, %{id: todo3_id}} =
      Repo.insert(
        Data.new(datastore_todos_id, %{"title" => "Faire le ménage", "nullField" => nil})
      )

    Repo.insert(DataReferences.new(%{refs_id: todo3_id, ref_by_id: todolist2_id}))

    # 7
    # {:ok, %{inserted_data: %{id: todo4_id}}} =
    #   DataServices.create(env_id, %{
    #     "_datastore" => "todos",
    #     "title" => ["Faire le ménage"],
    #     "nullField" => nil,
    #     "_refBy" => [todolist2_id]
    #   })
    #   |> Repo.transaction()
    {:ok, %{id: todo4_id}} =
      Repo.insert(
        Data.new(datastore_todos_id, %{"title" => ["Faire le ménage"], "nullField" => nil})
      )

    Repo.insert(DataReferences.new(%{refs_id: todo4_id, ref_by_id: todolist2_id}))

    {:ok,
     %{
       env_id: env_id,
       user_id: user_id,
       user_data_id: user_data_id,
       todolist1_id: todolist1_id,
       todolist2_id: todolist2_id,
       todo1_id: todo1_id,
       todo2_id: todo2_id,
       todo3_id: todo3_id,
       todo4_id: todo4_id
     }}
  end

  test "Base test, select all", %{
    user_data_id: user_data_id,
    todolist1_id: todolist1_id,
    todolist2_id: todolist2_id,
    todo1_id: todo1_id,
    todo2_id: todo2_id,
    todo3_id: todo3_id,
    todo4_id: todo4_id,
    env_id: env_id
  } do
    res =
      %{"$find" => %{}}
      |> Parser.from_json()
      |> EctoParser.to_ecto(env_id, user_data_id)
      |> Repo.all()

    assert Enum.count(res) == 7

    assert res
           |> Enum.map(fn e -> e["_id"] end)
           |> MapSet.new() ==
             MapSet.new([
               user_data_id,
               todolist1_id,
               todolist2_id,
               todo1_id,
               todo2_id,
               todo3_id,
               todo4_id
             ])
  end

  test "Select all wrong env_id", %{
    env_id: env_id,
    user_data_id: user_data_id
  } do
    res =
      %{"$find" => %{}}
      |> Parser.from_json()
      |> EctoParser.to_ecto(env_id + 1, user_data_id)
      |> Repo.all()

    assert Enum.empty?(res)
  end

  test "Select where datastore _users", %{
    user_id: user_id,
    user_data_id: user_data_id,
    todolist1_id: todolist1_id,
    todolist2_id: todolist2_id,
    env_id: env_id
  } do
    res =
      %{"$find" => %{"_datastore" => "_users"}}
      |> Parser.from_json()
      |> EctoParser.to_ecto(env_id, user_data_id)
      |> Repo.one()

    assert %{
             "score" => 42,
             "_datastore" => "_users",
             "_id" => ^user_data_id,
             "_refBy" => [],
             "_refs" => [^todolist1_id, ^todolist2_id],
             "_user" => %{"email" => "test@lenra.io", "id" => ^user_id}
           } = res
  end

  test "Select where datastore Todo", %{env_id: env_id, user_data_id: user_data_id} do
    res =
      %{"$find" => %{"_datastore" => "todos"}}
      |> Parser.from_json()
      |> EctoParser.to_ecto(env_id, user_data_id)
      |> Repo.all()

    assert Enum.count(res) == 4
  end

  test "Select with multi where", %{
    todo3_id: todo3_id,
    env_id: env_id,
    user_data_id: user_data_id
  } do
    # null value in data should stay
    # Empty _refs_id/_refBy should return empty array

    res =
      %{"$find" => %{"_datastore" => "todos", "_id" => todo3_id}}
      |> Parser.from_json()
      |> EctoParser.to_ecto(env_id, user_data_id)
      |> Repo.one()

    assert %{
             "title" => "Faire le ménage",
             "nullField" => nil,
             "_refs" => []
           } = res
  end

  test "Select with where on list of number", %{
    todolist1_id: todolist1_id,
    todolist2_id: todolist2_id,
    env_id: env_id,
    user_data_id: user_data_id
  } do
    res =
      %{"$find" => %{"_refs" => [todolist1_id, todolist2_id]}}
      |> Parser.from_json()
      |> EctoParser.to_ecto(env_id, user_data_id)
      |> Repo.one()

    assert %{
             "score" => 42,
             "_datastore" => "_users",
             "_user" => %{"email" => "test@lenra.io"}
           } = res
  end

  test "Select with where on id with @me", %{
    user_data_id: user_data_id,
    env_id: env_id
  } do
    res =
      %{"$find" => %{"_id" => "@me"}}
      |> Parser.from_json()
      |> EctoParser.to_ecto(env_id, user_data_id)
      |> Repo.one()

    assert %{
             "score" => 42,
             "_datastore" => "_users",
             "_user" => %{"email" => "test@lenra.io"},
             "_id" => ^user_data_id,
             "_refBy" => []
           } = res
  end

  test "Select with where on number", %{
    user_data_id: user_data_id,
    env_id: env_id
  } do
    res =
      %{"$find" => %{"_id" => user_data_id}}
      |> Parser.from_json()
      |> EctoParser.to_ecto(env_id, user_data_id)
      |> Repo.one()

    assert %{
             "score" => 42,
             "_datastore" => "_users",
             "_user" => %{"email" => "test@lenra.io"},
             "_id" => ^user_data_id,
             "_refBy" => []
           } = res
  end

  test "Select with in dot", %{
    user_data_id: user_data_id,
    env_id: env_id
  } do
    res =
      %{
        "$find" => %{
          "$and" => [
            %{"_datastore" => "todos"},
            %{
              "title" => %{
                "$in" => ["Faire la vaisselle", "Faire la cuisine", "Faire la sieste"]
              }
            }
          ]
        }
      }
      |> Parser.from_json()
      |> EctoParser.to_ecto(env_id, user_data_id)
      |> Repo.all()

    assert length(res) == 2
  end

  test "Select with contains", %{
    user_data_id: user_data_id,
    env_id: env_id,
    todolist1_id: todolist1_id,
    todo1_id: todo1_id,
    todo2_id: todo2_id
  } do
    res =
      %{
        "$find" => %{
          "$and" => [
            %{"_datastore" => "todos"},
            %{
              "_refBy" => %{
                "$contains" => todolist1_id
              }
            }
          ]
        }
      }
      |> Parser.from_json()
      |> EctoParser.to_ecto(env_id, user_data_id)
      |> Repo.all()

    [todo1 | [todo2 | _res]] = res
    # Get Todo1 & todo2
    ids = [todo1_id, todo2_id]
    assert length(res) == 2
    assert todo2["_id"] in ids
    assert todo1["_id"] in ids
  end

  test "Select with contains array", %{
    user_data_id: user_data_id,
    env_id: env_id,
    todo4_id: todo4_id
  } do
    res =
      %{
        "$find" => %{
          "$and" => [
            %{
              "_datastore" => "todos"
            },
            %{
              "title" => %{
                "$contains" => ["Faire le ménage"]
              }
            }
          ]
        }
      }
      |> Parser.from_json()
      |> EctoParser.to_ecto(env_id, user_data_id)
      |> Repo.all()

    [todo1 | _res] = res
    # Get Todo4
    assert length(res) == 1
    assert todo1["_id"] == todo4_id
  end

  test "Select with simple $or", %{
    user_data_id: user_data_id,
    env_id: env_id,
    todo2_id: todo2_id,
    todo3_id: todo3_id
  } do
    res =
      %{
        "$find" => %{
          "_datastore" => "todos",
          "$or" => [
            %{
              "title" => "Faire le ménage",
            }, %{
              "title" => "Faire la cuisine"
            }
          ]

        }
      }
      |> Parser.from_json()
      |> EctoParser.to_ecto(env_id, user_data_id)
      |> IO.inspect()
      |> Repo.all()

    assert length(res) == 2
    [todo2, todo3] = res
    assert todo2["_id"] == todo2_id
    assert todo3["_id"] == todo3_id

  end
end
