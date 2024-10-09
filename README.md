# Primatype - A touch typing trainer SPA in less than 100 lines

This is the result of a [live stream](https://youtu.be/HzoUz9wH5E8?si=Y7IhykB_zQqxL9Wd) of less than two hours. It demonstrates
that a simple touch typing training app can be written in Elm without third
party dependencies in very little time and code.

[![live stream recording](https://img.youtube.com/vi/HzoUz9wH5E8/0.jpg)](https://youtu.be/HzoUz9wH5E8)

- [Live demo](https://blog.axelerator.de/primatype)
- [Source code](src/Primatype.elm) 98 LOC version
  However to get to less than 100 lines one has to abandon the good practices
  and the unfified code formatter
- [Unoptimized code](src/PrimatypeUnoptimized.elm)
  Properly annotated and formatted code

## How to use

After you've cloned the repo, open the `dist/index.html` in your browser 
you should see the code in action.

If you want to make changes to the code you can edit the `src/Primatype.elm` and
and recompile with (of course you need to [install Elm](https://guide.elm-lang.org/install/elm) first, but it is *really* easy).

```
elm make src/Primatype.elm --output=dist/primatype.js
```

or if you want to continously watch for changes and automatically recompile 
(you have to install [fswatch](https://emcrisostomo.github.io/fswatch/getting.html):

```
fswatch -o1 src/Primatype.elm | xargs -n1 -I {} -- elm make src/Primatype.elm --output=dist/primatype.js
```

