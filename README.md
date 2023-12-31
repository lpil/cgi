# cgi

Common Gateway Interface (CGI) in Gleam.

[![Package Version](https://img.shields.io/hexpm/v/cgi)](https://hex.pm/packages/cgi)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/cgi/)

CGI is not commonly used these days, but there scenarios where it is still a
good choice. As CGI programs only run when there is a request to handle they do
not use any system resources when there is no traffic. This makes them very
efficient for low traffic websites.

It also make deployment really simple! Just copy the new version of the
compiled CGI program onto the server and it'll be used for future requests.

```sh
gleam add cgi
```
```gleam
import cgi
import gleam/string
import gleam/http/response.{Response}

pub fn main() {
  use request <- cgi.handle_request
  let headers = [#("content-type", "text/plain")]
  let body = "Hello! You send me this request:\n\n" <> string.inspect(request)
  Response(201, headers, body)
}
```

For your CGI server to run your program you may wish to [compile your Gleam
program to an escript][gleescript] if using the Erlang target, or bundling it
into a single JavaScript file if using the JavaScript target.

[gleescript]: https://github.com/lpil/gleescript

Further documentation can be found at <https://hexdocs.pm/cgi>.

Thank you to Steven vanZyl for [plug_cgi][1], which was used as a
reference. Why is there so little information on the CGI protcol online
these days?

[1]: https://github.com/rushsteve1/plug_cgi
