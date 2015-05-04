{Disposable, CompositeDisposable} = require 'atom'

disposables = new CompositeDisposable()

do_action = (num, action, func, arg) ->
  console.log('num', num)
  console.log('action', action)
  console.log('func', func)
  console.log('func', arg)

searchForwardsUntilRegex = (regex, cursor) ->


FUNCTIONS =
  'f': searchForwardsUntilRegex

module.exports = {
    do_action
}
