module Tests exposing (all)

import Expect
import Main exposing (..)
import Test exposing (..)
import Url



-- Check out http://package.elm-lang.org/packages/elm-community/elm-test/latest to learn more about testing in Elm!


emptyUrl =
    { protocol = Url.Http
    , host = ""
    , port_ = Nothing
    , path = ""
    , query = Nothing
    , fragment = Nothing
    }


url2Routing : Bool -> String -> Routing
url2Routing isUserLoggedIn url =
    Url.fromString url
        |> Maybe.withDefault emptyUrl
        |> changeRouting isUserLoggedIn


all : Test
all =
    describe "A Test Suite"
        [ describe "changeRouting"
            [ describe "ログイン済みの時"
                [ test "root" <|
                    let
                        expected =
                            MainPage

                        actual =
                            url2Routing True "https://labotter2.firebaseapp.com/"
                    in
                    \_ ->
                        Expect.equal expected actual
                , test "config" <|
                    let
                        expected =
                            ConfigPage

                        actual =
                            url2Routing True "https://labotter2.firebaseapp.com/config"
                    in
                    \_ ->
                        Expect.equal expected actual
                , test "login" <|
                    let
                        expected =
                            LoginPage

                        actual =
                            url2Routing True "https://labotter2.firebaseapp.com/login"
                    in
                    \_ ->
                        Expect.equal expected actual
                ]
            , describe "ログインしていない時"
                [ test "root" <|
                    let
                        expected =
                            TopPage

                        actual =
                            url2Routing False "https://labotter2.firebaseapp.com/"
                    in
                    \_ ->
                        Expect.equal expected actual
                , test "config" <|
                    let
                        expected =
                            TopPage

                        actual =
                            url2Routing False "https://labotter2.firebaseapp.com/config"
                    in
                    \_ ->
                        Expect.equal expected actual
                , test "login" <|
                    let
                        expected =
                            LoginPage

                        actual =
                            url2Routing False "https://labotter2.firebaseapp.com/login"
                    in
                    \_ ->
                        Expect.equal expected actual
                ]
            ]
        ]
