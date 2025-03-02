extends Node3D

@onready var udp := PacketPeerUDP.new()
@onready var port := 5005
@onready var node := $Node3D
@onready var nodeToFollow := str(8)
const mult := 5

func _ready() -> void:
	var err = udp.bind(port, "0.0.0.0")  # Listen on all network interfaces
	if err == OK:
		print("UDP Server listening on port " + str(port))
	else:
		print("Failed to bind UDP socket. Error: ", err)

func _process(_delta: float) -> void:
	while udp.get_available_packet_count() > 0:  # Check for new packets
		var packet = udp.get_packet()
		var data = packet.get_string_from_utf8()
		# Try parsing as JSON
		var parsed_data = JSON.parse_string(data)
		if parsed_data:
			print(parsed_data)
			node.position.x = parsed_data["hands"][0][nodeToFollow].x *mult
			node.position.y =  parsed_data["hands"][0][nodeToFollow].y*mult
			node.position.z =  parsed_data["hands"][0][nodeToFollow].z*mult
		else:
			print("Skill issue (Invalid JSON)")
