module Pages.Login exposing (Model, Msg(..), init, initialCmd, subscriptions, update, view)

{-| User login page
-}

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Html exposing (..)
import Html.Attributes exposing (for, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode
import Types
    exposing
        ( AppMessage
        , Auth
        , MessageSeverity
        , UpdateAppState(..)
        , httpErrorToAppMessage
        )


type alias Model =
    { userName : String
    , password : String
    }


type alias LoginData =
    { userName : String
    , password : String
    }


type Msg
    = UserNameChanged String
    | PasswordChanged String
    | Login
    | GotSession (Result Http.Error Auth)


minPasswordLength : Int
minPasswordLength =
    5


authDecoder : Decode.Decoder Auth
authDecoder =
    Decode.succeed Auth
        |> required "sessionID" Decode.string


loginEncoder : LoginData -> Encode.Value
loginEncoder loginData =
    Encode.object
        [ ( "userName", Encode.string loginData.userName )
        , ( "password", Encode.string loginData.password )
        ]


login : LoginData -> Cmd Msg
login loginData =
    Http.request
        { method = "POST"
        , headers = []
        , url = "/login/"
        , body = Http.jsonBody (loginEncoder loginData)
        , expect = Http.expectJson GotSession authDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


initialCmd : Cmd Msg
initialCmd =
    Cmd.none


init : ( Model, Cmd Msg )
init =
    let
        model =
            { userName = ""
            , password = ""
            }
    in
    ( model
    , initialCmd
    )


update : Msg -> Model -> ( Model, Cmd Msg, UpdateAppState )
update msg model =
    case msg of
        Login ->
            ( model
            , login <| LoginData model.userName model.password
            , NoOp
            )

        UserNameChanged userName ->
            ( { model
                | userName = userName
              }
            , Cmd.none
            , NoOp
            )

        PasswordChanged password ->
            ( { model
                | password = password
              }
            , Cmd.none
            , NoOp
            )

        GotSession (Ok auth) ->
            ( model
            , Cmd.none
            , NoOp
            )

        GotSession (Err error) ->
            ( model
            , Cmd.none
            , AddAppMessage <| httpErrorToAppMessage error
            )


view : Model -> Html Msg
view model =
    Grid.container []
        [ Grid.row []
            [ Grid.col [ Col.sm4 ]
                [ h1 [] [ text "Login" ]
                , Form.form [ onSubmit Login ]
                    [ Form.group []
                        [ Form.label [ for "username" ] [ text "Username" ]
                        , Input.text [ Input.attrs [ value model.userName, onInput UserNameChanged ] ]
                        ]
                    , Form.group []
                        [ Form.label [ for "password" ] [ text "Password" ]
                        , Input.text [ Input.attrs [ value model.password, onInput PasswordChanged ] ]
                        ]
                    , Button.button
                        [ Button.primary
                        , Button.attrs []
                        ]
                        [ text "Login..." ]
                    ]
                ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
