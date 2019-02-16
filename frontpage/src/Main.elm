port module Main exposing
    ( Model
    , Msg(..)
    , Routing(..)
    , changeRouting
    , init
    , main
    , update
    , view
    )

import Browser exposing (Document)
import Browser.Navigation as Nav
import Html
    exposing
        ( Html
        , a
        , br
        , button
        , div
        , h1
        , h2
        , img
        , input
        , li
        , text
        )
import Html.Attributes exposing (href, id, placeholder, src, style, value)
import Html.Events exposing (onClick, onInput)
import Task
import Time exposing (Month(..))
import Url
import Url.Parser exposing ((</>), Parser, int, map, oneOf, parse, s, top)



---- ROUTING ----


type Routing
    = TopPage
    | MainPage
    | ConfigPage
    | LoginPage


changeRouting : Bool -> Url.Url -> Routing
changeRouting isUserLoggedIn url =
    let
        nextPage =
            Maybe.withDefault TopPage (parse route url)
    in
    nextRouting isUserLoggedIn nextPage


nextRouting : Bool -> Routing -> Routing
nextRouting isUserLoggedIn nextPage =
    case isUserLoggedIn of
        True ->
            case nextPage of
                TopPage ->
                    MainPage

                other ->
                    other

        False ->
            case nextPage of
                LoginPage ->
                    LoginPage

                other ->
                    TopPage


route : Parser (Routing -> a) a
route =
    oneOf
        [ map MainPage top
        , map ConfigPage <| s "config"
        , map LoginPage <| s "login"
        ]



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
    , tweetMessage : TweetMessage
    , isUserLoggedIn : Bool
    , key : Nav.Key
    }


type alias TweetMessage =
    { laboin : String
    , laboout : String
    , labonow : String
    }


init : Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init url key =
    let
        nextRoute : Routing
        nextRoute =
            changeRouting False url
    in
    ( { labointime = 0
      , labotimes = []
      , now = Time.millisToPosix 0
      , routing = nextRoute
      , tweetMessage =
            { laboin = "らぼいん!"
            , laboout = "らぼりだ!"
            , labonow = "らぼなう!"
            }
      , isUserLoggedIn = False
      , key = key
      }
    , Cmd.batch
        [ updateChangeRoutingCmd nextRoute
        ]
    )



---- UPDATE ----


port logout : () -> Cmd msg


port laboin : Int -> Cmd msg


port laboout : Int -> Cmd msg


port link_twitter : () -> Cmd msg


port updatelabotimes : (List Period -> msg) -> Sub msg


port updatelabointime : (Int -> msg) -> Sub msg


port userlogin : (Bool -> msg) -> Sub msg


port showloginpage : () -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ updatelabotimes UpdateLaboTimes
        , updatelabointime UpdateLaboinTime
        , userlogin Login
        , Time.every 500 SetCurrentTime
        ]


type Msg
    = Logout
    | Login Bool
    | LaboIn
    | LaboOut
    | UpdateLaboTimes (List Period)
    | UpdateLaboinTime Int
    | SetCurrentTime Time.Posix
    | LinkTwitter
    | None
    | ChangeRouting Url.Url
    | ChangeTweetMessageLaboin String
    | RequestChangeUrl Browser.UrlRequest


updateChangeRoutingCmd : Routing -> Cmd Msg
updateChangeRoutingCmd nextRoute =
    case nextRoute of
        LoginPage ->
            showloginpage ()

        other ->
            Cmd.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Logout ->
            ( { model | isUserLoggedIn = False }, logout () )

        Login isUserLoggedIn ->
            let
                nextRoute =
                    nextRouting isUserLoggedIn model.routing
            in
            ( { model | isUserLoggedIn = isUserLoggedIn, routing = nextRoute }, updateChangeRoutingCmd nextRoute )

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

        ChangeRouting url ->
            let
                nextRoute =
                    changeRouting model.isUserLoggedIn url
            in
            ( { model | routing = nextRoute }, updateChangeRoutingCmd nextRoute )

        ChangeTweetMessageLaboin message ->
            let
                newTweetMessage : TweetMessage -> String -> TweetMessage
                newTweetMessage tweetMessagex messagex =
                    { tweetMessagex | laboin = messagex }
            in
            ( { model | tweetMessage = newTweetMessage model.tweetMessage message }
            , Cmd.none
            )

        RequestChangeUrl urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )



---- VIEW ----


view : Model -> Document Msg
view model =
    let
        routing =
            case model.routing of
                TopPage ->
                    topPageView

                MainPage ->
                    mainPageView

                ConfigPage ->
                    configPageView

                LoginPage ->
                    loginPageView
    in
    { title = "らぼったー2"
    , body = [ routing model ]
    }


mainPageView : Model -> Html Msg
mainPageView model =
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


configPageView : Model -> Html Msg
configPageView model =
    div []
        [ input [ placeholder "Text to reverse", value model.tweetMessage.laboin, onInput ChangeTweetMessageLaboin ] []
        ]


loginPageView : Model -> Html Msg
loginPageView model =
    div []
        [ div [ id "firebaseui-auth-container" ] []
        , div [ id "loader" ] [ text "Loading..." ]
        ]


topPageView : Model -> Html Msg
topPageView model =
    div []
        [ text "らぼったーへようこそ"
        , viewLink "/login"
        ]


viewLink : String -> Html msg
viewLink path =
    li [] [ a [ href path ] [ text path ] ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.application
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = RequestChangeUrl
        , onUrlChange = ChangeRouting
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
