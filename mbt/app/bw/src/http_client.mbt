///|
let base_url = "https://api.cloudflare.com/client/v4/accounts"

///|
fn endpoint(account_id : String, path : String) -> String {
  "\{base_url}/\{account_id}/browser-rendering\{path}"
}

///|
async fn post_json(
  account_id : String,
  api_token : String,
  path : String,
  body : Json,
) -> (Int, String, &@io.Data) {
  let headers = {
    "Authorization": "Bearer \{api_token}",
    "Content-Type": "application/json",
  }
  let (response, data) = @http.post(endpoint(account_id, path), body, headers~)
  (response.code, response.reason, data)
}

///|
async fn get_json(
  account_id : String,
  api_token : String,
  path : String,
) -> (Int, String, &@io.Data) {
  let headers = { "Authorization": "Bearer \{api_token}" }
  let (response, data) = @http.get(endpoint(account_id, path), headers~)
  (response.code, response.reason, data)
}

///|
fn ensure_success(code : Int, reason : String, data : &@io.Data) -> Unit raise {
  guard code is (200..<300) else {
    raise Failure::Failure(
      "Cloudflare API returned \{code} \{reason}: \{data.text()}",
    )
  }
}
