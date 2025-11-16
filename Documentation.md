# Documentación del Código

## main_scene.gd  

```Código
extends Node2D 
var points : int = 0  # Contador de puntos del jugador 
var boss_active = false  # Bandera para saber si el jefe está activo 
func _ready(): 
$Ui.update_points(points)  # Actualiza la UI con los puntos iniciales 
func _on_player_health_changed(current, max): 
$Ui.update_health(current, max)  # Cuando la vida del jugador cambia, 
actualiza la barra de salud 
func _on_player_player_died(): 
$Ui.show_player_died()  # Muestra el mensaje de "Game Over" cuando el 
jugador muere 
func _on_enemy_died(): 
points += 1  # Suma 1 punto por enemigo muerto 
$Ui.update_points(points)  # Actualiza la UI con los nuevos puntos 
# Cada 100 puntos, cura al jugador completamente 
if points % 100 == 0: 
$Player.heal($Player.max_hp) 
func _on_map_enemy_spawned(enemy): 
enemy.enemy_died.connect(_on_enemy_died)  # Conecta la señal de muerte 
del enemigo para contar puntos 
func _on_map_boss_appeared(boss): 
boss_active = true  # Marca que el jefe está activo 
boss.boss_died.connect(_on_boss_died)  # Conecta señal de muerte del jefe 
boss.health_changed.connect(_on_boss_health_changed)  # Conecta cambios 
de vida del jefe 
$Ui.show_boss_bar(boss.max_hp)  # Muestra la barra de vida del jefe 
func _on_boss_died(): 
points += 100  # Da 100 puntos por matar al jefe 
$Ui.update_points(points) 
$Ui.hide_boss_bar()  # Oculta la barra del jefe 
$Ui.show_victory()  # Muestra mensaje de victoria 
func _on_boss_health_changed(current, max): 
$Ui.update_boss_health(current, max)  # Actualiza la barra de vida del jefe 
```


---

## player.gd  

```Código
extends CharacterBody2D 
@export var speed:float = 400  # Velocidad de movimiento, modificable desde el 
editor 
@onready var current_weapon = $Weapon  # Referencia al nodo arma 
@export var max_hp : float = 40  # Vida máxima 
var current_hp : float  # Vida actual 
signal health_changed(current, max)  # Señal para notificar cambios de vida 
signal player_died  # Señal cuando el jugador muere 
func _ready(): 
current_hp = max_hp  # Inicia con vida completa 
health_changed.emit(current_hp, max_hp)  # Emite señal inicial 
func _process(delta): 
if Input.is_action_pressed("shoot"): 
current_weapon.shoot()  # Si mantiene presionado el botón de disparo, 
se ejecuta el disparo 
func _physics_process(delta): 
# Obtiene dirección de movimiento con teclas devuelve Vector2 de dirección 
var direction = Input.get_vector("left", "right", "up", "down") 
velocity = direction * speed  # Calcula velocidad 
move_and_slide()  # Mueve al personaje y maneja colisiones 
func take_damage(damage): 
current_hp -= damage  # Resta daño 
current_hp = clamp(current_hp, 0, max_hp)  # Asegura que esté entre 0 y 
max_hp 
health_changed.emit(current_hp, max_hp)  # Notifica cambio de vida 
if current_hp <= 0: 
die()  # Si llega a 0, el jugador muere 
func heal(amount): 
current_hp += amount  # Suma curación 
current_hp = clamp(current_hp, 0, max_hp)  # No puede exceder el máximo 
health_changed.emit(current_hp, max_hp) 
func die(): 
player_died.emit()  # Emite señal de muerte 
queue_free()  # Elimina el nodo del juego 
```


---

## map.gd  

```Código
extends Node2D 
@export var enemy_to_spawn: PackedScene  # Escena del enemigo a spawnear 
@export var boss_scene: PackedScene  # Escena del jefe 
@onready var shapeSize = $SpawnArea/CollisionShape2D.shape.extents  # Tamaño 
del área de spawn 
@onready var origin = $SpawnArea/CollisionShape2D.global_position  # Centro del 
área 
@onready var spawnStart = origin - shapeSize  # Esquina superior izquierda 
@onready var spawnEnd = origin + shapeSize  # Esquina inferior derecha 
var boss_spawned = false  # Controla si el jefe ya apareció 
var game_time = 0  # Tiempo transcurrido de juego 
@export var boss_spawn_time = 60.0  # Jefe aparece después de 60 segundos 
signal enemy_spawned(enemy)  # Señal al generar el enemigo 
signal boss_appeared(boss)  # Señal al aparecer el jefe 
func _ready(): 
pass 
func _process(delta): 
if not boss_spawned: 
game_time += delta  # Cuenta el tiempo de juego 
if game_time >= boss_spawn_time: 
spawn_boss()  # Si llega al tiempo, genera el jefe 
func _on_spawn_timer_timeout(): 
if boss_spawned: 
return  # Si el jefe ya apareció, no genera más enemigos 
# Genera posición aleatoria dentro del área 
var x = randf_range(spawnStart.x, spawnEnd.x) 
var y = randf_range(spawnStart.y, spawnEnd.y) 
var e = enemy_to_spawn.instantiate()  # Inicia spawneo de enemigos 
e.position = Vector2(x,y) 
call_deferred("add_child", e)  # Añade nodo cuando termines el proceso 
anterior 
enemy_spawned.emit(e)  # Emite señal con el enemigo creado 
func spawn_boss(): 
boss_spawned = true 
$SpawnTimer.stop()  # Detiene la generación de enemigos 
# Elimina todos los enemigos restantes 
for child in get_children(): 
if child.is_in_group("enemies"): 
child.queue_free() 
# Crea el jefe en el centro superior de la pantalla 
var boss = boss_scene.instantiate() 
boss.position = Vector2(get_viewport_rect().size.x / 2, 100) 
call_deferred("add_child", boss) 
boss_appeared.emit(boss) 
func _on_remove_area_body_entered(body): 
body.queue_free()  # Elimina lo que entre en el área de eliminación 
```
---

## enemy.gd  

```Código
extends CharacterBody2D 
@export var speed: float = 100  # Velocidad de movimiento 
@export var direction: Vector2 = Vector2.DOWN  # Dirección, hacia abajo de forma 
predeterminada. 
@export var max_hp : float = 2  # Vida máxima 
var current_hp : float  # Vida actual 
@export var collision_damage = 5  # Daño al chocar con jugador 
signal health_changed(current, max) 
signal enemy_died 
func _ready(): 
current_hp = max_hp 
health_changed.emit(current_hp, max_hp) 
func _process(delta): 
pass 
func _physics_process(delta): 
velocity = direction.normalized() * speed  # Calcula velocidad en la dirección 
look_at(position + velocity)  # Rota para mirar hacia donde se mueve 
rotation += PI/2  # Ajusta 90 grados porque el sprite cae hacia abajo pero 
apuntando a otro lado. 
var collision = move_and_collide(velocity * delta)  # Mueve y detecta colisiones 
if collision: 
var body = collision.get_collider()  # Obtiene con qué chocó 
print('Enemy smashed into ', body.name) 
if body.has_method("take_damage"): 
body.take_damage(collision_damage)  # Si puede recibir daño, se 
ejecuta/realiza 
func take_damage(damage): 
current_hp -= damage 
current_hp = clamp(current_hp, 0, max_hp) 
health_changed.emit(current_hp, max_hp) 
if current_hp <= 0: 
die() 
func die(): 
enemy_died.emit()  # Emite señal de muerte 
queue_free()  # Se elimina del juego 
```


---

## bullet.gd  

```Código
extends CharacterBody2D 
var bullet_speed = 1  # Velocidad  
var bullet_damage = 1  # Daño 
func _ready(): 
velocity = -transform.y * bullet_speed  # Velocidad hacia arriba local 
func _process(delta): 
pass 
func _physics_process(delta): 
var collision = move_and_collide(velocity * delta)  # Mueve y detecta colisión 
if collision: 
var body = collision.get_collider() 
if body.has_method("take_damage"): 
body.take_damage(bullet_damage)  # Hace daño al objetivo 
queue_free()  # La bala se destruye al impactar 
func _on_life_timer_timeout(): 
queue_free()  # Se destruye después de cierto tiempo para no saturar la 
memoria 
```


---

## weapon.gd  

```Código
extends Node2D 
@export var reload_time : float = 0.2  # Tiempo entre disparos 
@export var bullet : PackedScene  # Escena de la bala 
@export var damage : float = 1  # Daño de la bala 
@export var bullet_speed = 1000  # Velocidad de la bala 
var reloaded = true  # Controla si el arma está lista para disparar 
@export var enemy_weapon : bool = false  # Si es arma de enemigo, hay disparo 
automático 
func _ready(): 
$ReloadTimer.wait_time = reload_time  # Configura el timer 
if enemy_weapon: 
$ReloadTimer.start()  # Los enemigos empiezan a disparar 
automáticamente 
func _process(delta): 
 pass 
 
func _on_reload_timer_timeout(): 
 reloaded = true  # Recarga el arma 
 if enemy_weapon: 
  shoot()  # Enemigos disparan automáticamente 
  
func shoot(): 
 if reloaded: 
  var b = bullet.instantiate()  # Crea la bala 
  b.bullet_damage = damage  # Asigna el daño 
  b.bullet_speed = bullet_speed  # Asigna la velocidad 
  b.global_transform = global_transform  # Posición y rotación del arma 
  get_tree().get_root().call_deferred("add_child", b)  # Añade a la escena 
raíz 
  reloaded = false 
  $ReloadTimer.start()  # Enciende el cronómetro de recarga de arma 
```

---

## Ui.gd  

```Código
extends Control 
 
func _ready(): 
 if has_node("BossHealthBar"): 
  $BossHealthBar.hide()  # Oculta barra del jefe al inicio 
 if has_node("Victory"): 
  $Victory.hide()  # Oculta mensaje de victoria 
 
func _process(delta): 
 pass 
 
func update_health(current, max): 
 $HealthBar.max_value = max  # Define el valor máximo de la barra 
 $HealthBar.value = current  # Define el valor actual 
 
func update_points(points): 
 $PointsLabel.text = str(points)  # Muestra puntos como texto 
 
func show_player_died(): 
 $PlayerDied.show()  # Muestra "Game Over" 
 
func show_boss_bar(max_hp): 
 if has_node("BossHealthBar"): 
  $BossHealthBar.max_value = max_hp 
  $BossHealthBar.value = max_hp 
  $BossHealthBar.show()  # Muestra barra del jefe 
 
func update_boss_health(current, max): 
if has_node("BossHealthBar"): 
$BossHealthBar.value = current  # Actualiza la vida del jefe 
func hide_boss_bar(): 
if has_node("BossHealthBar"): 
$BossHealthBar.hide() 
func show_victory(): 
if has_node("Victory"): 
$Victory.show()  # Muestra el mensaje de victoria 
```
---

## boss.gd  

```Código
extends CharacterBody2D 
@export var max_hp : float = 200  # Vida máxima del jefe 
var current_hp : float 
@export var speed : float = 150 
@export var collision_damage = 10  # Daño al chocar 
@onready var weapons = [    
$Weapon1/Weapon, $Weapon2/Weapon, $Weapon3/Weapon, $Weapon4/Weapon, 
$Weapon5/Weapon, $Weapon6/Weapon, $Weapon7/Weapon, 
$Weapon8/Weapon 
] # lista con las 8 armas del jefe 
# Definir los patrones de movimiento 
enum MovePattern {HORIZONTAL, VERTICAL, CIRCLE} 
var current_pattern = MovePattern.HORIZONTAL  # Patrón actual 
var pattern_timer = 0.0  # Tiempo en el patrón actual 
var pattern_duration = 5.0  # Cambia patrón cada 5 segundos 
var screen_width 
var screen_height 
var min_y = 50  # No sube más arriba 
var max_y = 300  # No baja más abajo 
# Variables para movimiento circular 
var circle_center = Vector2.ZERO  # Centro del círculo 
var circle_radius = 100  # Radio del círculo 
var circle_angle = 0.0  # Ángulo actual 
var move_direction = 1  # Dirección: 1 = derecha/abajo, -1 = izquierda/arriba 
signal boss_died 
signal health_changed(current, max) 
func _ready(): 
 current_hp = max_hp 
 health_changed.emit(current_hp, max_hp) 
  
 var viewport = get_viewport_rect().size 
 screen_width = viewport.x  # Ancho de pantalla 
 screen_height = viewport.y  # Alto de pantalla 
  
 circle_center = Vector2(screen_width / 2, 150)  # Centro para movimiento 
circular 
  
 $ShootTimer.start()  # Inicia disparos automáticos 
 
func _physics_process(delta): 
 pattern_timer += delta  # Cuenta tiempo en patrón actual 
  
 # Cambia de patrón cada 5 segundos 
 if pattern_timer >= pattern_duration: 
  pattern_timer = 0.0 
  change_pattern() 
  
 # Ejecuta movimiento según patrón actual 
 match current_pattern: 
  MovePattern.HORIZONTAL: 
   move_horizontal(delta) 
  MovePattern.VERTICAL: 
   move_vertical(delta) 
  MovePattern.CIRCLE: 
   move_circle(delta) 
  
 move_and_slide()  # Aplica movimiento 
  
 # Maneja las colisiones con el jugador 
 for i in get_slide_collision_count(): 
  var collision = get_slide_collision(i) 
  var body = collision.get_collider() 
  if body.has_method("take_damage"): 
   body.take_damage(collision_damage) 
 
func move_horizontal(delta): 
 velocity.y = 0  # Sin movimiento vertical 
 velocity.x = move_direction * speed  # Movimiento horizontal 
  
 # Cambia dirección al llegar a los bordes 
 if position.x > screen_width - 100: 
  move_direction = -1 
 elif position.x < 100: 
  move_direction = 1 
  
 position.y = clamp(position.y, min_y, max_y)  # Mantiene Y en rango 
 
func move_vertical(delta): 
 velocity.x = 0  # Sin movimiento horizontal 
 velocity.y = move_direction * speed * 0.7  # Movimiento vertical más lento 
  
 # Cambia dirección al llegar arriba/abajo 
 if position.y > max_y: 
  move_direction = -1 
 elif position.y < min_y: 
  move_direction = 1 
 
func move_circle(delta): 
 circle_angle += delta * 2  # Incrementa el ángulo de la velocidad de rotación  
 # Calcula posición en el círculo 
 var target_x = circle_center.x + cos(circle_angle) * circle_radius 
 var target_y = circle_center.y + sin(circle_angle) * circle_radius 
  
 target_y = clamp(target_y, min_y, max_y)  # Mantiene Y en los límites 
  
 # Velocidad hacia la posición objetivo 
 velocity = (Vector2(target_x, target_y) - position).normalized() * speed 
 
func change_pattern(): 
 var patterns = [MovePattern.HORIZONTAL, MovePattern.VERTICAL, 
MovePattern.CIRCLE] 
 var new_pattern = patterns[randi() % patterns.size()]  # Elige patrón aleatorio 
  
 # Evita repetir el mismo patrón 
 while new_pattern == current_pattern: 
  new_pattern = patterns[randi() % patterns.size()] 
  
 current_pattern = new_pattern 
  
 # Reinicia variables para movimiento circular 
 if current_pattern == MovePattern.CIRCLE: 
  circle_center = position  # Centro = posición actual 
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
# Todas las armas disparan simultáneamente (corregir) 
for weapon in weapons: 
if weapon: 
weapon.shoot() 
```
