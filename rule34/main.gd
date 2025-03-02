extends Node3D 

@onready var udp := PacketPeerUDP.new()
@onready var port := 5005
@onready var nodeRight := $red_saber  # Renamed for clarity
@onready var nodeLeft := $blue_saber  # New node for left hand
@onready var nodeToFollow := str(8)  
@onready var i_vec_right := Vector3(9, 3.25, -5)
@onready var i_vec_left := Vector3(9, 3.25, -5)  # Separate initial vector for left
@onready var f_vec_right := Vector3.ZERO
@onready var f_vec_left := Vector3.ZERO
const mult := 300

func _ready() -> void:
	var err = udp.bind(port, "0.0.0.0")  
	if err == OK:
		print("UDP Server listening on port " + str(port))
	else:
		print("Failed to bind UDP socket. Error: ", err)

func _process(_delta: float) -> void:
	while udp.get_available_packet_count() > 0:  
		var packet = udp.get_packet()
		var data = packet.get_string_from_utf8()
		
		var parsed_data = JSON.parse_string(data)
		if parsed_data and "hands" in parsed_data:
			for hand in parsed_data["hands"]:  # Iterate through hands
				if hand.has(nodeToFollow):
					var is_left = hand.get("isleft", false)  # Get handedness
					var target_node =  nodeRight if is_left else nodeLeft   # Select node
					var i_vec = i_vec_left if is_left else i_vec_right  # Select initial vector
					var f_vec = f_vec_left if is_left else f_vec_right  # Select final vector

					f_vec.x = -hand[nodeToFollow].z * mult
					f_vec.y = hand[nodeToFollow].x * mult
					f_vec.z = -hand[nodeToFollow].y * mult
					
					# Compute target rotation
					var target_rotation = rotate_vector_to_target(i_vec, f_vec)

					# Ignore small movements (hand shakes)
					if i_vec.distance_to(f_vec) > 0.01:
						# Use SLERP to gradually rotate, increase 0.7 for even faster response
						target_node.global_transform.basis = target_node.global_transform.basis.slerp(target_rotation, 0.7)

						# Add extra manual rotation boost
						target_node.global_transform.basis = target_node.global_transform.basis.rotated(Vector3.UP, deg_to_rad(15))  

					# Update vectors to prevent snapping
					if is_left:
						i_vec_left = f_vec
						f_vec_left = f_vec
					else:
						i_vec_right = f_vec
						f_vec_right = f_vec

# Rotate vector to align with target vector
func rotate_vector_to_target(v_initial: Vector3, v_final: Vector3) -> Basis:
	var v_i = v_initial.normalized()
	var v_f = v_final.normalized()

	var axis = v_i.cross(v_f)
	if axis.length() < 0.0001:
		if v_i.dot(v_f) < 0:
			axis = Vector3(1, 0, 0) if abs(v_i.x) < 0.99 else Vector3(0, 1, 0)  
		else:
			return Basis()  

	var angle = acos(v_i.dot(v_f)) * 3.0  # Boost rotation intensity

	var quat = Quaternion(axis.normalized(), angle)
	return Basis(quat)
