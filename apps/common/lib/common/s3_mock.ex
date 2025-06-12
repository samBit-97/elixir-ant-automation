defmodule Common.S3Mock do
  @behaviour Common.S3.S3Behaviour

  def bucket do
    "tnt-automation-test"
  end

  def list_keys(_bucket, _opts) do
    [
      "file1.txt",
      "file2.txt",
      "file3.txt",
      "file4.txt"
    ]
  end
end
