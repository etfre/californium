{Disposable, CompositeDisposable} = require 'atom'
ObserverHandler = require './californium-state'

module.exports =
  subscriptions: null

  activate: ->
    obsHandler = new ObserverHandler()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'californium:startListening': => obsHandler.startListening()

  deactivate: ->
    @subscriptions.dispose()
