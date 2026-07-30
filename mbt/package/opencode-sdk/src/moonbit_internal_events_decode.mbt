// OpenCode's canonical JSONL event mapping:
// https://github.com/anomalyco/opencode/blob/1e17856ba4b5b052650c8115060852f3f023844e/packages/opencode/src/cli/cmd/run.ts#L678-L794

///|
fn moonbit_internal_thread_event_from_json(
  json : Json,
) -> ThreadEvent raise OpenCodeSdkError {
  let object = moonbit_internal_json_object(json, "thread event")
  let event_type = moonbit_internal_required_string(
    object, "type", "thread event",
  )
  let session_id = moonbit_internal_required_string(
    object, "sessionID", "thread event",
  )
  match event_type {
    "text" => {
      let part = moonbit_internal_json_object(
        moonbit_internal_required_json(object, "part", event_type),
        "\{event_type}.part",
      )
      Text({
        session_id,
        text: moonbit_internal_required_string(
          part,
          "text",
          "\{event_type}.part",
        ),
      })
    }
    "reasoning" => {
      let part = moonbit_internal_json_object(
        moonbit_internal_required_json(object, "part", event_type),
        "\{event_type}.part",
      )
      Reasoning({
        session_id,
        text: moonbit_internal_required_string(
          part,
          "text",
          "\{event_type}.part",
        ),
      })
    }
    "tool_use" => {
      let part = moonbit_internal_json_object(
        moonbit_internal_required_json(object, "part", event_type),
        "\{event_type}.part",
      )
      let state = moonbit_internal_json_object(
        moonbit_internal_required_json(part, "state", "\{event_type}.part"),
        "\{event_type}.part.state",
      )
      let status = match
        moonbit_internal_required_string(
          state,
          "status",
          "\{event_type}.part.state",
        ) {
        "completed" => ToolUseStatus::Completed
        "error" => ToolUseStatus::Failed
        status =>
          raise InvalidEvent(message="unsupported tool-use status: \{status}")
      }
      ToolUse({
        session_id,
        call_id: moonbit_internal_required_string(
          part,
          "callID",
          "\{event_type}.part",
        ),
        tool: moonbit_internal_required_string(
          part,
          "tool",
          "\{event_type}.part",
        ),
        status,
      })
    }
    "step_start" => StepStart({ session_id, })
    "step_finish" => {
      let part = moonbit_internal_json_object(
        moonbit_internal_required_json(object, "part", event_type),
        "\{event_type}.part",
      )
      let tokens = moonbit_internal_json_object(
        moonbit_internal_required_json(part, "tokens", "\{event_type}.part"),
        "\{event_type}.part.tokens",
      )
      let cache = moonbit_internal_json_object(
        moonbit_internal_required_json(
          tokens,
          "cache",
          "\{event_type}.part.tokens",
        ),
        "\{event_type}.part.tokens.cache",
      )
      StepFinish({
        session_id,
        reason: moonbit_internal_required_string(
          part,
          "reason",
          "\{event_type}.part",
        ),
        cost: moonbit_internal_required_double(
          part,
          "cost",
          "\{event_type}.part",
        ),
        usage: {
          input_tokens: moonbit_internal_required_int(
            tokens,
            "input",
            "\{event_type}.part.tokens",
          ),
          output_tokens: moonbit_internal_required_int(
            tokens,
            "output",
            "\{event_type}.part.tokens",
          ),
          reasoning_tokens: moonbit_internal_required_int(
            tokens,
            "reasoning",
            "\{event_type}.part.tokens",
          ),
          cache_read_tokens: moonbit_internal_required_int(
            cache,
            "read",
            "\{event_type}.part.tokens.cache",
          ),
          cache_write_tokens: moonbit_internal_required_int(
            cache,
            "write",
            "\{event_type}.part.tokens.cache",
          ),
        },
      })
    }
    "error" => {
      let error = moonbit_internal_json_object(
        moonbit_internal_required_json(object, "error", event_type),
        "\{event_type}.error",
      )
      let name = moonbit_internal_required_string(
        error,
        "name",
        "\{event_type}.error",
      )
      let message = @lens.object("data")
        .string("message")
        .get(Json::object(error)) catch {
          _ => name
        }
      StreamError({ session_id: Some(session_id), message })
    }
    _ =>
      raise InvalidEvent(message="unsupported thread event type: \{event_type}")
  }
}
