extends Node2D

const PLAYER_SPEED := 390.0
const ENEMY_SPEED := 235.0
const ORB_SPEED := 190.0
const FONT_COLOR := Color("#f4f7ff")

var player := Vector2.ZERO
var enemies: Array[Dictionary] = []
var orbs: Array[Vector2] = []
var spawn_clock := 0.0
var orb_clock := 0.0
var score := 0
var lives := 3
var running := false
var game_over := false
var best := 0
var flash := 0.0

func _ready() -> void:
	get_window().title = "WEB RUNNER | Godot"
	_reset_round()

func _reset_round() -> void:
	var bounds := get_viewport_rect().size
	player = Vector2(bounds.x * 0.5, bounds.y * 0.78)
	enemies.clear()
	orbs.clear()
	spawn_clock = 0.0
	orb_clock = 0.7
	score = 0
	lives = 3
	game_over = false
	running = false
	flash = 0.0
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if not running:
			if game_over:
				_reset_round()
			running = true
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed and not running:
		if game_over:
			_reset_round()
		running = true
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if flash > 0.0:
		flash = maxf(0.0, flash - delta)
	if running:
		var bounds := get_viewport_rect().size
		var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		player += direction * PLAYER_SPEED * delta
		player.x = clampf(player.x, 34.0, bounds.x - 34.0)
		player.y = clampf(player.y, 96.0, bounds.y - 34.0)
		spawn_clock -= delta
		if spawn_clock <= 0.0:
			spawn_clock = maxf(0.30, 0.88 - float(score) * 0.004) * randf_range(0.72, 1.2)
			var radius := randf_range(15.0, 26.0)
			enemies.append({"pos": Vector2(randf_range(40.0, bounds.x - 40.0), -radius), "r": radius, "vx": randf_range(-45.0, 45.0)})
		orb_clock -= delta
		if orb_clock <= 0.0:
			orb_clock = randf_range(1.8, 2.8)
			orbs.append(Vector2(randf_range(36.0, bounds.x - 36.0), -18.0))
		_update_objects(delta, bounds)
	queue_redraw()

func _update_objects(delta: float, bounds: Vector2) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		var pos: Vector2 = enemy["pos"]
		pos.y += (ENEMY_SPEED + minf(float(score), 300.0) * 0.65) * delta
		pos.x += float(enemy["vx"]) * delta
		enemy["pos"] = pos
		if pos.x < 28.0 or pos.x > bounds.x - 28.0:
			enemy["vx"] = -float(enemy["vx"])
		if pos.y > bounds.y + 40.0:
			enemies.remove_at(i)
			continue
		if pos.distance_to(player) < float(enemy["r"]) + 17.0:
			enemies.remove_at(i)
			lives -= 1
			flash = 0.28
			if lives <= 0:
				best = maxi(best, score)
				running = false
				game_over = true
			return
	for i in range(orbs.size() - 1, -1, -1):
		orbs[i].y += ORB_SPEED * delta
		if orbs[i].distance_to(player) < 26.0:
			orbs.remove_at(i)
			score += 25
			continue
		if orbs[i].y > bounds.y + 20.0:
			orbs.remove_at(i)
			score += 1
		else:
			score += 1

func _draw() -> void:
	var size := get_viewport_rect().size
	_draw_background(size)
	_draw_hud(size)
	for orb in orbs:
		_draw_orb(orb)
	for enemy in enemies:
		_draw_enemy(enemy["pos"], float(enemy["r"]))
	_draw_player(player)
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.18, 0.28, flash * 0.46), true)
	if not running:
		_draw_card(size)

func _draw_background(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#090e1b"), true)
	for x in range(0, int(size.x) + 1, 48):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.3, 0.68, 0.88, 0.075), 1.0)
	for y in range(0, int(size.y) + 1, 48):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.3, 0.68, 0.88, 0.075), 1.0)
	for x in range(0, int(size.x) + 1, 96):
		for y in range(0, int(size.y) + 1, 96):
			draw_circle(Vector2(x, y), 2.0, Color(0.44, 0.83, 0.95, 0.16))

func _draw_hud(size: Vector2) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	draw_string(font, Vector2(28, 42), "WEB RUNNER", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#56d9f6"))
	draw_string(font, Vector2(28, 68), "MOVE  WASD / ARROWS     •     COLLECT CYAN ORBS     •     DODGE RED DRONES", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#93a9c5"))
	draw_string(font, Vector2(size.x - 28, 42), "SCORE  %05d" % score, HORIZONTAL_ALIGNMENT_RIGHT, -1, 20, FONT_COLOR)
	var hearts := "♥  ".repeat(maxi(0, lives)).strip_edges()
	draw_string(font, Vector2(size.x - 28, 69), hearts if lives > 0 else "", HORIZONTAL_ALIGNMENT_RIGHT, -1, 18, Color("#ff5f78"))

func _draw_player(pos: Vector2) -> void:
	var font := ThemeDB.fallback_font
	draw_line(pos + Vector2(-6, -5), pos + Vector2(-25, -25), Color("#8ee9ff"), 2.0)
	draw_line(pos + Vector2(6, -5), pos + Vector2(25, -25), Color("#8ee9ff"), 2.0)
	draw_circle(pos + Vector2(0, 3), 17.0, Color("#197bb9"))
	draw_circle(pos + Vector2(0, -5), 12.0, Color("#eb425b"))
	draw_circle(pos + Vector2(0, -5), 8.0, Color("#e5f5ff"))
	draw_line(pos + Vector2(-7, -5), pos + Vector2(7, -5), Color("#197bb9"), 2.0)
	draw_circle(pos + Vector2(-5, -5), 1.7, Color.WHITE)
	draw_circle(pos + Vector2(5, -5), 1.7, Color.WHITE)

func _draw_enemy(pos: Vector2, radius: float) -> void:
	draw_circle(pos + Vector2(0, 3), radius + 2.0, Color(1.0, 0.25, 0.37, 0.16))
	draw_circle(pos, radius, Color("#f04e62"))
	draw_circle(pos, radius * 0.66, Color("#631e3a"))
	draw_circle(pos + Vector2(-radius * 0.28, -radius * 0.12), 2.4, Color("#ffe8ee"))
	draw_circle(pos + Vector2(radius * 0.28, -radius * 0.12), 2.4, Color("#ffe8ee"))

func _draw_orb(pos: Vector2) -> void:
	draw_circle(pos, 15.0, Color(0.16, 0.88, 1.0, 0.16))
	draw_circle(pos, 8.0, Color("#43e5f5"))
	draw_circle(pos, 3.0, Color("#e1ffff"))

func _draw_card(size: Vector2) -> void:
	var card := Rect2(size * 0.5 - Vector2(214, 112), Vector2(428, 224))
	draw_rect(card, Color(0.045, 0.075, 0.13, 0.93), true)
	draw_rect(card, Color("#43d8f2"), false, 2.0)
	var font := ThemeDB.fallback_font
	if font == null:
		return
	if game_over:
		draw_string(font, card.position + Vector2(0, 55), "RUN OVER", HORIZONTAL_ALIGNMENT_CENTER, card.size.x, 31, Color("#ff6179"))
		draw_string(font, card.position + Vector2(0, 91), "SCORE  %d     BEST  %d" % [score, best], HORIZONTAL_ALIGNMENT_CENTER, card.size.x, 17, FONT_COLOR)
		draw_string(font, card.position + Vector2(0, 151), "PRESS ENTER OR CLICK TO PLAY AGAIN", HORIZONTAL_ALIGNMENT_CENTER, card.size.x, 14, Color("#a9bdd3"))
	else:
		draw_string(font, card.position + Vector2(0, 56), "WEB RUNNER", HORIZONTAL_ALIGNMENT_CENTER, card.size.x, 31, Color("#54e1fa"))
		draw_string(font, card.position + Vector2(0, 96), "DODGE THE DRONES. GRAB THE GLOW.", HORIZONTAL_ALIGNMENT_CENTER, card.size.x, 15, FONT_COLOR)
		draw_string(font, card.position + Vector2(0, 153), "PRESS ENTER OR CLICK TO START", HORIZONTAL_ALIGNMENT_CENTER, card.size.x, 15, Color("#a9bdd3"))
