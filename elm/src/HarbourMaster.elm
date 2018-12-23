module HarbourMaster exposing (main)

import Browser
import Html exposing (..)
import Pages.Info
import Types exposing (AppState)


type Page
    = InfoPage Pages.Info.Model


type alias Model =
    { appState : AppState
    , currPage : Page
    }


type Msg
    = NavInfo
    | Info Pages.Info.Msg


initialModel : Model
initialModel =
    { appState = { dummyGlobalState = "dummy_global_state" }
    , currPage = InfoPage Pages.Info.init
    }


initialCmd : Cmd Msg
initialCmd =
    Pages.Info.initialCmd |> Cmd.map Info


view : Model -> Html Msg
view model =
    case model.currPage of
        InfoPage pageModel ->
            Pages.Info.page pageModel |> Html.map Info


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ appState } as model) =
    case msg of
        -- navigate to info page
        NavInfo ->
            ( { model | currPage = InfoPage Pages.Info.init }, Cmd.none )

        Info pageMsg ->
            let
                (InfoPage pageModel) =
                    model.currPage

                ( infoModel, infoCmd ) =
                    Pages.Info.update pageMsg pageModel
            in
            ( { model | currPage = InfoPage infoModel }, Cmd.map Info infoCmd )


init : () -> ( Model, Cmd Msg )
init flags =
    ( initialModel, initialCmd )


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
