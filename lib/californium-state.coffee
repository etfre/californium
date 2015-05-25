utils = require './utils'
actions = require './actions'
{Disposable, CompositeDisposable} = require 'atom'

class EditorObserver

  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable
    @listening = true
    @input = ''
    @editorView = atom.views.getView @editor
    @editorView.addEventListener 'keypress', (event) =>
       @handleInput(event)


  handleInput: (event) ->
    if not @listening
      return
    char = utils.CHARS[event.which]
    if @input != '' and char == '^' and @input.slice(-1) == '`'
      [num, action, func, arg] = @input.split '-'
      @input = ''
      arg = arg.slice(0, -1)
      handler = new actions.ActionHandler(@editor, num, action, arg)
      handler.doFunction(func)
      @listening = false
    else
      @input += char
    # stop keypress event
    event.preventDefault()

class ObserverHandler

  constructor: ->
    @observers = []

  startListening: ->
    current_editor = atom.workspace.getActiveTextEditor()
    obs = null
    for o in @observers
      if o.editor is current_editor
        obs = o
        obs.listening = true
        break
    if not obs
      obs = new EditorObserver(current_editor)
      current_editor.onDidDestroy =>
        i = @observers.indexOf(current_editor)
        @observers.splice(i, 1)
      @observers.push obs

module.exports = ObserverHandler
