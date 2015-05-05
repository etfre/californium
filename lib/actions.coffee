utils = require './utils'

{Disposable, CompositeDisposable, Point, Range} = require 'atom'

disposables = new CompositeDisposable()

class ActionHandler

  constructor: (@editor, num, action, arg) ->
    @num = parseInt(num)
    @argRegex = new RegExp(arg)
    @start = @editor.getCursorBufferPosition()

  doFunction: (func) ->
    @func = FUNCS[func]
    if @func.regexStr is not null
      @argRegex = new RegExp(@func.regexStr)
    funcResult = this[@func.funcName].apply(this)
    @editor.setSelectedBufferRange(funcResult)
    console.log(funcResult)

  searchUntil: () ->
    start = @start
    count = 0
    end = null
    while count < @num
      result = @scanForwardsThroughRegex start
      if result is null
        break
      console.log('end', result)
      end = result.range.end
      start = end
      count++
    if end is null
      null
    end = utils.moveBackwards @editor, end, result.matchText.length
    new Range(@start, end)


  scanForwardsThroughRegex: (startPos) ->
    eof = utils.getLastPos(@editor)
    result = null
    @editor.scanInBufferRange @argRegex, [startPos, eof], (hit) ->
      hit.stop()
      if hit.matchText != ''
        result = hit
    result

FUNCS =
  'f':
    'funcName': 'searchUntil'
    'regexStr': null
    'num': null
    'type': 'motion'
  # 'F':
  #   'func': ActionHandler.searchThrough
  #   'regexStr': null
  #   'num': null
  #   'type': 'motion'

module.exports = {
    ActionHandler
}
