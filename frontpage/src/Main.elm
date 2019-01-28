port module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html
    exposing
        ( Html
        , br
        , button
        , div
        , h1
        , h2
        , img
        , text
        )
import Html.Attributes exposing (src, style)
import Html.Events exposing (onClick)
import Task
import Time exposing (Month(..))



---- MODEL ----


type alias Model =
    { labonow : Bool, labotimes : List Int, now : Time.Posix }


init : ( Model, Cmd Msg )
init =
    ( { labonow = False, labotimes = [], now = Time.millisToPosix 0 }, Cmd.none )



---- UPDATE ----


port logout : () -> Cmd msg


port laboin : () -> Cmd msg


port laboout : () -> Cmd msg


port updatelabonow : (Bool -> msg) -> Sub msg


port updatelabotimes : (List Int -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ updatelabonow UpdateLaboNow
        , updatelabotimes UpdateLaboTimes
        , Time.every 1000 SetCurrentTime
        ]


type Msg
    = Logout
    | LaboIn
    | LaboOut
    | UpdateLaboNow Bool
    | UpdateLaboTimes (List Int)
    | SetCurrentTime Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Logout ->
            ( model, logout () )

        LaboIn ->
            ( { model
                | labonow = True
                , labotimes =
                    model.labotimes
                        ++ [ Time.posixToMillis model.now ]
              }
            , laboin ()
            )

        LaboOut ->
            ( { model
                | labonow = False
                , labotimes =
                    model.labotimes
                        ++ [ Time.posixToMillis model.now ]
              }
            , laboout ()
            )

        UpdateLaboNow laboNow ->
            ( { model | labonow = laboNow }, Cmd.none )

        UpdateLaboTimes laboTimes ->
            ( { model | labotimes = laboTimes }, Cmd.none )

        SetCurrentTime time ->
            ( { model | now = time }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    let
        laboNowUpdateButton =
            if model.labonow then
                button [ onClick LaboOut ] [ text "らぼりだ" ]

            else
                button [ onClick LaboIn ] [ text "らぼいん" ]

        time2Str : Int -> Maybe String
        time2Str time =
            Just <| millisToTimeFormat time

        laboinTime =
            if model.labonow then
                List.reverse model.labotimes
                    |> List.head
                    |> Maybe.andThen time2Str
                    |> Maybe.withDefault "-"

            else if List.length model.labotimes >= 2 then
                List.reverse model.labotimes
                    |> List.drop 1
                    |> List.head
                    |> Maybe.andThen time2Str
                    |> Maybe.withDefault "-"

            else
                "-"

        labooutTime =
            if model.labonow then
                "-"

            else if List.length model.labotimes >= 1 then
                List.reverse model.labotimes
                    |> List.head
                    |> Maybe.andThen time2Str
                    |> Maybe.withDefault "-"

            else
                "-"
    in
    div []
        [ div []
            [ h1 [ style "display" "inline" ] [ text "らぼったあ" ]
            , button [ onClick Logout, style "display" "inline-block" ] [ text "ログアウト" ]
            ]
        , div []
            [ h2 [] [ text <| "らぼいん: " ++ laboinTime ]
            , h2 [] [ text <| "らぼりだ: " ++ labooutTime ]
            ]
        , laboNowUpdateButton
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }



-- Time Util --


millisToTimeFormat : Int -> String
millisToTimeFormat millis =
    let
        posix =
            Time.millisToPosix <| millis

        year =
            String.fromInt <| Time.toYear jst posix

        month =
            monthlyNumber <| Time.toMonth jst posix

        day =
            Time.toDay jst posix |> String.fromInt |> formatNumber

        hour =
            Time.toHour jst posix |> String.fromInt |> formatNumber

        minutes =
            Time.toMinute jst posix |> String.fromInt |> formatNumber

        seconds =
            Time.toSecond jst posix |> String.fromInt |> formatNumber
    in
    year ++ "-" ++ month ++ "-" ++ day ++ " " ++ hour ++ ":" ++ minutes ++ ":" ++ seconds


jst : Time.Zone
jst =
    let
        hour n =
            n * 60
    in
    Time.customZone (9 |> hour) []


monthlyNumber : Time.Month -> String
monthlyNumber month =
    case month of
        Jan ->
            "01"

        Feb ->
            "02"

        Mar ->
            "03"

        Apr ->
            "04"

        May ->
            "05"

        Jun ->
            "06"

        Jul ->
            "07"

        Aug ->
            "08"

        Sep ->
            "09"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"


formatNumber : String -> String
formatNumber num =
    if String.length num == 1 then
        "0" ++ num

    else
        num
