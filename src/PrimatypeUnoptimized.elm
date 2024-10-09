module Primatype exposing (Focus(..), Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Browser.Events exposing (onKeyDown)
import Html exposing (Html, button, div, h3, main_, pre, text)
import Html.Attributes exposing (class, classList, id)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import String exposing (fromFloat, length)
import Task
import Time exposing (Posix, millisToPosix, posixToMillis)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { focus : Focus
    , lesson : Lesson
    , results : Results
    }


type alias Results =
    { secondsElapsed : Float
    , wpm : Float
    }


type alias Lesson =
    { typed : String
    , expected : String
    , good : String
    , bad : String
    , startedAt : Posix
    }


type Focus
    = OnMenu
    | OnLesson
    | OnResults


lesson0 : String
lesson0 =
    """import"""


init : () -> ( Model, Cmd Msg )
init _ =
    ( { focus = OnMenu
      , lesson =
            { typed = ""
            , expected = lesson0
            , good = ""
            , bad = ""
            , startedAt = millisToPosix 0
            }
      , results =
            { secondsElapsed = 0
            , wpm = 0
            }
      }
    , Cmd.none
    )


type Msg
    = ClickedStartLesson
    | KeyPressed Key
    | GotTimeToStart Posix
    | GotTimeToFinish Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ lesson } as model) =
    case msg of
        GotTimeToStart time ->
            ( { model
                | lesson = { lesson | startedAt = time }
                , focus = OnLesson
              }
            , Cmd.none
            )

        GotTimeToFinish time ->
            ( calculateResult time model
            , Cmd.none
            )

        ClickedStartLesson ->
            ( model
            , Task.perform GotTimeToStart Time.now
            )

        KeyPressed key ->
            let
                pos =
                    length lesson.typed

                expectedKey =
                    String.slice pos (pos + 1) lesson.expected
            in
            checkIfFinished <|
                case key of
                    Character c ->
                        { model | lesson = typing expectedKey (String.fromChar c) lesson }

                    Control controlKey ->
                        case controlKey of
                            "Enter" ->
                                { model | lesson = typing expectedKey "\n" lesson }

                            "Backspace" ->
                                { model
                                    | lesson =
                                        { lesson
                                            | typed = String.slice 0 -1 lesson.typed
                                            , good = String.slice 0 -1 lesson.good
                                            , bad = String.slice 0 -1 lesson.bad
                                        }
                                }

                            _ ->
                                model


calculateResult : Posix -> Model -> Model
calculateResult endTime model =
    let
        secondsElapsed =
            toFloat (posixToMillis endTime - posixToMillis model.lesson.startedAt) / 1000

        minutes =
            secondsElapsed / 60

        wordsTyped =
            (toFloat <| length model.lesson.typed) / 5.0

        wpm =
            wordsTyped / minutes

        results =
            { secondsElapsed = secondsElapsed
            , wpm = wpm
            }
    in
    { model
        | results = results
        , focus = OnResults
    }


checkIfFinished : Model -> ( Model, Cmd Msg )
checkIfFinished model =
    if length model.lesson.typed == length model.lesson.expected then
        ( model
        , Task.perform GotTimeToFinish Time.now
        )

    else
        ( model
        , Cmd.none
        )


typing : String -> String -> Lesson -> Lesson
typing expected actualKey lesson =
    let
        ( toGood, toBad ) =
            if actualKey == expected then
                if expected == "\n" then
                    ( "\n", "\n" )

                else
                    ( actualKey, " " )

            else if expected == "\n" then
                ( "\n", "⏎\n" )

            else
                ( " ", expected )
    in
    { lesson
        | typed = lesson.typed ++ actualKey
        , good = lesson.good ++ toGood
        , bad = lesson.bad ++ toBad
    }


subscriptions : Model -> Sub Msg
subscriptions _ =
    onKeyDown <| Decode.map KeyPressed keyDecoder


view : Model -> Html Msg
view ({ focus } as model) =
    main_ []
        [ viewMenu (focus /= OnMenu)
        , viewLesson (focus /= OnLesson) model.lesson
        , viewResults (focus /= OnResults) model.results
        ]


viewMenu : Bool -> Html Msg
viewMenu inactive =
    div [ id "menu", classList [ ( "off-left", inactive ) ] ]
        [ text "Menu"
        , button [ onClick ClickedStartLesson ] [ text "Start lesson" ]
        ]


viewLesson : Bool -> Lesson -> Html Msg
viewLesson inactive { expected, good, bad } =
    div [ id "lesson", classList [ ( "off-right", inactive ) ] ]
        [ pre [ class "expected" ] [ text expected ]
        , pre [ class "good" ] [ text good ]
        , pre [ class "bad" ] [ text bad ]
        ]


viewResults : Bool -> Results -> Html Msg
viewResults inactive { secondsElapsed, wpm } =
    div [ id "results", classList [ ( "off-right", inactive ) ] ]
        [ h3 [] [ text "Results" ]
        , div [] [ text "Total time: ", text (fromFloat secondsElapsed) ]
        , div [] [ text "WPM: ", text (fromFloat wpm) ]
        ]


type Key
    = Character Char
    | Control String


keyDecoder : Decode.Decoder Key
keyDecoder =
    Decode.map toKey (Decode.field "key" Decode.string)


toKey : String -> Key
toKey string =
    case String.uncons string of
        Just ( char, "" ) ->
            Character char

        _ ->
            Control string
