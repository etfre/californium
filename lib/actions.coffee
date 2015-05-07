utils = require './utils'
{Disposable, CompositeDisposable, Point, Range} = require 'atom'

disposables = new CompositeDisposable()

class ActionHandler

  constructor: (@editor, num, action, arg) ->
    @num = parseInt(num)
    @arg = arg
    @start = @editor.getCursorBufferPosition()
    @lastPos = utils.getLastPos(@editor).toArray()

  doFunction: (func) ->
    @func = FUNCS[func]
    if @func.regexStr is not null
      @argRegex = new RegExp(@func.regexStr)
    else
      if @func.type == 'surroundObject'
        @argRegex = new RegExp('\\' + @arg[0] + '|\\' + @arg[1]) 
        console.log(@argRegex)
      else
        @argRegex = new RegExp(@arg)
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

  modifyLine: () ->
    startArray = @start.toArray()
    startArray[1] = 0
    count = 0
    endRow = Math.min(@start.toArray()[0] + @num - 1, @lastPos[0])
    endCol = @editor.lineTextForBufferRow(endRow).length
    return new Range(startArray, [endRow, endCol])

  getSurroundRange: () ->
    start = @start
    end = @start
    pos1 = null
    pos2 = null
    oppoCharCount = 0
    while pos1 is null
      result = @scanBackwardsThroughRegex start, @argRegex
      if result is null
        return null
      start = result.range.start
      if result.matchText == @arg[1]
        oppoCharCount++
      else
        if oppoCharCount > 0 
          oppoCharCount--
        else
          pos1 = result.range.start 
    oppoCharCount = 0
    while pos2 is null
      result = @scanForwardsThroughRegex end, @argRegex
      if result is null
        return null
      end = result.range.end
      if result.matchText == @arg[0]
        oppoCharCount++
      else
        if oppoCharCount > 0 
          oppoCharCount--
        else
          pos2 = result.range.end
    return new Range(pos1, pos2)

  scanForwardsThroughRegex: (startPos, regex) =>
    eof = utils.getLastPos(@editor)
    result = null
    @editor.scanInBufferRange regex, [startPos, @lastPos], (hit) =>
      hit.stop()
      if hit.matchText != ''
        result = hit
    result

  scanBackwardsThroughRegex: (startPos, regex) ->
    startOfFile = [0, 0]
    result = null
    @editor.backwardsScanInBufferRange regex, [startPos, startOfFile], (hit) =>
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
  'l':
    'funcName': 'modifyLine'
    'regexStr': '\\n'
    'num': null
    'type': 'motion'
    'args': []
  'y':
    'funcName': 'getSurroundRange'
    'regexStr': null
    'num': null
    'type': 'surroundObject'
    'args': []

module.exports = {
    ActionHandler
}
