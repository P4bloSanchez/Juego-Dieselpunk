extends CharacterBody2D

@export var speed:float = 400
@onready var current_weapon = $Weapon
@export var max_hp : float = 40
var current_hp : float

signal health_changed(current, max)
signal player_died

func _ready():
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)

func _process(delta):
	if Input.is_action_pressed("shoot"):
		current_weapon.shoot()

func _physics_process(delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	move_and_slide()

func take_damage(damage):
	current_hp -= damage
	current_hp = clamp(current_hp, 0, max_hp)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		die()

func heal(amount):
	current_hp += amount
	current_hp = clamp(current_hp, 0, max_hp)
	health_changed.emit(current_hp, max_hp)

func die():
	player_died.emit()
	queue_free()
