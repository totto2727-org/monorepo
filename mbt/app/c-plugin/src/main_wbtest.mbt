///|
test "c_plugin_app - exposes the package version" {
  inspect(c_plugin_app().version, content="0.2.0")
}
