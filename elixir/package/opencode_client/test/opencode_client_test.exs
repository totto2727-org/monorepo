defmodule OpencodeClientTest do
  use ExUnit.Case

  describe "generated OpenAPI client" do
    test "exports generated session operations" do
      assert {:module, OpencodeClient.Generated.Session} = Code.ensure_loaded(OpencodeClient.Generated.Session)

      assert function_exported?(OpencodeClient.Generated.Session, :session_create, 2)
      assert function_exported?(OpencodeClient.Generated.Session, :session_prompt_async, 3)
      assert function_exported?(OpencodeClient.Generated.Session, :session_delete, 2)
    end
  end
end
