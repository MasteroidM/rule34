extends Node3D

@export var box_scene_red: PackedScene  # Assign "Box_Red.tscn" in the Inspector
@export var box_scene_blue: PackedScene  # Assign "Box_Blue.tscn" in the Inspector
@export var spawn_interval: float = 2.0  # Time between spawns

var lane_positions = [Vector3(-10, 2, -3), Vector3(-10, 2, -6)]  # Adjusted Y position
var orientations = [0, 90, 180, 270]  # Four orientations

func _ready():
	var timer = $Timer  # Ensure Timer exists
	if not timer:
		push_error("Timer node not found! Please add a Timer as a child of Spawner.")
		return

	timer.wait_time = spawn_interval
	timer.timeout.connect(spawn_box)
	timer.start()

func spawn_box():
	if not box_scene_red or not box_scene_blue:
		push_error("Box scenes not assigned!")
		return

	# Randomly choose between red or blue box
	var chosen_scene = box_scene_red if randi() % 2 == 0 else box_scene_blue
	var box = chosen_scene.instantiate()

	var lane_index = randi() % lane_positions.size()  # Random lane
	var rotation_index = randi() % orientations.size()  # Random rotation

	box.transform.origin = lane_positions[lane_index]
	box.rotation_degrees.x = orientations[rotation_index]

	# Add the box to the Main scene
	var main_scene = get_tree().current_scene  
	if main_scene:
		main_scene.add_child(box)  
	else:
		push_error("Main scene not found!")
