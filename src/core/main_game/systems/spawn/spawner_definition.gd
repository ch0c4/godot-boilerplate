class_name SpawnerDefinition extends Resource

enum RespawnMode {
	ONCE,
	ON_REENTER,
	ON_TIMER,
	ON_VISIBLE
}

enum SpawnPositionMode {
	ON_SHAPE,
	ON_TRANSFORM
}

enum SpawnBlockReason {
	NONE,
	ONE_TIME_SPAWN_USED,
	ACTIVE_INSTANCE,
	COOLDOWN,
	NOT_VISIBLE,
	NOT_REENTERED,
	TRIGGER_NOT_ACTIVE
}

enum SpawnEvent {
	CAMERA_ENTERED,
	CAMERA_EXITED,
	COOLDOWN_FINISHED,
	NODE_FREED,
	SPAWNED
}


@export var scene: PackedScene
@export var preview_texture: Texture2D

@export_category("Spawn Behavior")
@export var respawn_mode: RespawnMode
@export var spawn_position_mode := SpawnPositionMode.ON_TRANSFORM

@export_range(0.0, 60.0, 0.1) var cooldown_time := 0.0
@export_range(0.0, 60.0, 0.1) var randomize_cooldown_time := 0.0
