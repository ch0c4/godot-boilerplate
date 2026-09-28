class_name Hitbox extends Area2D

signal hit_hurtbox(hurtbox: Hurtbox)

@export var damage: = 1

var knockback: = Vector2.ZERO

func _ready() -> void:
	area_entered.connect(_on_hurtbox_entered)


func _on_hurtbox_entered(hurtbox: Hurtbox) -> void:
	assert(hurtbox is Hurtbox, "Your hitbox is colliding with an area that isn't an hurtbox!")
	
	if hurtbox.is_invincible: 
		return
	
	hit_hurtbox.emit(hurtbox)
	hurtbox.hurt.emit(self)
