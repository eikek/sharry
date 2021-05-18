# Contributing

Thank you very much for your interest in this project!

Contributions are possible by various means.


## Feedback

Feedback is very important and most welcome! You can currently use the
[issue tracker](https://github.com/eikek/sharry/issues/new) to leave
feedback. You can also reach me via matrix via `@eikek:matrix.org`.

If you find a feature request already filed, you can vote on it. I
tend to prefer most voted requests to those without much attention.


## Documentation

The website `https://eikek.github.io/sharry` contains the main
documentation and is also hosted in this repository. The sources are
in `/modules/microsite` folder. It is built using
[Jekyll](https://jekyllrb.com), a static site generator via the [sbt
microsite plugin](https://47degrees.github.io/sbt-microsites/).

If you want to contribute to the documentation: the main content is in
`/modules/microsite/docs` and sibling directories, while assets are in
`src/main/resources/microsite`. It is recommended to install
[nix](https://nixos.org/guides/install-nix.html) in order to not
fiddle with dependencies. If you have nix installed, you can create an
environment with all the tools available:

``` bash
$ nix-shell project/microsite.nix
```

Run the above in two terminals. Then in one, run `sbt` to generate the site:
```
$ sbt
sbt:sharry-root> microsite/makeMicrosite
```

In the other terminal run jekyll, for example:
```
$ jekyll serve -s modules/microsite/target/site --baseurl /sharry
```

If you use `nix-shell`, there is a shortcut `jekyll-sharry`.

Then see the site at `http://localhost:4000/sharry`. You need to run
`microsite/makeMicrosite` after a change and then reload the page.


## Code

Code is very welcome, too, of course.

If you want to work on something larger, please create an issue to
discuss it first.

The backend of sharry is written in [Scala](https://scala-lang.org)
using a pure functional style. It builds on great libraries from the
[typelevel](https://typelevel.org) ecosystem, i.e.
[cats](https://typelevel.org/cats), [fs2](https://fs2.io),
[doobie](https://tpolecat.github.io/doobie/) and
[http4s](https://http4s.org/).

The web frontend is written in [Elm](https://elm-lang.org), which is a
nice functional language that compiles to javascript. The frontend is
included in the server component. The CSS is currently provided by
[FomanticUI](https://fomantic-ui.com/). (I'm working to migrate it on
[tailwind](https://tailwindcss.com)).

The [development](https://eikek.github.io/sharry/doc/dev) page
contains some tips to get started.
