utils = require './utils'
{Disposable, CompositeDisposable, Point, Range} = require 'atom'

disposables = new CompositeDisposable()

class ActionHandler

  constructor: (@editor, num, action, arg) ->
    @num = parseInt(num)
    @action = action
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
      else
        @argRegex = new RegExp(@arg)
    funcResult = this[@func.funcName].apply(this, @func.args)
    console.log(funcResult)
    if funcResult == null
      return
    doAction(funcResult, @action, @editor, @func.type)
    #@editor.setSelectedBufferRange(funcResult)

  searchAhead: (back, start=@start, lastPos=@lastPos, num=@num) ->
    lastPos = start
    count = 0
    end = null
    while count < num
      result = @scanForwardsThroughRegex [start, @lastPos], @argRegex
      if result == null
        break
      end = result.range.end
      lastLength = result.matchText.length
      start = end
      count++
    if end == null
      return null
    if back is true
      end = utils.moveBackwards @editor, end, lastLength
    new Range(lastPos, end)

   searchBehind: (back, start=@start,  lastPos=@lastPos, num=@num) ->
    lastPos = start
    count = 0
    end = null
    while count < num
      result = @scanBackwardsThroughRegex [start, [0, 0]], @argRegex
      if result == null
        break
      end = result.range.start
      lastLength = result.matchText.length
      start = end
      count++
    if end == null
      return null
    if back
      end = utils.moveForwards @editor, end, lastLength
    new Range(lastPos, end)

  modifyLine: () ->
    start = @start.toArray()
    start[1] = 0
    count = 0
    endRow = Math.min(start[0] + @num - 1, @lastPos[0])
    endCol = @editor.lineTextForBufferRow(endRow).length
    return new Range(start, [endRow, endCol])

  modifyTextObject: (outer) ->
    start = @start.toArray()
    end = @start.toArray()
    start[1] = 0
    end[1] = @editor.lineTextForBufferRow(end[0]).length
    behind = @scanBackwardsThroughRegex([@start, start], @argRegex)
    if behind != null
      if outer
        behind = behind.range.start
      else
        behind = behind.range.end
    ahead = @scanForwardsThroughRegex([@start, end], @argRegex)
    if ahead != null
      if outer
        ahead = ahead.range.end
      else
        ahead = ahead.range.start
    if behind != null and ahead != null
      return new Range(behind, ahead, end)
    else if ahead != null
      console.log(behind, end)
      return @searchBehind(!outer, behind, end)
    else if behind != null
      return @searchAhead(!outer, ahead, end)
    else
      return null

  getSurroundRange: () ->
    start = @start
    end = @start
    pos1 = null
    pos2 = null
    oppoCharCount = 0
    while pos1 == null
      result = @scanBackwardsThroughRegex [start, [0, 0]], @argRegex
      if result == null
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
    while pos2 == null
      result = @scanForwardsThroughRegex [end, @lastPos], @argRegex
      if result == null
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

  scanForwardsThroughRegex: (searchRange, regex) =>
    result = null
    @editor.scanInBufferRange regex, searchRange, (hit) =>
      hit.stop()
      if hit.matchText != ''
        result = hit
    result

  scanBackwardsThroughRegex: (searchRange, regex) ->
    result = null
    @editor.backwardsScanInBufferRange regex, searchRange, (hit) =>
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
  's':
    'funcName': 'getSurroundRange'
    'regexStr': null
    'num': null
    'type': 'surroundObject'
    'args': []
  'i':
    'funcName': 'modifyTextObject'
    'regexStr': null
    'num': null
    'type': 'textObject'
    'args': [false]
  'a':
    'funcName': 'modifyTextObject'
    'regexStr': null
    'num': null
    'type': 'textObject'
    'args': [true]

doAction = (range, action, editor, type) ->
  if action == 'm'
    if type == 'motion'
      editor.setCursorBufferPosition(range.end)
  else if action == 'd'
    editor.setTextInBufferRange range, ''
  else if action == 's'
    editor.setSelectedBufferRange(range)
  else if action == 'p'
    editor.setTextInBufferRange range, atom.clipboard.read()
  else 
    atom.clipboard.write(range.toString())

module.exports = {
    ActionHandler
}
