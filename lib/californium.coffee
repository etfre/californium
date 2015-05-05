{Disposable, CompositeDisposable} = require 'atom'
ObserverHandler = require './californium-state'

module.exports =
  subscriptions: null

  activate: ->
    obsHandler = new ObserverHandler()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'californium:startListening': => obsHandler.startListening()
      'californium:test': => @test()

  deactivate: ->
    @subscriptions.dispose()

  test: ->
    editor = atom.workspace.getActiveTextEditor()
    console.log(editor.getCursorBufferPosition())
    console.log(editor.lineTextForBufferRow(17))
