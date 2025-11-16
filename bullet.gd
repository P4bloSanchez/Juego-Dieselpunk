extends CharacterBody2D
var bullet_speed = 1
var bullet_damage = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	velocity = -transform.y * bullet_speed
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		var body = collision.get_collider()
		#print('Bullet hit ', body.name)
		if body.has_method("take_damage"):
			body.take_damage(bullet_damage)
		#explosion here??
		queue_free()

func _on_life_timer_timeout():
	queue_free()
