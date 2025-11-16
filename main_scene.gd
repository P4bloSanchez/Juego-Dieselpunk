extends Node2D

var points : int = 0
var boss_active = false

func _ready():
	$Ui.update_points(points)

func _process(delta):
	pass

func _on_player_health_changed(current, max):
	$Ui.update_health(current, max)

func _on_player_player_died():
	$Ui.show_player_died()

func _on_enemy_died():
	points += 1
	$Ui.update_points(points)
	
	# Regenerar vida cada 100 puntos
	if points % 100 == 0:
		$Player.heal($Player.max_hp)

func _on_map_enemy_spawned(enemy):
	enemy.enemy_died.connect(_on_enemy_died)

func _on_map_boss_appeared(boss):
	boss_active = true
	boss.boss_died.connect(_on_boss_died)
	boss.health_changed.connect(_on_boss_health_changed)
	$Ui.show_boss_bar(boss.max_hp)

func _on_boss_died():
	points += 100
	$Ui.update_points(points)
	$Ui.hide_boss_bar()
	$Ui.show_victory()

func _on_boss_health_changed(current, max):
	$Ui.update_boss_health(current, max)
