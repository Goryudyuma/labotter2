port module Main exposing (Model, Msg(..), init, main, update, view)

import Browser exposing (Document)
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



---- ROUTING ----


type Routing
    = MainPage



---- MODEL ----


type alias Period =
    { labointime : Int
    , laboouttime : Int
    }


type alias Model =
    { labointime : Int
    , labotimes : List Period
    , now : Time.Posix
    , routing : Routing
    }


init : ( Model, Cmd Msg )
init =
    ( { labointime = 0
      , labotimes = []
      , now = Time.millisToPosix 0
      , routing = MainPage
      }
    , Cmd.none
    )



---- UPDATE ----


port logout : () -> Cmd msg


port laboin : Int -> Cmd msg


port laboout : Int -> Cmd msg


port link_twitter : () -> Cmd msg


port updatelabotimes : (List Period -> msg) -> Sub msg


port updatelabointime : (Int -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ updatelabotimes UpdateLaboTimes
        , updatelabointime UpdateLaboinTime
        , Time.every 500 SetCurrentTime
        ]


type Msg
    = Logout
    | LaboIn
    | LaboOut
    | UpdateLaboTimes (List Period)
    | UpdateLaboinTime Int
    | SetCurrentTime Time.Posix
    | LinkTwitter
    | None


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Logout ->
            ( model, logout () )

        LaboIn ->
            ( { model
                | labointime = Time.posixToMillis model.now
                , labotimes =
                    model.labotimes
              }
            , laboin <| Time.posixToMillis model.now
            )

        LaboOut ->
            ( { model
                | labointime = 0
                , labotimes =
                    model.labotimes
                        ++ [ { labointime = model.labointime
                             , laboouttime = Time.posixToMillis model.now
                             }
                           ]
              }
            , laboout <| Time.posixToMillis model.now
            )

        UpdateLaboTimes laboTimes ->
            ( { model | labotimes = laboTimes }, Cmd.none )

        UpdateLaboinTime labointime ->
            ( { model | labointime = labointime }, Cmd.none )

        SetCurrentTime time ->
            ( { model | now = time }, Cmd.none )

        LinkTwitter ->
            ( model, link_twitter () )

        None ->
            ( model, Cmd.none )



---- VIEW ----


view : Model -> Document Msg
view model =
    let
        routing =
            case model.routing of
                MainPage ->
                    mainView
    in
    { title = "らぼったー2"
    , body = [ routing model ]
    }


mainView : Model -> Html Msg
mainView model =
    let
        laboNow : Bool
        laboNow =
            model.labointime /= 0

        laboNowUpdateButton =
            if laboNow then
                button [ onClick LaboOut ] [ text "らぼりだ" ]

            else
                button [ onClick LaboIn ] [ text "らぼいん" ]

        time2Str : Int -> Maybe String
        time2Str time =
            Just <| millisToTimeFormat time

        laboinTime : Maybe String
        laboinTime =
            if laboNow then
                time2Str model.labointime

            else
                case
                    model.labotimes
                        |> List.reverse
                        |> List.head
                of
                    Just t ->
                        t.labointime
                            |> time2Str

                    Nothing ->
                        Nothing

        laboinTimeStr : String
        laboinTimeStr =
            Maybe.withDefault "-" laboinTime

        labooutTime : Maybe String
        labooutTime =
            if laboNow then
                Nothing

            else
                case
                    model.labotimes
                        |> List.reverse
                        |> List.head
                of
                    Just t ->
                        t.laboouttime
                            |> time2Str

                    Nothing ->
                        Nothing

        labooutTimeStr : String
        labooutTimeStr =
            Maybe.withDefault "-" labooutTime
    in
    div
        []
        [ div []
            [ h1 [ style "display" "inline" ] [ text "らぼったあ" ]
            , button [ onClick LinkTwitter, style "display" "inline-block" ] [ text "Twitter" ]
            , button [ onClick Logout, style "display" "inline-block" ] [ text "ログアウト" ]
            ]
        , div []
            [ h2 [] [ text <| "らぼいん: " ++ laboinTimeStr ]
            , h2 [] [ text <| "らぼりだ: " ++ labooutTimeStr ]
            ]
        , laboNowUpdateButton
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.application
        { view = view
        , init = \_ -> \_ -> \_ -> init
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = \_ -> None
        , onUrlChange = \_ -> None
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
