module Pages.Image exposing (Model, Msg, init, subscriptions, update, view)

{-| Page for single Docker image
-}

import Html exposing (Html, div, text)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Util exposing (createEngineApiUrl)


{-| Details about Docker image
-}
type alias DockerImage =
    { id : String
    , repoTags : List String
    , size : Int
    , author : String
    }


dockerImageDecoder : Decode.Decoder DockerImage
dockerImageDecoder =
    Decode.succeed DockerImage
        |> required "Id" Decode.string
        |> required "RepoTags" (Decode.list Decode.string)
        |> required "Size" Decode.int
        |> required "Author" Decode.string


getDockerImage : String -> Cmd Msg
getDockerImage id =
    Http.get
        { url = createEngineApiUrl ("/images/" ++ id ++ "/json") Nothing
        , expect = Http.expectJson GotDockerImage dockerImageDecoder
        }


type alias Model =
    { dockerImage : Maybe DockerImage
    , serverError : String
    }


type Msg
    = GetDockerImage String
    | GotDockerImage (Result Http.Error DockerImage)


init : String -> ( Model, Cmd Msg )
init id =
    ( { dockerImage = Nothing, serverError = "" }, getDockerImage id )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDockerImage (Ok dockerImage) ->
            ( { model | dockerImage = Just dockerImage }
            , Cmd.none
            )

        GotDockerImage (Err error) ->
            ( { model | serverError = "Server error" }
            , Cmd.none
            )

        GetDockerImage id ->
            ( model, getDockerImage id )


view : Model -> Html Msg
view model =
    let
        content : Html Msg
        content =
            case model.dockerImage of
                Just dockerImage ->
                    div [] [ text <| "Docker image: " ++ dockerImage.id ]

                Nothing ->
                    text "No image"
    in
    content


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
