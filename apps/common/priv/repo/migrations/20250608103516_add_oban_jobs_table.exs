defmodule Common.Repo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  def change do

  end

  def up do
    Oban.Migrations.up(version: 11)
  end

  def down do
    Oban.Migrations.down(version: 0)
  end
end