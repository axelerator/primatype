module Primatype exposing (main)

import Browser
import Browser.Events exposing (onKeyDown)
import Html exposing (Html, button, div, h3, main_, pre, text)
import Html.Attributes exposing (class, classList, id)
import Html.Events exposing (onClick)
import Json.Decode as D
import Task
import Time exposing (Posix, millisToPosix, posixToMillis)


main = 
  Browser.element { init = init , update = update , subscriptions = subscriptions , view = view }


type Focus = OnMenu | OnLesson | OnResults

lesson0 =
    """import"""


init : () -> ( { focus : Focus, lesson : { typed : String, expected : String, good : String, bad : String, startedAt : Posix }, results : { secondsElapsed : Float, wpm : Float } }, Cmd msg )
init _ =
    ( { focus = OnMenu
      , lesson = { typed = "" , expected = lesson0
            , good = "" , bad = "" , startedAt = millisToPosix 0 }
      , results = { secondsElapsed = 0 , wpm = 0 }
      } , Cmd.none )


type Msg = ClickedStartLesson | KeyPressed Key | GotTimeToStart Posix | GotTimeToFinish Posix


update msg ({ lesson } as model) =
    case msg of
        GotTimeToStart time ->
            ( { model | lesson = { lesson | startedAt = time } , focus = OnLesson }
            , Cmd.none
            )

        GotTimeToFinish time -> ( calculateResult time model , Cmd.none)

        ClickedStartLesson -> ( model , Task.perform GotTimeToStart Time.now)

        KeyPressed key ->
            let
                pos = String.length lesson.typed
                expectedKey = String.slice pos (pos + 1) lesson.expected
            in
            checkIfFinished <|
                case key of
                    Character c ->
                        { model | lesson = typing expectedKey (String.fromChar c) lesson }

                    Control controlKey ->
                        case controlKey of
                            "Enter" -> { model | lesson = typing expectedKey "\n" lesson }

                            "Backspace" ->
                                { model | lesson = { lesson
                                            | typed = String.slice 0 -1 lesson.typed
                                            , good = String.slice 0 -1 lesson.good
                                            , bad = String.slice 0 -1 lesson.bad } }

                            _ -> model


calculateResult endTime model =
    let
        secondsElapsed = toFloat (posixToMillis endTime - posixToMillis model.lesson.startedAt) / 1000
        minutes = secondsElapsed / 60
        wordsTyped = (toFloat <| String.length model.lesson.typed) / 5.0
        wpm = wordsTyped / minutes
        results = { secondsElapsed = secondsElapsed , wpm = wpm }
    in
    { model | results = results , focus = OnResults }


checkIfFinished model =
    if String.length model.lesson.typed == String.length model.lesson.expected then
        ( model , Task.perform GotTimeToFinish Time.now)

    else
        ( model , Cmd.none)


typing expected actualKey lesson =
    let
        ( toGood, toBad ) =
            case (actualKey == expected, expected) of
              (True, "\n") -> ( "\n", "\n" )
              (True, _) -> ( actualKey, " " )
              (False, "\n") -> ( "\n", "⏎\n" )
              (False, _) -> ( " ", expected )
    in
    { lesson | typed = lesson.typed ++ actualKey
        , good = lesson.good ++ toGood , bad = lesson.bad ++ toBad }


subscriptions _ = onKeyDown <| D.map KeyPressed <| D.map toKey (D.field "key" D.string)


view ({ focus } as model) =
    main_ []
        [ viewMenu (focus /= OnMenu)
        , viewLesson (focus /= OnLesson) model.lesson
        , viewResults (focus /= OnResults) model.results ]


viewMenu inactive =
    div [ id "menu", classList [ ( "off-left", inactive ) ] ]
        [ text "Menu" , button [ onClick ClickedStartLesson ] [ text "Start lesson" ] ]


viewLesson inactive { expected, good, bad } =
    div [ id "lesson", classList [ ( "off-right", inactive ) ] ]
        [ pre [ class "expected" ] [ text expected ]
        , pre [ class "good" ] [ text good ]
        , pre [ class "bad" ] [ text bad ] ]


viewResults inactive { secondsElapsed, wpm } =
    div [ id "results", classList [ ( "off-right", inactive ) ] ]
        [ h3 [] [ text "Results" ]
        , div [] [ text "Total time: ", text (String.fromFloat secondsElapsed) ]
        , div [] [ text "WPM: ", text (String.fromFloat wpm) ]
        ]


type Key = Character Char | Control String


toKey string =
    case String.uncons string of
        Just ( char, "" ) -> Character char
        _ -> Control string
