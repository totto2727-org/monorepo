///|
async test "array option appends and parses repeated values" {
  let values = ints("value", required=true)
  let captured : Ref[Array[Int]] = Ref([])
  let app = cli(name="test", commands=[
    command(
      name="collect",
      options=[values],
      run=Some(ctx => captured.val = ctx.get_ints_required(values)),
    ),
  ])
  app.run(
    argv=Some(["collect", "--value", "1", "--value", "2", "--value", "3"]),
  )
  inspect(captured.val.length(), content="3")
  inspect(captured.val[0], content="1")
  inspect(captured.val[1], content="2")
  inspect(captured.val[2], content="3")
}

///|
async test "scalar option rejects repeated values" {
  let value = int("value")
  let called = Ref(false)
  let app = cli(name="test", commands=[
    command(
      name="collect",
      options=[value],
      run=Some(fn(_ctx) { called.val = true }),
    ),
  ])
  let mut raised = false
  app.run(argv=Some(["collect", "--value", "1", "--value", "2"])) catch {
    _ => raised = true
  }
  inspect(raised, content="true")
  inspect(called.val, content="false")
}
