module Tests exposing (routingTest)

import Expect
import Main exposing (..)
import Test exposing (..)
import Url
import Url.Parser exposing (parse)



-- Check out http://package.elm-lang.org/packages/elm-community/elm-test/latest to learn more about testing in Elm!


emptyUrl =
    { protocol = Url.Http
    , host = ""
    , port_ = Nothing
    , path = ""
    , query = Nothing
    , fragment = Nothing
    }


changeRouting : Bool -> Url.Url -> Routing
changeRouting isUserLoggedIn url =
    let
        nextPage =
            Maybe.withDefault TopPage (parse route url)
    in
    realRouting nextPage isUserLoggedIn


url2Routing : Bool -> String -> Routing
url2Routing isUserLoggedIn url =
    Url.fromString url
        |> Maybe.withDefault emptyUrl
        |> changeRouting isUserLoggedIn


routingTestHelper : Bool -> String -> Routing -> Expect.Expectation
routingTestHelper isUserLoggedIn url expected =
    url2Routing isUserLoggedIn url
        |> Expect.equal expected


routingTest : Test
routingTest =
    describe "changeRouting"
        [ describe "ログイン済みの時" <|
            let
                isUserLoggedIn =
                    True

                routingTestHelperLoggedIn =
                    routingTestHelper isUserLoggedIn
            in
            [ test "root" <|
                \_ ->
                    routingTestHelperLoggedIn "https://labotter2.firebaseapp.com/" MainPage
            , test "config" <|
                \_ ->
                    routingTestHelperLoggedIn "https://labotter2.firebaseapp.com/config" ConfigPage
            , test "login" <|
                \_ ->
                    routingTestHelperLoggedIn "https://labotter2.firebaseapp.com/login" LoginPage
            ]
        , describe "ログインしていない時" <|
            let
                isUserLoggedIn =
                    False

                routingTestHelperNotLoggedIn =
                    routingTestHelper isUserLoggedIn
            in
            [ test "root" <|
                \_ ->
                    routingTestHelperNotLoggedIn "https://labotter2.firebaseapp.com/" TopPage
            , test "config" <|
                \_ ->
                    routingTestHelperNotLoggedIn "https://labotter2.firebaseapp.com/config" TopPage
            , test "login" <|
                \_ ->
                    routingTestHelperNotLoggedIn "https://labotter2.firebaseapp.com/login" LoginPage
            ]
        ]
