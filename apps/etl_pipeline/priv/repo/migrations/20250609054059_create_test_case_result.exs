defmodule EtlPipeline.Repo.Migrations.CreateTestCaseResult do
  use Ecto.Migration

def change do
    create table(:test_case_result) do
      add :shipper_id, :string
      add :origin, :string
      add :destination, :string
      add :expected_transit_days, :integer
      add :actual_transit_days, :integer
      add :success, :boolean
      add :request_payload, :map
      add :response_payload, :map
      add :time_taken_ms, :integer

      timestamps()
    end

    # Indexes for fast LiveView grouping
    create index(:test_case_result, [:shipper_id])
    create index(:test_case_result, [:origin])
    create index(:test_case_result, [:destination])
    create index(:test_case_result, [:success])
  end
end
