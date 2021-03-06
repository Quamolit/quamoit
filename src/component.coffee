
_ = require 'lodash'

time = require './util/time'
tool = require './util/tool'

creator = require './creator'

module.exports = class Component
  constructor: (configs) ->
    @name = 'default' # name or id must be defined
    @category = 'component' # or shape
    # state machine of component lifecycle
    @period = 'stable' # [delay entering changing stable postpone leaving]
    @jumping = no # true during base changing

    _.assign @, configs.options
    @id = configs.id
    @base = configs.base
    @props = configs.props
    @layout = configs.layout
    @manager = configs.manager

    @viewport = @manager.getViewport()
    @onEnterCalls = []
    @onDestroyCalls = []

    @state = @getInitialState()
    @connectStoreState()
    @area = {} # position that merges base, layout, and lastArea
    @cache =
      frame: {}
      frameTime: 0 # time entered current state, in number
      area: {}
      areaTime: 0

    @onNewComponent()

    # extra state for animations
    @frame = @getEnteringKeyframe()
    @keyframe = @getKeyframe()

  # animation parameters
  getDuration: -> @props?.duration or 400
  getBezier: -> (x) -> x # linear by default
  getDelay: -> @layout?.delay or 0

  # initial states
  getInitialState: -> {}
  getKeyframe: -> {} # saves to this.keyframe
  getEnteringKeyframe: -> {}
  getLeavingKeyframe: -> {}
  # user rendering method like React
  render: null # function
  # functions called in entering periods
  onNewComponent: ->


  # will be binded to manager
  setPeriod: (name) ->
    debugger if name is 'postpone'
    @period = name
    @cache.frameTime = time.now()
    @cache.frame = _.cloneDeep @frame

  setState: (data) ->
    # console.info "setState at #{@id}:", data
    _.assign @state, data
    @setPeriod 'changing'
    @keyframe = @getKeyframe()

  checkBase: (base) ->
    return if (base.id is @base.id) and (base.index is @base.index)
    @cache.area = _.cloneDeep @area
    @cache.areaTime = time.now()
    @jumping = yes

  checkProps: (props) ->
    return if _.isEqual props, @props
    # console.log 'changing', props, @props
    @props = props
    @setPeriod 'changing'
    @keyframe = @getKeyframe()

  internalRender: ->
    @touchTime = @manager.touchTime
    unless @jumping
      @area = tool.combine @base, @layout
    factory = @render()
    switch @category
      when 'shape'
        @canvas = factory @base, @manager
        @expandChildren @base.children
      when 'component'
        factory = [factory] unless _.isArray factory
        # flattern array, in case of this.base.children
        factory = creator.fillList (_.flatten factory)
        @expandChildren factory

  expandChildren: (children) ->
    children = [children] unless _.isArray children
    children.map (f, index) =>
      childBase =
        index: index
        id: @id
        z: @base.z.concat index
        x: @area.x + (@frame.x or 0)
        y: @area.y + (@frame.y or 0)
      f childBase, @manager

  # listens to updates from store
  connectStoreState: ->
    return unless @stores?
    for stateName, value of @stores
      [store, getter, query] = value
      @state[stateName] = store.get getter, query
      f = =>
        newState = {}
        newState[stateName] = store.get getter, query
        @setState newState
      store.register f
      @onDestroyCalls.push -> store.unregister f
