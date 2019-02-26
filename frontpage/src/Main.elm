port module Main exposing
    ( Model
    , Msg(..)
    , Routing(..)
    , init
    , main
    , realRouting
    , route
    , update
    , view
    )

import Browser exposing (Document)
import Browser.Navigation as Nav
import Element
import Element.Background
import Element.Events
import Html
    exposing
        ( Html
        , a
        , button
        , div
        , h1
        , h2
        , input
        , span
        , text
        )
import Html.Attributes exposing (class, hidden, href, id, placeholder, style, value)
import Html.Events exposing (onClick, onInput)
import Time exposing (Month(..))
import Url
import Url.Parser exposing ((</>), Parser, map, oneOf, parse, s, top)



---- ROUTING ----


type Routing
    = TopPage
    | MainPage
    | ConfigPage
    | LoginPage


url2Routing : Url.Url -> Routing
url2Routing url =
    parse route url
        |> Maybe.withDefault TopPage


realRouting : Routing -> Bool -> Routing
realRouting nextPage isUserLoggedIn =
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
    ( { labointime = 0
      , labotimes = []
      , now = Time.millisToPosix 0
      , routing = url2Routing url
      , tweetMessage =
            { laboin = "らぼいん!"
            , laboout = "らぼりだ!"
            , labonow = "らぼなう!"
            }
      , isUserLoggedIn = False
      , key = key
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


port userlogin : (Bool -> msg) -> Sub msg


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
    | GoTo String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Logout ->
            ( { model | isUserLoggedIn = False }, logout () )

        Login isUserLoggedIn ->
            ( { model | isUserLoggedIn = isUserLoggedIn }, Cmd.none )

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
            ( { model | routing = url2Routing url }, Cmd.none )

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

        GoTo url ->
            ( model, Nav.pushUrl model.key url )



---- VIEW ----


view : Model -> Document Msg
view model =
    let
        footer =
            case model.isUserLoggedIn of
                True ->
                    Element.el
                        [ Element.height Element.fill
                        , Element.width Element.fill
                        ]
                    <|
                        footerView model

                False ->
                    Element.none
    in
    { title = "らぼったー2"
    , body =
        [ Element.layout [] <|
            Element.column [ Element.height Element.fill, Element.width Element.fill ]
                [ Element.el
                    [ Element.height <| Element.fillPortion 1
                    , Element.width Element.fill
                    ]
                  <|
                    headerView
                , Element.el
                    [ Element.height <| Element.fillPortion 8
                    , Element.width Element.fill
                    ]
                  <|
                    mainView model
                , Element.el
                    [ Element.height <| Element.fillPortion 1
                    , Element.width Element.fill
                    ]
                  <|
                    footer
                ]
        ]
    }


headerView : Element.Element Msg
headerView =
    Element.html <| div [] []


footerView : Model -> Element.Element Msg
footerView model =
    Element.row [ Element.height Element.fill, Element.width Element.fill ]
        [ Element.el
            [ Element.height Element.fill
            , Element.width <| Element.fillPortion 1
            , Element.Events.onMouseDown <| GoTo "/"
            , Element.Background.color (Element.rgb255 0 128 128)
            ]
          <|
            Element.el
                [ Element.centerX
                , Element.centerY
                ]
            <|
                Element.text "Home"
        , Element.el
            [ Element.height Element.fill
            , Element.width <| Element.fillPortion 2
            , Element.Background.color (Element.rgb255 128 0 128)
            ]
          <|
            Element.el [ Element.centerX, Element.centerY ] <|
                Element.text "らぼなう！"
        , Element.el
            [ Element.height Element.fill
            , Element.width <| Element.fillPortion 1
            , Element.Events.onMouseDown <| GoTo "/config"
            , Element.Background.color (Element.rgb255 128 128 0)
            ]
          <|
            Element.el [ Element.centerX, Element.centerY ] <|
                Element.text "config"
        ]


mainView : Model -> Element.Element Msg
mainView model =
    let
        routing =
            case realRouting model.routing model.isUserLoggedIn of
                TopPage ->
                    topPageView

                MainPage ->
                    mainPageView

                ConfigPage ->
                    configPageView

                LoginPage ->
                    loginPageView

        firebaseui =
            model.routing == LoginPage
    in
    Element.column
        [ Element.height Element.fill
        , Element.centerX
        ]
        [ Element.html <|
            div [ hidden <| not firebaseui ]
                [ div [ id "firebaseui-auth-container" ] []
                ]
        , routing model
        ]


mainPageView : Model -> Element.Element Msg
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
    Element.html <|
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


configPageView : Model -> Element.Element Msg
configPageView model =
    Element.html <|
        div []
            [ input [ placeholder "Text to reverse", value model.tweetMessage.laboin, onInput ChangeTweetMessageLaboin ] []
            ]


loginPageView : Model -> Element.Element Msg
loginPageView model =
    Element.html <| div [] []


topPageView : Model -> Element.Element Msg
topPageView model =
    Element.column [ Element.width Element.fill, Element.height Element.fill ]
        [ Element.el
            [ Element.height Element.fill
            , Element.centerX
            , Element.padding 10
            ]
          <|
            Element.el [ Element.alignBottom ] <|
                Element.text "らぼったーへようこそ！"
        , Element.el
            [ Element.height Element.fill
            , Element.centerX
            , Element.padding 10
            ]
          <|
            viewLink "/login" "ログイン"
        ]


viewLink : String -> String -> Element.Element msg
viewLink path content =
    Element.html <|
        a [ href path ]
            [ button [ class "mdc-button mdc-button--raised mdc-button--outlined" ]
                [ span [ class "mdc-button__label" ] [ text content ]
                ]
            ]



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
