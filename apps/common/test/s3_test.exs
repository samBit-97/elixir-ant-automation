defmodule Common.S3Test do
  use ExUnit.Case, async: true
  import Mock

  alias Common.S3

  describe "list_keys/2" do
    test "returns stream of keys on success" do
      bucket = "test-bucket"
      mock_objects = [%{key: "file1.txt"}, %{key: "file2.txt"}]
      
      with_mock ExAws, [:passthrough], 
        stream!: fn _ -> mock_objects end do
        
        result = S3.list_keys(bucket) |> Enum.to_list()
        
        assert result == ["file1.txt", "file2.txt"]
        assert_called ExAws.S3.list_objects_v2(bucket, [])
      end
    end

    test "passes opts to list_objects_v2" do
      bucket = "test-bucket"
      opts = [prefix: "folder/"]
      
      with_mock ExAws, [:passthrough], 
        stream!: fn _ -> [] end do
        
        S3.list_keys(bucket, opts) |> Enum.to_list()
        
        assert_called ExAws.S3.list_objects_v2(bucket, opts)
      end
    end

    test "reraises exception on error" do
      bucket = "test-bucket"
      
      with_mock ExAws, [:passthrough], 
        stream!: fn _ -> raise "S3 error" end do
        
        assert_raise RuntimeError, "S3 error", fn ->
          S3.list_keys(bucket) |> Enum.to_list()
        end
      end
    end
  end

  describe "get_object/2" do
    test "returns stream of object data on success" do
      bucket = "test-bucket"
      key = "file.txt"
      mock_data = ["chunk1", "chunk2"]
      
      with_mock ExAws, [:passthrough], 
        stream!: fn _ -> mock_data end do
        
        result = S3.get_object(bucket, key) |> Enum.to_list()
        
        assert result == ["chunk1", "chunk2"]
        assert_called ExAws.S3.download_file(bucket, key, :memory)
      end
    end

    test "reraises exception on error" do
      bucket = "test-bucket"
      key = "file.txt"
      
      with_mock ExAws, [:passthrough], 
        stream!: fn _ -> raise "Download error" end do
        
        assert_raise RuntimeError, "Download error", fn ->
          S3.get_object(bucket, key) |> Enum.to_list()
        end
      end
    end
  end

  describe "list_objects/2" do
    test "returns {:ok, objects} on success" do
      bucket = "test-bucket"
      mock_response = %{contents: [%{key: "file1.txt"}, %{key: "file2.txt"}]}
      
      with_mock ExAws, [:passthrough], 
        request: fn _ -> {:ok, mock_response} end do
        
        result = S3.list_objects(bucket)
        
        assert {:ok, objects} = result
        assert length(objects) == 2
        assert_called ExAws.S3.list_objects_v2(bucket, [])
      end
    end

    test "passes opts to list_objects_v2" do
      bucket = "test-bucket"
      opts = [prefix: "folder/"]
      
      with_mock ExAws, [:passthrough], 
        request: fn _ -> {:ok, %{contents: []}} end do
        
        S3.list_objects(bucket, opts)
        
        assert_called ExAws.S3.list_objects_v2(bucket, opts)
      end
    end

    test "returns {:error, reason} on AWS error" do
      bucket = "test-bucket"
      error_reason = "AccessDenied"
      
      with_mock ExAws, [:passthrough], 
        request: fn _ -> {:error, error_reason} end do
        
        result = S3.list_objects(bucket)
        
        assert {:error, ^error_reason} = result
      end
    end

    test "returns {:error, message} on exception" do
      bucket = "test-bucket"
      
      with_mock ExAws, [:passthrough], 
        request: fn _ -> raise "Network error" end do
        
        result = S3.list_objects(bucket)
        
        assert {:error, "Network error"} = result
      end
    end
  end
end