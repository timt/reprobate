module ConfigEditor.View exposing (view)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import ConfigEditor.Model as Model exposing (..)
import ConfigEditor.Msg as Msg exposing (..)
import String
import Dict
import Json.Encode as JsonEncode
import Date
import Date.Format as DateFormat
import Http
import Json.Decode as JsonDecode

(=>) = (,)


view : Model -> Html Msg
view model =
  div [ class "row" ]
    [ div [ class "col-md-12" ]
        [ div [ style [("margin-top", "3px")] ] [ text (Maybe.withDefault "" model.error) ]
        , agentView model
        ]
    ]


agentView : Model -> Html Msg
agentView model =
    div [] [
--      div [ class "form-inline" ] [
--        div [ style [ ( "margin" => "7px" ) ] ]
--          [
--          div [ class ("form-group"), style [ "padding-right" => "3px" ] ]
--            [
--            configEditor ((Maybe.map (\m -> m.config) model.agentModel) |> Maybe.withDefault "") False
            configEditor (model.command) False
            --,  span [ class "glyphicon glyphicon-ok form-control-feedback", (property "aria-hidden" (JsonEncode.string "true")) ] [ ]
--            ]
          , div [ class "form-group" ] [ runButton (False), cancelButton (False) ]
--          ]
--      ]
    ]


configEditor : String -> Bool -> Html Msg
configEditor v disable =
  textarea [ class "form-control input-sm"
        , onInput (\v -> (CommandChanged v))
        --, onEnter RunCommand
        , disabled disable
        , value v
        , rows 30
        ] []


--TIP: borrowed from https://github.com/evancz/elm-todomvc/blob/master/Todo.elm
onEnter : Msg -> Attribute Msg
onEnter msg =
  let
    tagger code =
      if code == 13 then msg else NoOp
  in
    on "keydown" (JsonDecode.map tagger keyCode)



runButton : Bool -> Html Msg
runButton disable =
  button
      [ class "btn btn-link", style [ "padding" => "0px", "margin" => "0px" ]
      , onClick RunCommand
      , title "Save"
      , disabled disable
      ]
      [
      i [ class "fa fa-check fa-2x" ] []
      ]


cancelButton : Bool -> Html Msg
cancelButton disable =
  button
      [ class "btn btn-link", style [ "padding" => "0px", "margin" => "0px" ]
      , onClick CancelCommand
      , title "Cancel"
      , disabled disable
      ]
      [
      i [ class "fa fa-times fa-2x" ] []
      ]
