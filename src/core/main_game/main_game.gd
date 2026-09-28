class_name MainGame extends Node

const LEVEL_UID: String = ""
const PLAYER_SCENE_UID: String = ""

var player: Node2D = null
var _current_level: BaseLevel = null

@onready var level_root: Node2D = %LevelRoot
@onready var entity_root: Node2D = %EntityRoot
@onready var effect_root: Node2D = %EffectRoot

@onready var hud_root: Control = %HudRoot
@onready var pause_root: Control = %PauseRoot
@onready var transition_root: Control = %TransitionRoot



func _enter_tree() -> void:
	Global.main_game = self


func _exit_tree() -> void:
	Global.main_game = null


func _ready() -> void:
	_init_systems()
	_init_player()
	
	load_level(LEVEL_UID)



func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event.is_action_pressed(&"debug_quit"):
		quit_game()


func quit_game() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


func load_level(level_scene: String) -> void:
	_perform_level_load.call_deferred(level_scene)


func _perform_level_load(level_scene_uid: String) -> void:
	if is_instance_valid(_current_level):
		_current_level.queue_free()
		_current_level = null
		await get_tree().process_frame


	var new_level_packed: PackedScene = (
			ResourceLoader.load(level_scene_uid, "PackedScene") as PackedScene
	)

	if new_level_packed == null:
		push_error("Could not load level as a packed scene: " + level_scene_uid)
		return

	var new_level: Node = new_level_packed.instantiate()

	if not new_level:
		push_error("Could not instantiate new level " + level_scene_uid)
		return

	if new_level is not BaseLevel:
		new_level.free()
		push_error("Loaded level is not of type BaseLevel " + level_scene_uid)
		return

	_current_level = new_level

	level_root.add_child(_current_level)

	_place_player_at_level_spawn()
	_setup_level_camera()


func _init_player() -> void:
	var player_scene: PackedScene = ResourceLoader.load(PLAYER_SCENE_UID) as PackedScene
	if player_scene == null:
		push_error("Could not load player scene: " + PLAYER_SCENE_UID)
		return

	var player_instance: Node = player_scene.instantiate()
	if not player_instance:
		push_error("Could not instantiate player scene " + PLAYER_SCENE_UID)
		return

	#if player_instance is not Player:
	#	player_instance.free()
	#	push_error("Loaded player scene is not of type Player " + PLAYER_SCENE_UID)
	#	return

	#player = player_instance as Player

	entity_root.add_child(player)


func _place_player_at_level_spawn() -> void:
	if player == null:
		push_error("Cannot place player in level because it is null")
		return
	if _current_level == null:
		push_error("Cannot place player into level because level is null")
		return

	player.global_position = _current_level.get_default_player_spawn()


func _setup_level_camera() -> void:
	pass


func _init_systems() -> void:
	pass
