module TypesTest exposing (updateAppStateSuite)

import Expect exposing (Expectation)
import Test exposing (..)
import Types as Sut


updateAppStateSuite : Test
updateAppStateSuite =
    let
        message : Sut.AppMessage
        message =
            Sut.AppMessage "message_text" Sut.Error
    in
    describe "Function updateAppStateSuite" <|
        [ test "First app message"
            (\_ ->
                let
                    appState : Sut.AppState
                    appState =
                        { appMessages = []
                        , auth = Nothing
                        }
                in
                Expect.equal
                    (Sut.updateAppState appState (Sut.AddAppMessage message))
                    { appState | appMessages = [ message ] }
            )
        , test "Second app message gets prepended to existing messages"
            (\_ ->
                let
                    message_1 =
                        Sut.AppMessage "message_1" Sut.Info

                    appState : Sut.AppState
                    appState =
                        { appMessages = [ message_1 ], auth = Nothing }
                in
                Expect.equal
                    (Sut.updateAppState appState (Sut.AddAppMessage message))
                    { appState | appMessages = [ message, message_1 ] }
            )
        ]
