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


routingTestHelper : String -> Bool -> Routing -> Expect.Expectation
routingTestHelper url isUserLoggedIn expected =
    url2Routing isUserLoggedIn url
        |> Expect.equal expected


routingTest : Test
routingTest =
    describe "changeRouting"
        [ describe "ログイン済みの時"
            [ test "root" <|
                \_ ->
                    routingTestHelper "https://labotter2.firebaseapp.com/" True MainPage
            , test "config" <|
                \_ ->
                    routingTestHelper "https://labotter2.firebaseapp.com/config" True ConfigPage
            , test "login" <|
                \_ ->
                    routingTestHelper "https://labotter2.firebaseapp.com/login" True LoginPage
            ]
        , describe "ログインしていない時"
            [ test "root" <|
                \_ ->
                    routingTestHelper "https://labotter2.firebaseapp.com/" False TopPage
            , test "config" <|
                \_ ->
                    routingTestHelper "https://labotter2.firebaseapp.com/config" False TopPage
            , test "login" <|
                \_ ->
                    routingTestHelper "https://labotter2.firebaseapp.com/login" False LoginPage
            ]
        ]
