defmodule Common.HttpoisonClientTest do
  use ExUnit.Case, async: true
  import Mock

  alias Common.HttpoisonClient

  describe "post/4" do
    test "delegates to HTTPoison.post/4" do
      with_mock HTTPoison, [:passthrough],
        post: fn _, _, _, _ -> {:ok, %HTTPoison.Response{}} end do
        url = "https://example.com"
        body = "test body"
        headers = [{"Content-Type", "application/json"}]
        opts = [timeout: 5000]

        HttpoisonClient.post(url, body, headers, opts)

        assert_called(HTTPoison.post(url, body, headers, opts))
      end
    end

    test "returns success response from HTTPoison" do
      response = %HTTPoison.Response{status_code: 200, body: "success"}

      with_mock HTTPoison, [:passthrough], post: fn _, _, _, _ -> {:ok, response} end do
        result = HttpoisonClient.post("https://example.com", "body", [], [])

        assert {:ok, ^response} = result
      end
    end

    test "returns error response from HTTPoison" do
      error = %HTTPoison.Error{reason: :timeout}

      with_mock HTTPoison, [:passthrough], post: fn _, _, _, _ -> {:error, error} end do
        result = HttpoisonClient.post("https://example.com", "body", [], [])

        assert {:error, ^error} = result
      end
    end
  end
end

