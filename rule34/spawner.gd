extends Node3D

@export var box_scene_red: PackedScene  # Assign "Box.tscn" in the Inspector
@export var spawn_interval: float = 2.0  # Time between spawns

var lane_positions = [Vector3(-10, 2, -2), Vector3(-10, 2, -7)]  # Adjusted Y position
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
	if not box_scene_red:
		push_error("Box scene not assigned!")
		return

	var box = box_scene_red.instantiate()
	var lane_index = randi() % lane_positions.size()  # Random lane
	var rotation_index = randi() % orientations.size()  # Random rotation

	box.transform.origin = lane_positions[lane_index]
	box.rotation_degrees.x = orientations[rotation_index]

	# Instead of adding to Spawner, add to Main scene
	var main_scene = get_tree().current_scene  # Get the root scene
	if main_scene:
		main_scene.add_child(box)  # Add the box to the Main scene
	else:
		push_error("Main scene not found!")
