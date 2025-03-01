extends Node3D

@onready var udp := PacketPeerUDP.new()
@onready var port := 5005

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
			print("Parsed JSON:", parsed_data)
		else:
			print("Skill issue (Invalid JSON)")
