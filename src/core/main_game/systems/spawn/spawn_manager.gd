class_name SpawnManager extends Node

var _entity_root: Node2D = null

func spawn_enemy(enemy_scene: PackedScene, global_transform: Transform2D) -> Node2D:
	if _entity_root == null:
		return null
	
	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	if enemy == null:
		return null
	
	_entity_root.add_child(enemy)
	enemy.global_transform = global_transform
	
	return enemy


func spawn_collectable(collectable_scene: PackedScene, global_transform: Transform2D) -> Node2D:
	if _entity_root == null:
		return null
	
	var collectable: Node2D = collectable_scene.instantiate() as Node2D
	if collectable == null:
		return null
	
	_entity_root.add_child(collectable)
	collectable.global_transform = global_transform
	
	return collectable
