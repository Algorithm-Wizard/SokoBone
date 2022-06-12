extends Node2D

const TILESIZE = 64

export(float) var speed :float = 2
export(float) var pushMult :float = .5

enum States {READY, MOVING, QUEUED}

var boxes := []
var moves := 0
var empty := 0
var width := 0
var height := 0
var playerPos := Vector2.ZERO
var walking = false
var currLevel = 0
var state = States.READY
var moveQ := Vector2()
var moveL := "idle_s"

onready var player :AnimatedSprite = $Player
onready var foreground :TileMap = $Stone
onready var background :Sprite = $Dirt
onready var goals :TileMap = $Goals
onready var score :Label = $UI/Score
onready var crates :Node2D = $Crates
onready var Crate :PackedScene = preload("res://Crate.tscn")
onready var tween :Tween= $Tween

func _ready():
	startLevel(currLevel)

func movePlayer(direction :Vector2):
	match(state):
		States.READY:
			var walk :String
			var idle :String
			match(direction):
				Vector2.UP:
					walk = "walk_n"
					idle = "idle_n"
				Vector2.DOWN:
					walk = "walk_s"
					idle = "idle_s"
				Vector2.LEFT:
					walk = "walk_w"
					idle = "idle_w"
				Vector2.RIGHT:
					walk = "walk_e"
					idle = "idle_e"
				_:
					return
			var next := playerPos + direction
			var ccrate = getCratev(next)
			var cnext = next + direction
			if isWall(next):
				player.play(idle)
			elif ccrate and isWall(cnext):
				player.play(idle)
			elif ccrate and getCratev(cnext):
				player.play(idle)
			else:
				if ccrate:
					player.speed_scale = speed * pushMult
					tween.interpolate_property(ccrate, "position", next * TILESIZE, cnext * TILESIZE, 1 / player.speed_scale)
					boxes[cnext.y][cnext.x] = ccrate
					boxes[next.y][next.x] = null
					if goals.get_cellv(next) == Goals.FULL:
						goals.set_cellv(next, Goals.EMPTY)
						empty += 1
					if goals.get_cellv(cnext) == Goals.EMPTY:
						goals.set_cellv(cnext, Goals.FULL)
						empty -= 1
					moves += 1
					updateScore()
				else:
					player.speed_scale = speed
				state = States.MOVING
				player.play(walk)
				moveL = idle
				tween.interpolate_property(player, "position", playerPos * TILESIZE, next * TILESIZE, 1 / player.speed_scale)
				tween.start()
				playerPos = next
		States.MOVING:
			state = States.QUEUED
			moveQ = direction

func isWall(pos :Vector2) -> bool:
	if pos.x < 0 or pos.y < 0:
		return true
	if pos.x >= width or pos.y >= height:
		return true
	return foreground.get_cellv(pos) == Stone.WALL

func getCratev(pos :Vector2) -> Sprite:
	if pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height:
		return boxes[pos.y][pos.x]
	return null

func _on_Tween_tween_completed(object, key):
	if object != player:
		return
	if state == States.QUEUED:
		state = States.READY
		movePlayer(moveQ)
	else:
		player.play(moveL)
		state = States.READY

func updateScore():
	score.text = "Level %d\nMoves %d\nOpen %d" % [(currLevel + 1), moves, empty]

func startLevel(level :int):
	tween.remove_all()
	state = States.READY
	moves = 0
	empty = 0
	playerPos = Vector2.ZERO
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
	boxes.resize(height)
	for row in data:
		width = max(width, row.length())
	background.region_rect.size = TILESIZE * Vector2(width, height)
	for row in height:
		boxes[row] = []
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
	updateScore()

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

func _on_Controls_pressed(direction :Vector2):
	movePlayer(direction)
