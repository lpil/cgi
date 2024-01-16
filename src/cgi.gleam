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

/// Load a CGI HTTP request and dispatch a response.
///
/// CGI works over stdin and stdout, so be sure your code does not use them for
/// this will likely cause the program to fail.
///
pub fn handle_request(f: fn(Request(BitArray)) -> Response(String)) -> Nil {
  use request <- with_request_body(load_request())
  f(request)
  |> send_response
}

/// Send a CGI HTTP response by printing it to stdout.
///
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

/// Load a CGI HTTP request from the environment.
///
/// The body of the request is not loaded. Use `read_body` or
/// `with_request_body` to load the body into the request.
///
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

/// Load the body of a request from stdin.
///
/// Due to how IO works in JavaScript may not always work on JavaScript,
/// especially if the body ir larger or on Windows. Consider using the
/// `with_request_body` function instead, which works on all platforms.
///
pub fn read_body(request: Request(BitArray)) -> Request(BitArray) {
  let body = read_body_sync(request_content_length(request))
  Request(..request, body: body)
}

fn request_content_length(request: Request(BitArray)) -> Int {
  request
  |> request.get_header("content-length")
  |> result.try(int.parse)
  |> result.unwrap(0)
}

@external(erlang, "cgi_ffi", "read_body_sync")
@external(javascript, "./cgi_ffi.mjs", "read_body_sync")
fn read_body_sync(length: Int) -> BitArray

/// Load the body of a request from stdin, running a callback with the
/// response with the body.
///
pub fn with_request_body(
  request: Request(BitArray),
  handle: fn(Request(BitArray)) -> anything,
) -> Nil {
  read_body_async(request_content_length(request), fn(body) {
    handle(Request(..request, body: body))
  })
}

@external(javascript, "./cgi_ffi.mjs", "read_body_async")
fn read_body_async(length: Int, handle: fn(BitArray) -> anything) -> Nil {
  let body = read_body_sync(length)
  handle(body)
  Nil
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
