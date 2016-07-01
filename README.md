# webbrowser

Open a URL in one of the web browsers available on a platform.

Inspired by the [webbrowser](https://github.com/amodm/webbrowser-rs) Rust library.

# Examples

```
ok = webbrowser:open("http://github.com")
```

Currently state of platform support is:

* macos => default, as well as browsers listed by calling
  `maps:get(app, webbrowser:browsers(macos)).`
* windows => default browser only
* linux => default browser only
* android => not supported right now
* ios => not supported right now

# Important note

* This library requires availability of browsers and a graphical environment
  during runtime.
* `make test` will actually open the default browser locally on github.com.

# Build

    $ make
