extends Node2D

@export var enemy_to_spawn: PackedScene
@export var boss_scene: PackedScene
@onready var shapeSize = $SpawnArea/CollisionShape2D.shape.extents
@onready var origin = $SpawnArea/CollisionShape2D.global_position
@onready var spawnStart = origin - shapeSize
@onready var spawnEnd = origin + shapeSize

var boss_spawned = false
var game_time = 0
@export var boss_spawn_time = 60.0  # 60 segundos = 1 minuto

signal enemy_spawned(enemy)
signal boss_appeared(boss)

func _ready():
	pass

func _process(delta):
	if not boss_spawned:
		game_time += delta
		if game_time >= boss_spawn_time:
			spawn_boss()

func _on_spawn_timer_timeout():
	if boss_spawned:
		return
		
	var x = randf_range(spawnStart.x, spawnEnd.x)
	var y = randf_range(spawnStart.y, spawnEnd.y)
	var e = enemy_to_spawn.instantiate()
	e.position = Vector2(x,y)
	call_deferred("add_child", e)
	enemy_spawned.emit(e)

func spawn_boss():
	boss_spawned = true
	$SpawnTimer.stop()
	
	# Eliminar todos los enemigos existentes
	for child in get_children():
		if child.is_in_group("enemies"):
			child.queue_free()
	
	var boss = boss_scene.instantiate()
	boss.position = Vector2(get_viewport_rect().size.x / 2, 100)
	call_deferred("add_child", boss)
	boss_appeared.emit(boss)

func _on_remove_area_body_entered(body):
	body.queue_free()

func _on_boss_appeared(boss: Variant) -> void:
	pass # Replace with function body.
