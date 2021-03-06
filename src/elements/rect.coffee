
creator = require '../creator'

module.exports = creator.create
  name: 'rect'
  category: 'shape'
  period: 'stable'

  onClick: (event) ->
    @props.onClick? event

  coveredPoint: (x, y) ->
    return no unless @props.kind is 'fill'
    centerX = @base.x + (@layout.x or 0)
    centerY = @base.y + (@layout.y or 0)
    if (Math.abs(x - centerX) * 2) > @props.w then return no
    if (Math.abs(y - centerY) * 2) > @props.h then return no
    return yes

  render: ->
    (base, manager) =>
      type: 'rect'
      base:
        x: (@layout.x or 0) + base.x
        y: (@layout.y or 0) + base.y
      w: @props.w
      h: @props.h
      kind: @props.kind or 'fill'
      fillStyle: @props.color or 'blue'
      strokeStyle: @props.color or 'blue'
