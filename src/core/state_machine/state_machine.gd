class_name StateMachine extends Node

@export var state_label: Label
@export var initial_state: State

var current_state: State
var states: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitionned.connect(on_child_transition)
	
	if initial_state:
		initial_state.enter("")
		current_state = initial_state
	
	if state_label:
		state_label.text = initial_state.name


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func on_child_transition(state: State, new_state_name: String, data: Dictionary) -> void:
	if state != current_state:
		return
	
	var new_state := states.get(new_state_name.to_lower()) as State
	if !new_state:
		return
	
	if current_state:
		current_state.exit()
	
	new_state.enter(state.get_path(), data)
	current_state = new_state


	if state_label:
		state_label.text = new_state_name


func force_transition_to(state_name: String, data := {}) -> void:
	on_child_transition(current_state, state_name, data)
