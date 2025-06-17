defmodule Etl.FileStreamerTest do
  use ExUnit.Case, async: true
  alias Common.Model
  alias EtlPipeline.Etl.FileStreamer
  alias Common.RowInfo

  import Mox
  defmock(S3Mock, for: Common.S3.S3Behaviour)

  setup :verify_on_exit!

  setup do
    Application.put_env(:common, :s3, S3Mock)
    :ok
  end

  @csv_data """
  locn_nbr,shipper_id,barcode,weight,hazmat,length,width,height,address1,city,country,postal_code,state_province,delivery_method,locnType
  LOC001,SH123,BC001,2.5,false,10,5,3,123 Main St,CityA,US,12345,CA,GND,Warehouse
  """

  @s3_file_data """
  10022|00501|NY|1|2|2|Y|Y
  10022|00544|NY|1|2|2|Y|Y
  10022|00601|PR|5|6|45
  10022|00602|PR|5|6|45
  10022|00603|PR|5|6|45
  10022|00604|PR|5|6|45
  10022|00605|PR|5|6|45
  10022|00606|PR|5|6|45
  10022|00610|PR|5|6|45
  10022|00611|PR|5|6|45
  10022|00612|PR|5|6|45
  10022|00613|PR|5|6|45
  10022|00614|PR|5|6|45
  """

  test "stream_file/2 parse csv correctly" do
    File.mkdir_p!("test-data")
    file = "test-data/sample_dest.csv"
    origin = "WH1"

    File.write!(file, @csv_data)

    [row_info] =
      FileStreamer.stream_file(file, origin)
      |> Enum.to_list()

    assert %RowInfo{shipper_id: "SH123", origin: "WH1"} = row_info
  end

  test "stream_s3_bucket/1 stream file contents in S3 bucket" do
    S3Mock
    |> expect(:get_object, fn "tnt-automation-test", "file1.txt" ->
      @s3_file_data
      |> String.split("\n", trim: true)
      |> Stream.map(& &1)
    end)

    result =
      FileStreamer.stream_s3_bucket("file1.txt")
      |> Enum.to_list()

    assert(length(result) == 13)

    assert match?(
             %Model{
               origin: "10022",
               destination: "00501",
               expected_transit_day: 1,
               shipper: "file1"
             },
             Enum.at(result, 0)
           )
  end
end
