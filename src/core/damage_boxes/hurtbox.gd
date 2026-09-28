class_name Hurtbox extends Area2D

@warning_ignore("unused_signal")
signal hurt(hitbox: Hitbox)

var is_invincible: = false :
	set = _set_is_invincible


func _set_is_invincible(value) -> void:
	is_invincible = value
	set_deferred("monitoring", not is_invincible)
