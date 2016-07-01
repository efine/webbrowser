-module(webbrowser).

%% API exports
-export([
         open/1,
         open_browser/2,
         browsers/0,
         browsers/1,
         browser/2
        ]).

-type browser() :: default | firefox | internet_explorer |
                   chrome | opera | safari.
-type url() :: string().
-type result() :: ok | {error, {atom(), term()}}.
-type app() :: string() | default.

%%====================================================================
%% API functions
%%====================================================================
%%@ @doc
%%% Open URLs in the web browsers available on a platform
%%%
%%% Inspired by the [webbrowser](https://github.com/amodm/webbrowser-rs) Rust library.
%%%
%%% # Examples
%%%
%%% ```
%%% ok = webbrowser:open("http://github.com")
%%% ```
%%%
%%% Currently state of platform support is:
%%%
%%% * macos => default, as well as browsers listed by calling
%%%   `maps:get(apps, maps:get(webbrowser:browsers(macos)).`
%%% * windows => default browser only
%%% * linux => default browser only
%%% * android => not supported right now
%%% * ios => not supported right now
%%%
%%% Important note:
%%%
%%% * This library requires availability of browsers and a graphical environment during runtime
%%% * `make test` will actually open the browser locally

%%% Opens the URL on the default browser of this platform
%%%
%%% Returns ok so long as the browser invocation was successful. An error is returned only if
%%% there was an error in running the command, or if the browser was not found
%%%
%%% # Examples
%%% ```
%%% ok = webbrowser:open("http://github.com").
%%% ```
%%% @end
-spec open(Url) -> Result
    when Url :: url(), Result :: result().
open(Url) ->
    open_browser(default, Url).

%%% @doc
%%% Opens the specified URL on the specific browser (if available) requested. Return semantics are
%%% the same as for open.1.
%%%
%%% # Examples
%%% ```
%%% ok = webbrowser:open_browser(firefox, "http://github.com").
%%% ```
%%% @end
-spec open_browser(Browser, Url) -> Result
    when Browser :: browser(), Url :: url(), Result :: result().
open_browser(Browser, Url) ->
    case browser(os_type(), Browser) of
        {ok, {App, Cmd}} ->
            Cmd(App, Url),
            ok;
        {error, {unsupported_os, OS}} ->
            {error, {not_found,
                     lists:flatten(io_lib:format(
                       "Platform ~p not yet supported by "
                       "this library", [OS]))}
            };
        {error, {unsupported_browser, _Br}} ->
            {error, {not_found,
                     "Only the default browser is supported "
                     "on this platform right now"}};
        Err ->
            Err
    end.

os_type() -> os_type(os:type()).

os_type({unix, darwin}) -> macos;
os_type({unix, linux})  -> linux;
os_type({win32, _})     -> win32;
os_type(_)              -> unsupported.

browsers() ->
    #{macos  => browsers(macos),
      linux  => browsers(linux),
      win32  => browsers(win32)}.

browsers(macos) ->
    #{cmd => fun(default, Url) ->
                     os:cmd("open " ++ Url);
                (App, Url) ->
                     os:cmd(string:join(["open", "-a", App, Url]))
             end,
      app => #{firefox => "Firefox",
               chrome  => "Google Chrome",
               opera   => "Opera",
               safari  => "Safari"
              }
     };
browsers(linux) ->
    #{cmd => fun(default, Url) ->
                     os:cmd("xdg-open " ++ Url)
             end,
      app => #{default => default}
     };
browsers(win32) ->
    #{cmd => fun(default, Url) ->
                     os:cmd(string:join(["start", "link", Url]))
             end,
      app => #{default => default}
     }.

-spec browser(OS, Browser) -> Result
    when OS :: atom(), Browser :: atom(),
         Result :: {ok, {App, Cmd}} | {error, term()},
         App :: app(),
         Cmd :: fun((App :: app(), Url :: url()) -> string()).
browser(OS, Browser) ->
    case maps:get(OS, browsers(), undefined) of
        undefined ->
            {error, {unsupported_os, OS}};
        #{cmd := CmdFun, app := AppMap} ->
            case maps:get(Browser, AppMap, undefined) of
                AppName when is_list(AppName) ->
                    {ok, {AppName, CmdFun}};
                default ->
                    {ok, {default, CmdFun}};
                undefined ->
                    {error, {unsupported_browser, Browser}}
            end
    end.

