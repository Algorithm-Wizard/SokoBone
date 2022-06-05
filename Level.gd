extends Node2D

const TILESIZE = 64

export(float) var speed :float = 2
export(float) var pushMult :float = .8

enum States {READY, MOVING, QUEUED}
enum Face {NORTH, SOUTH, EAST, WEST, NONE}

var boxes := []
var moves := 0
var empty := 0
var width := 0
var height := 0
var playerPos := Vector2.ZERO
var walking = false
var currLevel = 0
var state = States.READY
var moveQ = Face.NONE
var moveL := "idle_s"

onready var background :Sprite = $Dirt
onready var foreground :TileMap = $Stone
onready var goals :TileMap = $Goals
onready var score :Label = $UI/Score
onready var crates :Node2D = $Crates
onready var Crate :PackedScene = preload("res://Crate.tscn")
onready var player :AnimatedSprite = $Player
onready var tween :Tween= $Tween

func _ready():
	startLevel(currLevel)

func _process(delta):
	var direction = Face.NONE
	if Input.is_action_just_pressed("ui_down"):
		direction = Face.SOUTH
	elif Input.is_action_just_pressed("ui_up"):
		direction = Face.NORTH
	elif Input.is_action_just_pressed("ui_left"):
		direction = Face.WEST
	elif Input.is_action_just_pressed("ui_right"):
		direction = Face.EAST
	if direction != Face.NONE:
		movePlayer(direction)

func movePlayer(direction):
	player.speed_scale = speed
	match(state):
		States.READY:
			state = States.MOVING
			var next := playerPos
			match(direction):
				Face.SOUTH:
					if canMove(Vector2.DOWN):
						next += Vector2.DOWN
						player.play("walk_s")
						moveL = "idle_s"
				Face.NORTH:
					next += Vector2.UP
					player.play("walk_n")
					moveL = "idle_n"
				Face.WEST:
					next += Vector2.LEFT
					player.play("walk_w")
					moveL = "idle_w"
				Face.EAST:
					next += Vector2.RIGHT
					player.play("walk_e")
					moveL = "idle_e"
			tween.interpolate_property(player, "position", playerPos * TILESIZE, next * TILESIZE, 1 / speed)
			tween.start()
			playerPos = next
		States.MOVING:
			state = States.QUEUED
			moveQ = direction

func canMove(direction :Vector2)->bool:
	var dest := playerPos + direction
	if isWall(dest):
		return false
	return true

func isWall(pos :Vector2)->bool:
	if pos.x < 0 or pos.y < 0:
		return true
	if pos.x >= width or pos.y >= height:
		return true
	return false

func _on_Tween_tween_completed(object, key):
	if state == States.QUEUED:
		state = States.READY
		movePlayer(moveQ)
	else:
		player.play(moveL)
		state = States.READY

func startLevel(level :int):
	tween.remove_all()
	state = States.READY
	moves = 0
	empty = 0
	playerPos = Vector2.ZERO
	score.text = "Level %d\nMoves %d" % [(currLevel + 1), moves]
	foreground.clear()
	goals.clear()
	for row in boxes:
		for cell in row:
			if cell != null:
				crates.remove_child(cell)
				(cell as Node).queue_free()
	boxes.clear()
	var data = LevelData.DATA[level]
	width = 0
	height = data.size()
	for row in data:
		width = max(width, row.length())
		boxes.append([])
	background.region_rect.size = TILESIZE * Vector2(width, height)
	for row in height:
		boxes[row].resize(width)
		var line:String = data[row]
		line += " ".repeat(width - line.length())
		for col in width:
			boxes[row][col] = null
			var cell :String = line[col]
			if cell in ["@", "+"]:
				playerPos = Vector2(col, row)
			if cell == "#":
				foreground.set_cell(col, row, Stone.WALL)
			if cell in ["*", "$"]:
				var crate = Crate.instance()
				crates.add_child(crate)
				crate.position = Vector2(col, row) * TILESIZE
				boxes[row][col] = crate
			if cell in [".", "+"]:
				goals.set_cell(col, row, Goals.EMPTY)
				empty += 1
			if cell == "*":
				goals.set_cell(col, row, Goals.FULL)
	player.position = playerPos * TILESIZE
	floorFill(playerPos.x, playerPos.y)

func floorFill(x :int, y :int):
	var empty = TileMap.INVALID_CELL
	if foreground.get_cell(x, y) == TileMap.INVALID_CELL:
		foreground.set_cell(x, y, Stone.FLOOR)
	if x < width - 1 and foreground.get_cell(x + 1, y) == empty:
		floorFill(x + 1, y)
	if x > 0 and foreground.get_cell(x - 1, y) == empty:
		floorFill(x - 1, y)
	if y < height - 1 and foreground.get_cell(x, y + 1) == empty:
		floorFill(x, y + 1)
	if y > 0 and foreground.get_cell(x, y - 1) == empty:
		floorFill(x, y - 1)

func _on_Reset_pressed():
	startLevel(currLevel)

func _on_Next_pressed():
	currLevel += 1
	currLevel %= LevelData.DATA.size()
	startLevel(currLevel)

func _on_Prev_pressed():
	currLevel += LevelData.DATA.size() - 1
	currLevel %= LevelData.DATA.size()
	startLevel(currLevel)
