module Pages.Images exposing (Model, Msg, init, subscriptions, update, view)

{-| Page for all Docker images
-}

import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Table as Table
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (checked, href, title, type_)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (..)
import Routes exposing (imagePath, imagesPath)
import String.Extra exposing (ellipsis)
import Util exposing (bytesToMiB)


imageNameNone : String
imageNameNone =
    "<none>:<none>"



{- Short information on Docker image, as returned by /images/json endpoint -}


type alias DockerImage =
    { id : String
    , repoTags : List String
    , labels : Dict String String
    , size : Int
    }


type DockerImages
    = DockerImages (List DockerImage)


{-| Decoder for a single docker image record of endpoint /images
-}
dockerImageDecoder : Decode.Decoder DockerImage
dockerImageDecoder =
    Decode.succeed DockerImage
        |> required "Id" Decode.string
        |> required "RepoTags" (Decode.list Decode.string)
        |> optional "Labels" (Decode.dict Decode.string) (Dict.fromList [])
        |> required "Size" Decode.int


{-| Decoder for a list of single docker image record of endpoint /images
-}
dockerImagesDecoder : Decode.Decoder DockerImages
dockerImagesDecoder =
    Decode.map DockerImages <|
        Decode.list dockerImageDecoder


{-| Fetch a list of Docker images
-}
getDockerImages : Cmd Msg
getDockerImages =
    Http.get
        { url = "/api/docker-engine/?url=/images/json"
        , expect = Http.expectJson GotDockerImages dockerImagesDecoder
        }


type alias Model =
    { dockerImages : Maybe DockerImages
    , serverError : String
    , filterUnnamedImages : Bool
    }


type Msg
    = GetDockerImages
    | GotDockerImages (Result Http.Error DockerImages)
    | ToggleHideUnnamedImages Bool


init : ( Model, Cmd Msg )
init =
    ( { dockerImages = Nothing
      , serverError = ""
      , filterUnnamedImages = True
      }
    , getDockerImages
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDockerImages (Ok dockerImages) ->
            ( { model | dockerImages = Just dockerImages }
            , Cmd.none
            )

        GotDockerImages (Err error) ->
            ( { model | serverError = "Server error" }
            , Cmd.none
            )

        GetDockerImages ->
            ( model, getDockerImages )

        ToggleHideUnnamedImages isChecked ->
            ( { model | filterUnnamedImages = isChecked }
            , getDockerImages
            )


{-| Combination of repo tags (if any, and if not "<none>:<none>"), or image ID as fallback
-}
imageNamesOrId : DockerImage -> String
imageNamesOrId image =
    let
        actualTags =
            List.filter (\x -> x /= imageNameNone) image.repoTags
    in
    case actualTags of
        (h :: t) as tags ->
            String.join ", " tags

        [] ->
            image.id


{-| Create table of all Docker images, possibly filtered by whether the image has a proper name
-}
viewImages : List DockerImage -> Bool -> Html Msg
viewImages images filterUnnamedImages =
    let
        isUnnamedImage : DockerImage -> Bool
        isUnnamedImage image =
            not <| String.startsWith "sha256:" <| imageNamesOrId image

        filteredImages : List DockerImage
        filteredImages =
            if filterUnnamedImages then
                -- exclude anonymous layers
                List.filter isUnnamedImage images

            else
                images

        sortedImages =
            List.sortBy imageNamesOrId filteredImages
    in
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
                (List.map viewImageRow sortedImages)
        }


{-| Create a table row, corresponding to a single Docker image
-}
viewImageRow : DockerImage -> Table.Row Msg
viewImageRow image =
    let
        imageName : String
        imageName =
            imageNamesOrId image
                |> ellipsis 80

        sizeStr =
            image.size
                |> bytesToMiB
                |> String.fromInt

        imageNameTitle : String
        imageNameTitle =
            imageName
                ++ "("
                ++ image.id
                ++ ")"
    in
    Table.tr []
        [ Table.td []
            [ a
                [ title imageNameTitle
                , href <| imagePath image.id
                ]
                [ text imageName ]
            ]
        , Table.td [] [ text sizeStr ]
        ]


view : Model -> Html Msg
view model =
    let
        content : Html Msg
        content =
            case model.dockerImages of
                Just (DockerImages dockerImages) ->
                    viewImages dockerImages model.filterUnnamedImages

                Nothing ->
                    text "No images"
    in
    Grid.row []
        [ Grid.col [ Col.xs11 ]
            [ h1 [] [ text "Images" ]
            , Checkbox.checkbox
                [ Checkbox.inline
                , Checkbox.onCheck ToggleHideUnnamedImages
                , Checkbox.checked model.filterUnnamedImages
                ]
                "Hide unnamed images"
            , br
                []
                []
            , content
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
