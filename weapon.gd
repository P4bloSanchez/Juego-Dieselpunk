extends Node2D
@export var reload_time : float = 0.2
@export var bullet : PackedScene
@export var damage : float = 1
@export var bullet_speed = 1000
var reloaded = true
@export var enemy_weapon : bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	$ReloadTimer.wait_time = reload_time
	if enemy_weapon:
		$ReloadTimer.start()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func _on_reload_timer_timeout():
	reloaded = true
	if enemy_weapon:
		shoot()
	
func shoot():
	if reloaded:
		var b = bullet.instantiate()
		b.bullet_damage = damage
		b.bullet_speed = bullet_speed
		b.global_transform = global_transform
		get_tree().get_root().call_deferred("add_child", b)
		reloaded = false
		$ReloadTimer.start()
