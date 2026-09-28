class_name CollectableSpawner extends Spawner

@export var collision_shape: CollisionShape2D

@export_category("Spawner Override Options")
@export var override_collectable_default := false
@export var override_respawn_mode := SpawnerDefinition.RespawnMode.ON_REENTER
@export var override_spawn_position_mode := SpawnerDefinition.SpawnPositionMode.ON_TRANSFORM

@export_range(0.0, 60.0, 0.1) var override_cooldown_time := 0.0
@export_range(0.0, 60.0, 0.1) var override_randomize_cooldown_time := 0.0

var _collectable_scene: PackedScene = null

var _spawn_manager: SpawnManager

var _respawn_mode := SpawnerDefinition.RespawnMode.ON_REENTER
var _spawn_position_mode := SpawnerDefinition.SpawnPositionMode.ON_TRANSFORM
var _default_cooldown_time := 0.0
var _randomize_cooldown_time := 0.0

var _instance_currently_active := false
var _spawner_is_visible := false
var _must_exit_before_respawn := false
var _on_cooldown := false

var _has_spawned_once := false

var _spawn_check_queue := false

@onready var respawn_timer: Timer = $RespawnTimer
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	_spawn_manager = Global.main_game.spawn_manager
	assert(_spawn_manager != null, "SpawnerDefinition was not available in Spawner Ready")
	
	if spawner_definition == null:
		push_error("Spawner has no definition registered: ", name)
		return
	
	_collectable_scene = spawner_definition.scene
	if _collectable_scene == null:
		push_error("Spawner collectable has no scene assigned: ", name)
		return
	
	_apply_collectable_spawn_definition(spawner_definition)
	
	visible_notifier.screen_entered.connect(_on_camera_entered)
	visible_notifier.screen_exited.connect(_on_camera_exited)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)


func _apply_collectable_spawn_definition(definition: SpawnerDefinition) -> void:
	if override_collectable_default:
		_respawn_mode = override_respawn_mode
		_spawn_position_mode = override_spawn_position_mode
		_default_cooldown_time = override_cooldown_time
		_randomize_cooldown_time = override_randomize_cooldown_time
		return
	
	_respawn_mode = definition.respawn_mode
	_spawn_position_mode = definition.spawn_position_mode
	_default_cooldown_time = definition.cooldown_time
	_randomize_cooldown_time = definition.randomize_cooldown_time


func _request_spawn_check() -> void:
	if _spawn_check_queue:
		return
	_spawn_check_queue = true
	
	_run_deferred_spawn_check.call_deferred()


func _run_deferred_spawn_check() -> void:
	if not _spawn_check_queue:
		push_warning("_run_deferred_spawn_check() called directly when no spawn check has queued")
		return
	
	_spawn_check_queue = false
	_try_spawn()


func _try_spawn() -> void:
	if not _can_spawn():
		return
	
	var spawn_success := _spawn_collectable()
	if not spawn_success:
		return
	
	_instance_currently_active = true
	_has_spawned_once = true
	
	_handle_spawn_event(SpawnerDefinition.SpawnEvent.SPAWNED)


func _spawn_collectable() -> bool:
	var spawn_position := global_transform
	if _spawn_position_mode == SpawnerDefinition.SpawnPositionMode.ON_SHAPE:
		if not collision_shape or not collision_shape.shape:
			return false
		
		var shape: RectangleShape2D = collision_shape.shape
		var half_size := shape.size * 0.5
		var local_position := Vector2(
			randf_range(-half_size.x, half_size.x),
			randf_range(-half_size.y, half_size.y)
		)
		
		spawn_position = Transform2D(0.0, collision_shape.global_transform * local_position)
	
	var collectable_instance: Node2D = _spawn_manager.spawn_collectable(_collectable_scene, spawn_position)
	if collectable_instance == null:
		push_error("Spawner unable to spawn collectable instance: ", name)
		return false
	
	collectable_instance.collectable_queued_free.connect(_on_collectable_left_scene)
	return true


func _can_spawn() -> bool:
	var block_reason := _determine_spawn_block_reason()
	if block_reason != SpawnerDefinition.SpawnBlockReason.NONE:
		return false
	
	return true


func _determine_spawn_block_reason() -> SpawnerDefinition.SpawnBlockReason:
	var reason: SpawnerDefinition.SpawnBlockReason
	
	reason = _check_one_time_only()
	if reason != SpawnerDefinition.SpawnBlockReason.NONE:
		return reason
	
	reason = _check_for_active_instance()
	if reason != SpawnerDefinition.SpawnBlockReason.NONE:
		return reason
	
	reason = _check_for_cooldown_complete()
	if reason != SpawnerDefinition.SpawnBlockReason.NONE:
		return reason
	
	reason = _check_for_spawner_visible()
	if reason != SpawnerDefinition.SpawnBlockReason.NONE:
		return reason
	
	reason = _check_for_spawn_reentered()
	if reason != SpawnerDefinition.SpawnBlockReason.NONE:
		return reason
	
	return SpawnerDefinition.SpawnBlockReason.NONE


func _check_one_time_only() -> SpawnerDefinition.SpawnBlockReason:
	if _uses_spawn_once() and _has_spawned_once:
		return SpawnerDefinition.SpawnBlockReason.ONE_TIME_SPAWN_USED
	
	return SpawnerDefinition.SpawnBlockReason.NONE


func _check_for_active_instance() -> SpawnerDefinition.SpawnBlockReason:
	return SpawnerDefinition.SpawnBlockReason.ACTIVE_INSTANCE if _instance_currently_active else SpawnerDefinition.SpawnBlockReason.NONE


func _check_for_cooldown_complete() -> SpawnerDefinition.SpawnBlockReason:
	return SpawnerDefinition.SpawnBlockReason.COOLDOWN if _on_cooldown else SpawnerDefinition.SpawnBlockReason.NONE


func _check_for_spawner_visible() -> SpawnerDefinition.SpawnBlockReason:
	return SpawnerDefinition.SpawnBlockReason.NOT_VISIBLE if not _spawner_is_visible else SpawnerDefinition.SpawnBlockReason.NONE 


func _check_for_spawn_reentered() -> SpawnerDefinition.SpawnBlockReason:
	if not _uses_reentry():
		return SpawnerDefinition.SpawnBlockReason.NONE
	
	if _must_exit_before_respawn:
		return SpawnerDefinition.SpawnBlockReason.NOT_REENTERED
	
	return SpawnerDefinition.SpawnBlockReason.NONE


func _uses_spawn_once() -> bool:
	return _respawn_mode == SpawnerDefinition.RespawnMode.ONCE


func _uses_reentry() -> bool:
	return _respawn_mode == SpawnerDefinition.RespawnMode.ON_REENTER


func _uses_cooldown_time() -> bool:
	return _respawn_mode == SpawnerDefinition.RespawnMode.ON_TIMER


func _uses_on_visible() -> bool:
	return _respawn_mode == SpawnerDefinition.RespawnMode.ON_VISIBLE


func _handle_spawn_event(event: SpawnerDefinition.SpawnEvent) -> void:
	match event:
		SpawnerDefinition.SpawnEvent.CAMERA_ENTERED:
			if _uses_reentry() and _instance_currently_active:
				_must_exit_before_respawn = true
			
			_request_spawn_check()
		
		SpawnerDefinition.SpawnEvent.CAMERA_EXITED:
			if _uses_reentry():
				_must_exit_before_respawn = false
		
		SpawnerDefinition.SpawnEvent.COOLDOWN_FINISHED:
			_request_spawn_check()
		
		SpawnerDefinition.SpawnEvent.NODE_FREED:
			if _uses_cooldown_time():
				_on_cooldown = true
				var total_respawn_time := _default_cooldown_time + randf_range(0.0, _randomize_cooldown_time)
				respawn_timer.start(total_respawn_time)
			else:
				_request_spawn_check()
		
		SpawnerDefinition.SpawnEvent.SPAWNED:
			if _uses_reentry():
				_must_exit_before_respawn = true


func _on_camera_entered() -> void:
	_spawner_is_visible = true
	_handle_spawn_event(SpawnerDefinition.SpawnEvent.CAMERA_ENTERED)


func _on_camera_exited() -> void:
	_spawner_is_visible = false
	_handle_spawn_event(SpawnerDefinition.SpawnEvent.CAMERA_EXITED)


func _on_respawn_timer_timeout() -> void:
	_on_cooldown = false
	_handle_spawn_event(SpawnerDefinition.SpawnEvent.COOLDOWN_FINISHED)


func _on_collectable_left_scene() -> void:
	_instance_currently_active = false
	_handle_spawn_event(SpawnerDefinition.SpawnEvent.NODE_FREED)


func is_enemy() -> bool:
	return false
