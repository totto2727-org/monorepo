defmodule OpencodeClientTest do
  use ExUnit.Case

  describe "generated OpenAPI client" do
    test "exports generated session operations" do
      assert {:module, OpencodeClient.Generated.Session} = Code.ensure_loaded(OpencodeClient.Generated.Session)

      assert function_exported?(OpencodeClient.Generated.Session, :session_create, 2)
      assert function_exported?(OpencodeClient.Generated.Session, :session_prompt_async, 3)
      assert function_exported?(OpencodeClient.Generated.Session, :session_delete, 2)
    end

    test "provides generated client transport" do
      assert {:module, OpencodeClient.Generated.Client} = Code.ensure_loaded(OpencodeClient.Generated.Client)

      assert function_exported?(OpencodeClient.Generated.Client, :request, 1)
    end

    test "provides SSE event stream backed by ReqServerSentEvents" do
      assert {:module, OpencodeClient.EventStream} = Code.ensure_loaded(OpencodeClient.EventStream)

      assert function_exported?(OpencodeClient.EventStream, :stream, 1)

      frame = ReqServerSentEvents.Frame.parse(~s(event: session.idle\ndata: {"type":"session.idle"}))

      assert %ReqServerSentEvents.Frame{event: "session.idle", data: ~s({"type":"session.idle"})} = frame
    end
  end
end
