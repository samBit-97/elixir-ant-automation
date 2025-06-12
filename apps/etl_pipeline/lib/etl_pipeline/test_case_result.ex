defmodule EtlPipeline.TestCaseResult do
  use Ecto.Schema
  import Ecto.Changeset

  schema "test_case_result" do
    field(:shipper_id, :string)
    field(:origin, :string)
    field(:destination, :string)
    field(:expected_transit_days, :integer)
    field(:actual_transit_days, :integer)
    field(:success, :boolean)
    field(:request_payload, :map)
    field(:response_payload, :map)
    field(:time_taken_ms, :integer)

    # inserted_at, updated_at
    timestamps()
  end

  def changeset(result, attrs) do
    result
    |> cast(attrs, [
      :shipper_id,
      :origin,
      :destination,
      :expected_transit_days,
      :actual_transit_days,
      :success,
      :request_payload,
      :response_payload,
      :time_taken_ms
    ])
    |> validate_required([
      :shipper_id,
      :origin,
      :destination,
      :expected_transit_days,
      :actual_transit_days,
      :success,
      :request_payload,
      :response_payload,
      :time_taken_ms
    ])
  end
end
