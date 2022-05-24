defmodule QueryParser.Repo.Migrations.Data do
  use Ecto.Migration

  def change do
    create table(:environments) do
      timestamps()
    end

    create table(:users) do
      add(:email, :string, null: false, default: "test@lenra.io")

      timestamps()
    end

    create table(:datastores) do
      add(:environment_id, references(:environments), null: false)
      add(:name, :string)

      timestamps()
    end

    create(
      unique_index(:datastores, [:name, :environment_id],
        name: :datastores_name_application_id_index
      )
    )

    create table(:datas) do
      add(:datastore_id, references(:datastores, on_delete: :delete_all), null: false)
      add(:data, :map, null: false)

      timestamps()
    end

    create table(:user_datas) do
      add(:user_id, references(:users), null: false)
      add(:data_id, references(:datas), null: false)

      timestamps()
    end

    create(unique_index(:user_datas, [:user_id, :data_id], name: :user_datas_user_id_data_id))

    create table(:data_references) do
      add(:refs_id, references(:datas, on_delete: :delete_all), null: false)
      add(:ref_by_id, references(:datas, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(
      unique_index(:data_references, [:refs_id, :ref_by_id],
        name: :data_references_refs_id_ref_by_id
      )
    )

    execute("CREATE VIEW data_query_view AS
    SELECT
    d.id as id,
    ds.environment_id as environment_id,
    to_jsonb(d.data) ||
    jsonb_build_object(
      '_datastore', ds.name,
      '_id', d.id,
      '_refs', (SELECT COALESCE((SELECT jsonb_agg(dr.refs_id) FROM data_references as dr where ref_by_id = d.id GROUP BY dr.ref_by_id), '[]'::jsonb)),
      '_refBy', (SELECT COALESCE((SELECT jsonb_agg(dr.ref_by_id) FROM data_references as dr where refs_id = d.id GROUP BY dr.refs_id), '[]'::jsonb))
    ) ||
    CASE  WHEN ds.name != '_users' THEN '{}'::jsonb
          WHEN ds.name = '_users' THEN jsonb_build_object(
            '_user', (SELECT to_jsonb(_) FROM (SELECT u.email, u.id) AS _)
          )
    END
    as data
      FROM datas AS d
      INNER JOIN datastores AS ds ON (ds.id = d.datastore_id)
      LEFT JOIN user_datas AS ud ON (ud.data_id = d.id)
      LEFT JOIN users AS u ON (u.id = ud.user_id);")
  end
end
