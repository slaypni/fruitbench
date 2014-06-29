#!/usr/bin/env coffee

sys = require 'sys'
fs = require 'fs'
vm = require 'vm'
_ = require 'underscore'
argv = (require 'yargs').argv


class Game
  constructor: ->
    @_typesNum = _.random 3, 5
    @_totalItemCounts = _.object ([i, (i * 2) - 1] for i in [1..@_typesNum])
    size = _.random 5, 10
    cells = (0 for x in [0...(size * size)])
    items = 
      for t in [1..@_typesNum]
        (t for i in [0...@_totalItemCounts[t]])
    items = _.flatten items, true
    for i in [0...items.length]
      cells[i] = items[i]
    cells = _.shuffle cells
    @_board = ((cells[i + j * size] for i in [0...size]) for j in [0...size])

    loc = {x: (_.random (size - 1)), y: (_.random (size - 1))}
    @_myLocation = _.clone loc
    @_opLocation = _.clone loc

    itemCounts = _.object ([t, 0] for t in [1..@_typesNum])
    @_myItemCounts = _.clone itemCounts
    @_opItemCounts = _.clone itemCounts

    @WIDTH = size
    @HEIGHT = size

    @PASS = 0
    @TAKE = 1
    @SOUTH = 2
    @NORTH = 3
    @EAST = 4
    @WEST = 5

    @_isInit = true

  get_board: =>
    _.clone @_board

  get_my_x: =>
    @_myLocation.x

  get_my_y: =>
    @_myLocation.y

  get_opponent_x: =>
    @_opLocation.x

  get_opponent_y: =>
    @_opLocation.y

  get_number_of_item_types: =>
    @_typesNum

  get_total_item_count: (t) =>
    @_totalItemCounts[t]

  get_my_item_count: (t) =>
    @_myItemCounts[t]

  get_opponent_item_count: (t) =>
    @_opItemCounts[t]

  _invert: =>
    g = _.clone @
    tmp = g._myLocation
    g._myLocation = g._opLocation
    g._opLocation = tmp
    tmp = g._myItemCounts
    g._myItemCounts = g._opItemCounts
    g._opItemCounts = tmp
    return g

  _move: (myMove, opMove) =>
    @_isInit = false
    mv = {}
    mv[@PASS] = [0, 0]
    mv[@TAKE] = [0, 0]
    mv[@SOUTH] = [0, 1]
    mv[@NORTH] = [0, -1]
    mv[@EAST] = [1, 0]
    mv[@WEST] = [-1, 0]

    for [move, location] in [[myMove, @_myLocation], [opMove, @_opLocation]]
      location.x += mv[move][0]
      location.y += mv[move][1]

    score = 1
    score = 0.5 if myMove == opMove == @TAKE and _.isEqual @_myLocation, @_opLocation
    for [move, location, items] in [[myMove, @_myLocation, @_myItemCounts], [opMove, @_opLocation, @_opItemCounts]]
      if move == @TAKE
        type = @_board[location.x][location.y]
        items[type] += score if type > 0
    for [move, location] in [[myMove, @_myLocation], [opMove, @_opLocation]]      
      @_board[location.x][location.y] = 0 if move == @TAKE

  _copy: (_game) =>
    @_board = _game._board
    @_myLocation = _game._myLocation
    @_opLocation = _game._opLocation
    @_myItemCounts = _game._myItemCounts
    @_opItemCounts = _game._opItemCounts
    @_isInit = _game._isInit
    
    @_typesNum = _game._typesNum
    @_totalItemCounts = _game._totalItemCounts
    @WIDTH = _game.WIDTH
    @HEIGHT = _game.HEIGHT
    return @

  _getResult: =>
    myScore = ((if @_myItemCounts[t] > (@_totalItemCounts[t] / 2) then 1 else if @_myItemCounts[t] == (@_totalItemCounts[t] / 2) then 0.5 else 0) for t in [1..@_typesNum]).reduce (a, b) -> a + b
    opScore = ((if @_opItemCounts[t] > (@_totalItemCounts[t] / 2) then 1 else if @_opItemCounts[t] == (@_totalItemCounts[t] / 2) then 0.5 else 0) for t in [1..@_typesNum]).reduce (a, b) -> a + b
    return 'win' if myScore > @_typesNum / 2
    return 'lose' if opScore > @_typesNum / 2
    return 'tie' if myScore == opScore == @_typesNum / 2
    return null

mybotPath = './mybot.js'
mybotData = fs.readFileSync mybotPath, 'utf8'
opbotPath = './opbot.js'
opbotData = fs.readFileSync opbotPath, 'utf8'

iterNum = if argv.n? then argv.n else 100
result =
  win: 0
  tie: 0
  lose: 0

for i in [0...iterNum]
  process.stdout.write "\rSimulating games... (#{i+1}/#{iterNum}) [w:#{result.win} t:#{result.tie} l:#{result.lose}]"
  
  game = new Game()
  mybot = (new Game())._copy game
  opbot = (new Game())._copy game
   
  while not game._getResult()?
    for [data, bot, path] in [[mybotData, mybot, mybotPath], [opbotData, opbot, opbotPath]]
      vm.runInNewContext data, bot
      bot.new_game?() if game._isInit
    myMove = mybot.make_move()
    opMove = opbot.make_move()
    game._move myMove, opMove
    mybot._copy game
    opbot._copy game._invert()
    
  result[game._getResult()]++

process.stdout.write "\rwin: #{result.win}, tie: #{result.tie}, lose: #{result.lose} (out of #{iterNum} trials)\n"
