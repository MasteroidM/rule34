extends Node3D

@export var speed: float = 3.0  # Movement speed
@export var direction: Vector3 = Vector3(1, 0, 0)  # Move forward (adjust if needed)

func _process(delta):
	# Move the box in the given direction
	transform.origin += direction * speed * delta

	# Optional: Remove the box if it moves too far (prevents infinite objects)
	if transform.origin.x > 10:  # Adjust based on your scene
		queue_free()


func _on_area_3d_area_entered(area: Area3D) -> void:
	print(area.name)
	if area.name == "blue_sabers":
		queue_free()
	pass # Replace with function body.
