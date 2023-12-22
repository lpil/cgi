// Thank you to Steven vanZyl for [plug_cgi][1], which was used as a
// reference. Why is there so little information on the CGI protcol online
// these days?
//
// [1]: https://github.com/rushsteve1/plug_cgi

import envoy
import gleam/io
import gleam/int
import gleam/dict
import gleam/list
import gleam/string
import gleam/result
import gleam/option
import gleam/http
import gleam/http/request.{type Request, Request}
import gleam/http/response.{type Response, Response}

pub type RequestError {
  MissingEnvironmentVariable(name: String)
}

pub fn main() {
  let request = load_request()
  let body = "Hello! You send me this request:\n\n" <> string.inspect(request)
  let response = Response(201, [#("content-type", "text/plain")], body)
  send_response(response)
}

// TODO: document
// TODO: test
pub fn send_response(response: Response(String)) -> Nil {
  let s = response.status
  io.println("status: " <> int.to_string(s) <> " " <> status_phrase(s))

  let l = string.byte_size(response.body)
  io.println("content-length: " <> int.to_string(l))

  list.each(response.headers, fn(header) {
    io.println(header.0 <> ": " <> header.1)
  })
  io.println("")
  io.println(response.body)
}

// TODO: document
// TODO: test
pub fn load_request() -> Request(BitArray) {
  let env = envoy.all()

  let method =
    env
    |> dict.get("REQUEST_METHOD")
    |> result.try(http.parse_method)
    |> result.unwrap(http.Get)

  let port =
    env
    |> dict.get("SERVER_PORT")
    |> result.try(int.parse)
    |> option.from_result

  let scheme = case dict.get(env, "HTTPS") {
    Ok(_) -> http.Https
    _ -> http.Http
  }

  let query = option.from_result(dict.get(env, "QUERY_STRING"))
  let host =
    dict.get(env, "SERVER_NAME")
    |> result.unwrap("localhost")

  let path =
    dict.get(env, "PATH_INFO")
    |> result.unwrap("/")

  let headers =
    env
    |> dict.to_list
    |> list.filter_map(fn(pair) {
      case pair.0 {
        "CONTENT_TYPE" -> Ok(#("content-type", pair.1))
        "CONTENT_LENGTH" -> Ok(#("content-length", pair.1))
        "HTTP_" <> name ->
          Ok(#(string.replace(string.lowercase(name), "_", "-"), pair.1))
        _ -> Error(Nil)
      }
    })

  // TODO: decide what to do RE the body.
  let body = <<>>

  Request(
    method: method,
    headers: headers,
    body: body,
    scheme: scheme,
    host: host,
    port: port,
    path: path,
    query: query,
  )
}

fn status_phrase(status: Int) -> String {
  case status {
    100 -> "Continue"
    101 -> "Switching Protocols"
    102 -> "Processing"
    103 -> "Early Hints"
    200 -> "OK"
    201 -> "Created"
    202 -> "Accepted"
    203 -> "Non-Authoritative Information"
    204 -> "No Content"
    205 -> "Reset Content"
    206 -> "Partial Content"
    207 -> "Multi-Status"
    208 -> "Already Reported"
    226 -> "IM Used"
    300 -> "Multiple Choices"
    301 -> "Moved Permanently"
    302 -> "Found"
    303 -> "See Other"
    304 -> "Not Modified"
    305 -> "Use Proxy"
    306 -> "Switch Proxy"
    307 -> "Temporary Redirect"
    308 -> "Permanent Redirect"
    400 -> "Bad Request"
    401 -> "Unauthorized"
    402 -> "Payment Required"
    403 -> "Forbidden"
    404 -> "Not Found"
    405 -> "Method Not Allowed"
    406 -> "Not Acceptable"
    407 -> "Proxy Authentication Required"
    408 -> "Request Timeout"
    409 -> "Conflict"
    410 -> "Gone"
    411 -> "Length Required"
    412 -> "Precondition Failed"
    413 -> "Request Entity Too Large"
    414 -> "Request-URI Too Long"
    415 -> "Unsupported Media Type"
    416 -> "Requested Range Not Satisfiable"
    417 -> "Expectation Failed"
    418 -> "I'm a teapot"
    421 -> "Misdirected Request"
    422 -> "Unprocessable Entity"
    423 -> "Locked"
    424 -> "Failed Dependency"
    425 -> "Too Early"
    426 -> "Upgrade Required"
    428 -> "Precondition Required"
    429 -> "Too Many Requests"
    431 -> "Request Header Fields Too Large"
    451 -> "Unavailable For Legal Reasons"
    500 -> "Internal Server Error"
    501 -> "Not Implemented"
    502 -> "Bad Gateway"
    503 -> "Service Unavailable"
    504 -> "Gateway Timeout"
    505 -> "HTTP Version Not Supported"
    506 -> "Variant Also Negotiates"
    507 -> "Insufficient Storage"
    508 -> "Loop Detected"
    510 -> "Not Extended"
    511 -> "Network Authentication Required"
    _ -> ""
  }
}
