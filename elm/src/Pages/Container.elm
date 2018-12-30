module Pages.Container exposing (Model, Msg, init, subscriptions, update, view)

{-| Page for single Docker container
-}

import Html exposing (Html, div, text)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Util exposing (createEngineApiUrl)


{-| Details about Docker container
-}
type alias DockerContainer =
    { id : String
    , name : String
    }


dockerContainerDecoder : Decode.Decoder DockerContainer
dockerContainerDecoder =
    Decode.succeed DockerContainer
        |> required "Id" Decode.string
        |> required "Name" Decode.string


getDockerContainer : String -> Cmd Msg
getDockerContainer id =
    Http.get
        { url = createEngineApiUrl ("/containers/" ++ id ++ "/json") Nothing
        , expect = Http.expectJson GotDockerContainer dockerContainerDecoder
        }


type alias Model =
    { dockerContainer : Maybe DockerContainer
    , serverError : String
    }


type Msg
    = GetDockerContainer String
    | GotDockerContainer (Result Http.Error DockerContainer)


init : String -> ( Model, Cmd Msg )
init id =
    ( { dockerContainer = Nothing, serverError = "" }
    , getDockerContainer id
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDockerContainer (Ok dockerContainer) ->
            ( { model | dockerContainer = Just dockerContainer }
            , Cmd.none
            )

        GotDockerContainer (Err error) ->
            ( { model | serverError = "Server error" }
            , Cmd.none
            )

        GetDockerContainer id ->
            ( model, getDockerContainer id )


view : Model -> Html Msg
view model =
    let
        content : Html Msg
        content =
            case model.dockerContainer of
                Just dockerContainer ->
                    div []
                        [ text <|
                            "Docker container: "
                                ++ dockerContainer.name
                                ++ " ("
                                ++ dockerContainer.id
                                ++ ")"
                        ]

                Nothing ->
                    text "No container"
    in
    content


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
