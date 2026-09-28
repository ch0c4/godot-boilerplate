@tool
class_name PreviewSprite extends Sprite2D

const NULL_SPRITE = preload("uid://dagt4tpnjg47b")

var _previous_texture: Texture2D = null

@onready var preview_refresh_timer: Timer = $PreviewRefreshTimer


func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()
		return
	
	preview_refresh_timer.timeout.connect(_on_refresh_timeout)
	preview_refresh_timer.start(0.25)
	_on_refresh_timeout()


func _on_refresh_timeout() -> void:
	var spawner: Spawner = get_parent() as Spawner
	if spawner is not Spawner:
		return
	
	if spawner == null:
		return
	
	var definition := spawner.spawner_definition
	var new_texture = definition.preview_texture if (definition and definition.preview_texture) else NULL_SPRITE
	if new_texture == _previous_texture:
		return
	
	_previous_texture = new_texture
	texture = new_texture
