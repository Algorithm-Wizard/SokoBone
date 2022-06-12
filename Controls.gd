extends Node2D

signal pressed(direction)
signal released

var low := 0.5
var high := 1.0
var ways := [Vector2.ZERO, Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]
var typed := 0
var clicked := 0

enum {NONE, RIGHT, UP, LEFT, DOWN}

onready var arrows :Sprite = $Arrows

func _process(delta):
	if clicked != NONE:
		return
	match (typed):
		NONE:
			if Input.is_action_pressed("ui_right"):
				typed = RIGHT
			elif Input.is_action_pressed("ui_up"):
				typed = UP
			elif Input.is_action_pressed("ui_left"):
				typed = LEFT
			elif Input.is_action_pressed("ui_down"):
				typed = DOWN
			if typed != NONE:
				emit_signal("pressed", ways[typed])
		RIGHT:
			if not Input.is_action_pressed("ui_right"):
				typed = NONE
		UP:
			if not Input.is_action_pressed("ui_up"):
				typed = NONE
		LEFT:
			if not Input.is_action_pressed("ui_left"):
				typed = NONE
		DOWN:
			if not Input.is_action_pressed("ui_down"):
				typed = NONE
	arrows.frame = typed

func _on_Selection_mouse_exited():
	if arrows.frame != NONE:
		clicked = NONE
		arrows.frame = NONE
		emit_signal("released")
	arrows.modulate.a = low

func _on_Selection_input_event(viewport, event, shape_idx):
	if typed != NONE:
		return
	if event is InputEventMouseButton:
		if event.pressed:
			if clicked != NONE:
				emit_signal("released")
			clicked = shape_idx + 1
			arrows.frame = clicked
			emit_signal("pressed", ways[clicked])
		else:
			clicked = NONE
			arrows.frame = clicked
			emit_signal("released")

func _on_Selection_mouse_entered():
	arrows.modulate.a = high
