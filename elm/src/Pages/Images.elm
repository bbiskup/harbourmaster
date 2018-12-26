module Pages.Images exposing (Model, Msg, init, subscriptions, update, view)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Table as Table
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (href, title)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Routes exposing (imagesPath)
import String.Extra exposing (ellipsis)



{- Short information on Docker image, as returned by /images/json endpoint -}


type alias DockerImage =
    { id : String
    , labels : Dict String String
    , size : Int
    }


type DockerImages
    = DockerImages (List DockerImage)


dockerImageDecoder : Decode.Decoder DockerImage
dockerImageDecoder =
    Decode.succeed DockerImage
        |> required "Id" Decode.string
        |> optional "Labels" (Decode.dict Decode.string) (Dict.fromList [])
        |> required "Size" Decode.int


dockerImagesDecoder : Decode.Decoder DockerImages
dockerImagesDecoder =
    Decode.map DockerImages <|
        Decode.list dockerImageDecoder


getDockerImages : Cmd Msg
getDockerImages =
    Http.get
        { url = "/api/docker-engine/?url=/images/json"
        , expect = Http.expectJson GotDockerImages dockerImagesDecoder
        }


type alias Model =
    { dockerImages : Maybe DockerImages
    , serverError : String
    }


type Msg
    = GetDockerImages
    | GotDockerImages (Result Http.Error DockerImages)


init : ( Model, Cmd Msg )
init =
    ( { dockerImages = Nothing, serverError = "" }, getDockerImages )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDockerImages (Ok dockerImages) ->
            ( { model | dockerImages = Just dockerImages }, Cmd.none )

        GotDockerImages (Err error) ->
            ( { model | serverError = "Server error" }, Cmd.none )

        GetDockerImages ->
            ( model, getDockerImages )


imageNameOrId : DockerImage -> String
imageNameOrId image =
    Maybe.withDefault image.id <| Dict.get "name" image.labels


viewImages : List DockerImage -> Html Msg
viewImages images =
    Table.table
        { options = [ Table.striped, Table.hover ]
        , thead =
            Table.simpleThead
                [ Table.th [] [ text "Name" ]
                , Table.th [] [ text "Size (MiB)" ]
                ]
        , tbody =
            Table.tbody
                []
                (List.map viewImageRow images)
        }


viewImageRow : DockerImage -> Table.Row Msg
viewImageRow image =
    let
        imageName : String
        imageName =
            imageNameOrId image
                |> ellipsis 40

        sizeStr =
            image.size
                |> toFloat
                |> (*) (1 / 1024 / 1024)
                |> round
                |> String.fromInt
    in
    Table.tr []
        [ Table.td [] [ a [ title imageName, href <| image.id ] [ text imageName ] ]
        , Table.td [] [ text sizeStr ]
        ]


view : Model -> Html Msg
view model =
    let
        content : Html Msg
        content =
            case model.dockerImages of
                Just (DockerImages dockerImages) ->
                    viewImages dockerImages

                Nothing ->
                    text "No images"
    in
    Grid.row []
        [ Grid.col [ Col.xs11 ]
            [ h1 [] [ text "Images" ]
            , content
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
