extends CharacterBody2D

@export var max_hp : float = 200
var current_hp : float
@export var speed : float = 150
@export var collision_damage = 10

@onready var weapons = [
	$Weapon1/Weapon, $Weapon2/Weapon, $Weapon3/Weapon, $Weapon4/Weapon,
	$Weapon5/Weapon, $Weapon6/Weapon, $Weapon7/Weapon, $Weapon8/Weapon
]

# Control de movimiento
enum MovePattern {HORIZONTAL, VERTICAL, CIRCLE}
var current_pattern = MovePattern.HORIZONTAL
var pattern_timer = 0.0
var pattern_duration = 5.0  # Cambiar patrón cada 5 segundos

# Límites de movimiento
var screen_width
var screen_height
var min_y = 50
var max_y = 300  # No baja tanto

# Variables para movimiento circular
var circle_center = Vector2.ZERO
var circle_radius = 100
var circle_angle = 0.0

var move_direction = 1

signal boss_died
signal health_changed(current, max)

func _ready():
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)
	
	var viewport = get_viewport_rect().size
	screen_width = viewport.x
	screen_height = viewport.y
	
	circle_center = Vector2(screen_width / 2, 150)
	
	$ShootTimer.start()

func _physics_process(delta):
	pattern_timer += delta
	
	# Cambiar patrón cada cierto tiempo
	if pattern_timer >= pattern_duration:
		pattern_timer = 0.0
		change_pattern()
	
	# Ejecutar patrón actual
	match current_pattern:
		MovePattern.HORIZONTAL:
			move_horizontal(delta)
		MovePattern.VERTICAL:
			move_vertical(delta)
		MovePattern.CIRCLE:
			move_circle(delta)
	
	move_and_slide()
	
	# Colisiones
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		if body.has_method("take_damage"):
			body.take_damage(collision_damage)

func move_horizontal(delta):
	velocity.y = 0
	velocity.x = move_direction * speed
	
	if position.x > screen_width - 100:
		move_direction = -1
	elif position.x < 100:
		move_direction = 1
	
	# Mantener Y en rango
	position.y = clamp(position.y, min_y, max_y)

func move_vertical(delta):
	velocity.x = 0
	velocity.y = move_direction * speed * 0.7  # Más lento vertical
	
	if position.y > max_y:
		move_direction = -1
	elif position.y < min_y:
		move_direction = 1

func move_circle(delta):
	circle_angle += delta * 2  # Velocidad rotación
	
	var target_x = circle_center.x + cos(circle_angle) * circle_radius
	var target_y = circle_center.y + sin(circle_angle) * circle_radius
	
	# Mantener en límites
	target_y = clamp(target_y, min_y, max_y)
	
	velocity = (Vector2(target_x, target_y) - position).normalized() * speed

func change_pattern():
	var patterns = [MovePattern.HORIZONTAL, MovePattern.VERTICAL, MovePattern.CIRCLE]
	var new_pattern = patterns[randi() % patterns.size()]
	
	# Evitar repetir el mismo patrón
	while new_pattern == current_pattern:
		new_pattern = patterns[randi() % patterns.size()]
	
	current_pattern = new_pattern
	
	# Reset para movimiento circular
	if current_pattern == MovePattern.CIRCLE:
		circle_center = position
		circle_angle = 0.0

func take_damage(damage):
	current_hp -= damage
	current_hp = clamp(current_hp, 0, max_hp)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		die()

func die():
	boss_died.emit()
	queue_free()

func _on_shoot_timer_timeout():
	for weapon in weapons:
		if weapon:
			weapon.shoot()
