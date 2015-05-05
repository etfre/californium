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
    funcResult = this[@func.funcName].apply(this, @func.args)
    if funcResult is null
      return
    @editor.setSelectedBufferRange(funcResult)

  searchAhead: (back) ->
    start = @start
    count = 0
    end = null
    while count < @num
      result = @scanForwardsThroughRegex start @argRegex
      if result is null
        break
      end = result.range.end
      lastLength = result.matchText.length
      start = end
      count++
    if end is null
      return null
    if back is true
      end = utils.moveBackwards @editor, end, lastLength
    new Range(@start, end)

   searchBehind: (back) ->
    start = @start
    count = 0
    end = null
    while count < @num
      result = @scanBackwardsThroughRegex start @argRegex
      if result is null
        break
      end = result.range.start
      lastLength = result.matchText.length
      start = end
      count++
    if end is null
      return null
    if back
      end = utils.moveForwards @editor, end, lastLength
    new Range(@start, end)

  scanForwardsThroughRegex: (startPos, regex) ->
    eof = utils.getLastPos(@editor)
    result = null
    @editor.scanInBufferRange regex, [startPos, eof], (hit) ->
      hit.stop()
      if hit.matchText != ''
        result = hit
    result

  scanBackwardsThroughRegex: (startPos, regex) ->
    startOfFile = [0, 0]
    result = null
    @editor.backwardsScanInBufferRange regex, [startPos, startOfFile], (hit) ->
      hit.stop()
      if hit.matchText != ''
        result = hit
    result

FUNCS =
  'f':
    'funcName': 'searchAhead'
    'regexStr': null
    'num': null
    'type': 'motion'
    'args': [false]
  'F':
    'funcName': 'searchBehind'
    'regexStr': null
    'num': null
    'type': 'motion'
    'args': [false]
  't':
    'funcName': 'searchAhead'
    'regexStr': null
    'num': null
    'type': 'motion'
    'args': [true]
  'T':
    'funcName': 'searchBehind'
    'regexStr': null
    'num': null
    'type': 'motion'
    'args': [true]


module.exports = {
    ActionHandler
}
