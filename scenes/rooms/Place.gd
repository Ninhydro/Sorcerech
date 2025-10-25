# AreaDetector.gd - Attach to World scene or individual Area2D nodes
extends Area2D

@export var area_name: String = ""

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body == Global.player:
		Global.set_current_area(area_name)
		print("Player entered: ", area_name)

func _on_body_exited(body: Node2D):
	if body == Global.player:
		print("Player exited: ", area_name)
