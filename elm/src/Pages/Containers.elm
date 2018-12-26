module Pages.Containers exposing (Model, Msg, init, subscriptions, update, view)

import Html exposing (..)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)



{- Short information on Docker container, as returned by /containers/json endpoint -}


type alias DockerContainer =
    { id : String
    , names : List String
    , image : String
    }


type DockerContainers
    = DockerContainers (List DockerContainer)


dockerContainerDecoder : Decode.Decoder DockerContainer
dockerContainerDecoder =
    Decode.succeed DockerContainer
        |> required "Id" Decode.string
        |> required "Names" (Decode.list Decode.string)
        |> required "Image" Decode.string


dockerContainersDecoder : Decode.Decoder DockerContainers
dockerContainersDecoder =
    Decode.map DockerContainers <|
        Decode.list dockerContainerDecoder


getDockerContainers : Cmd Msg
getDockerContainers =
    Http.get
        { url = "/api/docker-engine/?url=/containers/json"
        , expect = Http.expectJson GotDockerContainers dockerContainersDecoder
        }


type alias Model =
    { dockerContainers : Maybe DockerContainers
    , serverError : String
    }


type Msg
    = GetDockerContainers
    | GotDockerContainers (Result Http.Error DockerContainers)


init : ( Model, Cmd Msg )
init =
    ( { dockerContainers = Nothing, serverError = "" }, getDockerContainers )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDockerContainers (Ok dockerContainers) ->
            ( { model | dockerContainers = Just dockerContainers }, Cmd.none )

        GotDockerContainers (Err error) ->
            ( { model | serverError = "Server error" }, Cmd.none )

        GetDockerContainers ->
            ( model, getDockerContainers )


view : Model -> Html Msg
view model =
    case model.dockerContainers of
        Just (DockerContainers dockerContainers) ->
            let
                renderContainer : DockerContainer -> Html Msg
                renderContainer dockerContainer =
                    li [] [ text <| dockerContainer.id ++ "(" ++ dockerContainer.image ++ ")" ]
            in
            div []
                [ h1 [] [ text "Containers" ]
                , ul []
                    (List.map renderContainer dockerContainers)
                ]

        Nothing ->
            div []
                [ p [] [ text "No containers" ]
                , p [] [ text model.serverError ]
                ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
