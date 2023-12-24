-module(cgi_ffi).
-export([read_body_sync/1]).

read_body_sync(Length) ->
    try
      io:get_chars(standard_io, "", Length)
    catch
      _:_ -> <<>>
    end.
