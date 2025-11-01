# res://scripts/globals/Global.gd
extends Node

# ... (other variables) ...

# If you need to store completed events by dialogue_id, declare it like this:
var sub_quest: Dictionary = {}

# Your existing Global.gd code with `current_scene_path` changes:
var gameStarted: bool
var autosave_timer: Timer = Timer.new()
var autosave_interval_seconds: float = 60.0

var is_dialog_open := false
var attacking := false

# ADD THIS LINE:
var is_cutscene_active := false # <--- NEW: Flag to indicate if a cutscene is active


var highlight_shader: Shader
var highlight_materials: Array = []  # Track all created highlight materials
var camouflage_shader: Shader
var circle_shader: Shader

func _ready():
	Dialogic.connect("dialog_started", Callable(self, "_on_dialog_started"))
	Dialogic.connect("dialog_ended", Callable(self, "_on_dialog_ended"))
	
	#add_child(autosave_timer)
	#autosave_timer.wait_time = autosave_interval_seconds
	#autosave_timer.timeout.connect(_on_autosave_timer_timeout)
	#autosave_timer.start()
	#print("Autosave timer started with interval: %s seconds" % autosave_interval_seconds)
	highlight_shader = load("res://shaders/highlight2.gdshader") #currently I think the highlight.gdshader is not used
	camouflage_shader = load("res://shaders/camouflage_alpha.gdshader")
	circle_shader = load("res://shaders/circle.gdshader")
	
	if highlight_shader:
		print("Global highlight shader loaded successfully")
	else:
		print("ERROR: Failed to load highlight shader")
		highlight_shader = _create_fallback_shader()


func create_highlight_material() -> ShaderMaterial:
	var material = ShaderMaterial.new()
	material.shader = highlight_shader
	highlight_materials.append(material)
	return material

func create_camouflage_material() -> ShaderMaterial:
	var material = ShaderMaterial.new()
	material.shader = camouflage_shader
	return material

func create_circle_material() -> ShaderMaterial:
	var material = ShaderMaterial.new()
	material.shader = circle_shader
	return material

func cleanup_all_materials():
	print("Global: Cleaning up all shader materials")
	for material in highlight_materials:
		if material and is_instance_valid(material):
			if material is ShaderMaterial:
					material = null  # let GC handle it
	highlight_materials.clear()

func _create_fallback_shader() -> Shader:
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	void fragment() {
		COLOR = texture(TEXTURE, UV);
	}
	"""
	return shader

func _exit_tree():
	cleanup_all_materials()

func cleanup_dialogic():
	if Engine.has_singleton("Dialogic"):
		var dlg = Dialogic
		dlg.end_all_dialogs()
		dlg.clear()
		
func _on_dialog_started():
	is_dialog_open = true

func _on_dialog_ended():
	is_dialog_open = false
	
var play_intro_cutscene := false
var playerBody: Player = null # This is the variable the ProfileScene is looking for
var selected_form_index: int

# --- MODIFIED: current_form property with setter and signal (Godot 4.x syntax) ---
# Use a private backing variable for the actual value.
var current_form: String = "Normal" # Initialize with default value for the backing variable

# Declare the signal
signal current_form_changed(new_form_id: String)

# Public setter function that emits the signal
func set_player_form(value: String):
	if current_form != value:
		current_form = value
		current_form_changed.emit(current_form)
		print("Global: Player form changed to: " + current_form)

# Public getter function
func get_player_form() -> String:
	return current_form
# --- END MODIFIED ---

var health = 100
var health_max = 100
var health_min = 0
var playerAlive :bool
var playerDamageZone: Area2D
var playerDamageAmount: int
var playerHitbox: Area2D
var telekinesis_mode := false
var teleporting := false
var dashing := false
var camouflage := false
var time_freeze := false

var near_save = false
var saving = false
var loading = false

var enemyADamageZone: Area2D
var enemyADamageAmount: int
var enemyAdealing: bool
var enemyAknockback := Vector2.ZERO

var kills: int = 0 # Initialize kills
var affinity: int = 0 # Initialize affinity
var player_status: String = "Neutral" # NEW: Player status

var active_quests := []
var completed_quests := []
var dialog_timeline := ""
var dialog_current_index := 0
var dialogic_variables: Dictionary = {}

var fullscreen_on = false
var vsync_on = false
var brightness: float = 1.0
var pixel_smoothing: bool = false
var fps_limit: int = 60
var master_vol = -10.0
var bgm_vol = -10.0
var sfx_vol = -10.0
var voice_vol = -10.0


# Add to graphics variables

var resolution_index: int = 2 # Default to 1280x720 (index 2)
var base_resolution = Vector2(320, 180)
var available_resolutions = [
	base_resolution * 2, # 0: 640x360
	base_resolution * 3, # 1: 960x540
	base_resolution * 4, # 2: 1280x720
	base_resolution * 6  # 3: 1920x1080
]


var current_scene_path: String = "" 

var current_loaded_player_data: Dictionary = {}
var current_game_state_data: Dictionary = {}

var cutscene_name: String = ""
var cutscene_playback_position: float = 0.0

signal brightness_changed(new_brightness_value)

var player_position_before_dialog: Vector2 = Vector2.ZERO # Use Vector2 for position
var scene_path_before_dialog: String = ""


var cutscene_finished1 = false

var ignore_player_input_after_unpause: bool = false
var unpause_cooldown_timer: float = 0.0
const UNPAUSE_COOLDOWN_DURATION: float = 0.5  # 100ms cooldown

var global_time_scale: float = 1.0
func slow_time():
	global_time_scale = 0.3  # 30% normal speed

func normal_time():
	global_time_scale = 1.0  # 100% normal speed
	

#Timeline
var timeline = 0 
#0 prologue cutscene, after done change to 1, 
#1 tutorial mode, to house (block until maya house)
#2 minigame mode, block until house and guide to minigame
#3 after minigame expand to town, starting chapter part 1 but stop until town, see dialog npc new aerendale
#4 expand to tromarvelia & exactlyion, start part 1, see dialog npc tromarvelia & exactlyion
#5 after unlock both form go to part 1 climax, change npc dialog about war
#6 start part 2, change npc dialog for part 2
#7 decision, check unlocked ultimate form, checkpoint go back from restart
#8 ending timeline route, look at route status decision, change npc dialog depends on route
#9 restart timeline if not true or pacifist
#10 Epilogue mode (after true end or pacifist end) final change on npc dialog


var magus_form = false
var cyber_form = false
var ult_magus_form = false
var ult_cyber_form = false
var route_status = "" # "", "Genocide", "Magus", "Cyber","True"(normal), "Pacifist"
#(Nataly always fight Maya)  on magus & cyber routes, with the optional nora & valentina fight
var alyra_dead = false 
#false means alyra alive so this is true normal route -> lux dead, zach king & different dialog overall
#true means alyra is dead so this contribute true pacifist route -> lux alive, varek king & different dialog overall
var gawr_dead = false
#false -> it will give extra scene on nora sealing gawr  
#		on cyber route gawr will help king fight us (can be varek/zach) (no dialog change)
# 		contribute pacifist end  
#true -> unable to go to pacifist end, no extra scene
var nora_dead = false
#false ->  if gawr_dead = false -> save nora on sealing gawr scene
#								on magus route help fight valentina, if valentina die then nora help with buff? 
#								on cyber fight nora
#								contribute pacifist end
#false ->  if gawr_dead = true -> gawr dead, but nora is still alive somewhere
#								on magus route fight valentina alone 
#								on cyber fight nora
#true ->  if gawr_dead = false -> cannot save nora on sealing gawr scene
#								on magus route fight valentina alone 
#								on cyber route no fight since nora is dead
var replica_fini_dead = false
#false -> it will give extra scene on saving valentina from fini attack 
#		on magus route fini will help sterling fight us  (no dialog change)
# 		contribute pacifist end  
#true -> unable to go to pacifist end, no extra scene
var valentina_dead = false
#false ->  if replica_fini_dead = false -> save valentina from fini
#								on cyber route help fight nora, if nora die then valentina help with buff? 
#								on magus fight valentina
#								contribute pacifist end
#false ->  if replica_fini_dead = true -> fini dead, but valentina is still alive somewhere
#								on cyber route fight nora alone 
#								on magus fight valentina
#true ->  if replica_fini_dead = false -> cannot save valentina from fini
#								on cyber route fight nora alone 
#								on magus route no fight since valentina is dead 
#
var teleport_first = 0.0
var first_tromarvelia = false
var first_exactlyion = false
var meet_nora_one = false
var meet_valentina_one = false

var exactlyion_two = false
var tromarvelia_two = false
var meet_replica = false
var meet_gawr = false
var after_battle_replica = false
var after_battle_gawr = false


#Some of this need to be persistent save for achievement
var ending_magus = false
var ending_cyber = false
var ending_genocide = false
var ending_true = false
var ending_pacifist = false
var game_cleared = false

# Player tracking
var player: Player = null
var current_area: String = ""

var killing = false

# Player registration function
func register_player(player_node: Player) -> void:
	player = player_node
	print("Global: Player registered")

# Area management functions
func set_current_area(area_name: String) -> void:
	if current_area != area_name:
		current_area = area_name
		print("Global: Current area changed to: ", area_name)

func get_current_area() -> String:
	return current_area

func get_player() -> Player:
	return player

func get_player_camera() -> Camera2D:
	if player and player.has_node("CameraPivot/Camera2D"):
		return player.get_node("CameraPivot/Camera2D")
	return null

func _init():
	# Set initial default values for settings here
	fullscreen_on = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	brightness = 1.0
	pixel_smoothing = false
	fps_limit = 60
	master_vol = 0.0
	bgm_vol = -10.0
	sfx_vol = -10.0
	voice_vol = -10.0
	
	# Initialize profile data defaults
	kills = 0
	affinity = 0
	player_status = "Neutral"
	current_form = "Normal" # Initialize the backing variable

func _process(delta):
	# Handle unpause cooldown timer
	if unpause_cooldown_timer > 0:
		unpause_cooldown_timer -= delta
		if unpause_cooldown_timer <= 0:
			ignore_player_input_after_unpause = false
			unpause_cooldown_timer = 0.0
			print("=== GLOBAL: Input ENABLED (cooldown finished) ===")
	
	if Input.is_action_just_pressed("debug"):
		killing = !killing
		print("killing ", killing)
	
	# Continuous debug print - remove this after debugging
	#print("Global input flag: ", ignore_player_input_after_unpause, " | Timer: ", unpause_cooldown_timer)
	
func start_unpause_cooldown():
	ignore_player_input_after_unpause = true
	unpause_cooldown_timer = UNPAUSE_COOLDOWN_DURATION
	print("Global: Unpause cooldown started for ", UNPAUSE_COOLDOWN_DURATION, " seconds")
	
func set_current_game_scene_path(path: String):
	current_scene_path = path
	print("Global: Current game scene path set to: " + current_scene_path)

func get_save_data() -> Dictionary:
	
	var data = {
		"gameStarted": gameStarted,
		"current_scene_path": current_scene_path,
		"play_intro_cutscene": play_intro_cutscene,
		"cutscene_finished1": cutscene_finished1,
		"is_cutscene_active": is_cutscene_active, # NEW: Save cutscene active state
		"cutscene_name": cutscene_name,
		"cutscene_playback_position": cutscene_playback_position,
		
		"fullscreen_on": fullscreen_on,
		"vsync_on": vsync_on,
		"brightness": brightness,
		"fps_limit": fps_limit,
		"master_vol": master_vol,
		"bgm_vol": bgm_vol,
		"sfx_vol": sfx_vol,
		"voice_vol": voice_vol,
		"resolution_index": resolution_index,

		"selected_form_index": selected_form_index,
		"current_form": get_player_form(), # Use the getter for saving
		"playerAlive": playerAlive,

		"kills": kills, # Save kills
		"affinity": affinity, # Save affinity
		"player_status": player_status, # NEW: Save player status
		
		"sub_quest": sub_quest,
		"active_quests": active_quests,
		"completed_quests": completed_quests, #sub & main quest
		"timeline": timeline,
		"magus_form":magus_form,
		"cyber_form":cyber_form,
		"ult_magus_form":ult_magus_form,
		"ult_cyber_form":ult_cyber_form,
		"route_status":route_status,
		"alyra_dead":alyra_dead,
		"gawr_dead":gawr_dead,
		"nora_dead":nora_dead,
		"replica_fini_dead":replica_fini_dead,
		"valentina_dead":valentina_dead,
		
		"first_tromarvelia":first_tromarvelia,
		"first_exactlyion":first_exactlyion,
		"meet_nora_one":meet_nora_one,
		"meet_valentina_one":meet_valentina_one,
		
		"exactlyion_two":exactlyion_two,
		"tromarvelia_two":tromarvelia_two,
		"meet_replica":meet_replica,
		"meet_gawr":meet_gawr,
		"after_battle_replica":after_battle_replica,
		"after_battle_gawr":after_battle_gawr,
		
		"ending_magus":ending_magus,
		"ending_cyber":ending_cyber,
		"ending_genocide":ending_genocide,
		"ending_true":ending_true,
		"ending_pacifist":ending_pacifist,
		"game_cleared":game_cleared

	
		
	}
	print("Global: Gathering full save data.")
	return data

		#timeline
		#magus_form
		#cyber_form
		#ult_magus_form
		#ult_cyber_form
		#route_status
		#alyra_dead
		#gawr_dead
		#nora_dead
		#replica_fini_dead
		#valentina_dead
		
func apply_load_data(data: Dictionary):
	current_scene_path = data.get("current_scene_path", "")
	gameStarted = data.get("gameStarted", false)
	play_intro_cutscene = data.get("play_intro_cutscene", false)
	cutscene_finished1 = data.get("cutscene_finished1", false)
	is_cutscene_active = data.get("is_cutscene_active", false)
	cutscene_name = data.get("cutscene_name", "")
	cutscene_playback_position = data.get("cutscene_playback_position", 0.0)
	
		
	fullscreen_on = data.get("fullscreen_on", false)
	vsync_on = data.get("vsync_on", false)
	brightness = data.get("brightness", 1.0)
	fps_limit = data.get("fps_limit", 60)
	master_vol = data.get("master_vol", -10.0)
	bgm_vol = data.get("bgm_vol", -10.0)
	sfx_vol = data.get("sfx_vol", -10.0)
	voice_vol = data.get("voice_vol", -10.0)
	resolution_index = data.get("resolution_index", 2) 

	
	selected_form_index = data.get("selected_form_index", 0)
	# This assignment will now correctly call the set_player_form setter, emitting the signal
	set_player_form(data.get("current_form", "Normal")) 
	playerAlive = data.get("playerAlive", true)

	
	sub_quest = data.get("sub_quest", {})
	active_quests = data.get("active_quests", [])
	completed_quests = data.get("completed_quests", [])
	
	kills = data.get("kills", 0) # Load kills
	affinity = data.get("affinity", 0) # Load affinity
	player_status = data.get("player_status", "Neutral") # NEW: Load player status
		
	timeline = data.get("timeline", 0)
	magus_form = data.get("magus_form", false)
	cyber_form = data.get("cyber_form", false)
	ult_magus_form = data.get("ult_magus_form", false)
	ult_cyber_form = data.get("ult_cyber_form", false)
	route_status = data.get("route_status", "")
	alyra_dead = data.get("alyra_dead", false)
	gawr_dead = data.get("gawr_dead", false)
	nora_dead = data.get("nora_dead", false)
	replica_fini_dead = data.get("replica_fini_dead", false)
	valentina_dead = data.get("valentina_dead", false)

	
	first_tromarvelia = data.get("first_tromarvelia", false)
	first_exactlyion = data.get("first_exactlyion", false)
	meet_nora_one = data.get("meet_nora_one", false)
	meet_valentina_one = data.get("meet_valentina_one", false)
	
	exactlyion_two = data.get("exactlyion_two", false)
	tromarvelia_two = data.get("tromarvelia_two", false)
	meet_replica = data.get("meet_replica", false)
	meet_gawr = data.get("meet_gawr", false)
	after_battle_replica = data.get("after_battle_replica", false)
	after_battle_gawr = data.get("after_battle_gawr", false)

	ending_magus = data.get("ending_magus", false)
	ending_cyber = data.get("ending_cyber", false)
	ending_genocide = data.get("ending_genocide", false)
	ending_true = data.get("ending_true", false)
	ending_pacifist = data.get("ending_pacifist", false)
	game_cleared = data.get("game_cleared", false)



	
	print("Global: All saved data applied successfully.")

func reset_to_defaults():
	print("Global: Resetting essential game state to defaults.")
	current_scene_path = ""
	current_loaded_player_data = {}
	current_game_state_data = {}
	gameStarted = false
	is_dialog_open = false
	attacking = false
	play_intro_cutscene = false
	selected_form_index = 0
	playerAlive = true
	telekinesis_mode = false
	teleporting = false
	dashing = false
	camouflage = false
	time_freeze = false
	fullscreen_on = false
	vsync_on = false
	brightness = 1.0
	fps_limit = 60
	master_vol = -10.0
	bgm_vol = -10.0
	sfx_vol = -10.0
	voice_vol = -10
	resolution_index = 2 # Reset to default index
	
	kills = 0 # Reset kills
	affinity = 0 # Reset affinity
	player_status = "Neutral" # NEW: Reset player status
	# Reset the form using the setter
	set_player_form("Normal") 
	
	timeline = 0
	magus_form = false
	cyber_form = false
	ult_magus_form = false
	ult_cyber_form = false
	route_status = ""
	alyra_dead = false
	gawr_dead = false
	nora_dead = false
	replica_fini_dead = false
	valentina_dead = false
	
	first_tromarvelia =  false
	first_exactlyion = false
	meet_nora_one = false
	meet_valentina_one = false

	exactlyion_two = false
	tromarvelia_two = false
	meet_replica = false
	meet_gawr = false
	after_battle_replica = false
	after_battle_gawr = false
	
	
	ending_magus = false
	ending_cyber = false
	ending_genocide = false
	ending_true = false
	ending_pacifist = false
	game_cleared = false

	sub_quest = {}
	active_quests = []
	completed_quests = []
	dialog_timeline = ""
	dialog_current_index = 0
	dialogic_variables = {}
	is_cutscene_active = false # NEW: Reset cutscene active state
	

	cutscene_name = ""
	cutscene_playback_position = 0.0
	cutscene_finished1 = false

	if autosave_timer.is_running():
		autosave_timer.stop()
	autosave_timer.start()


func apply_graphics_settings():
	var current_resolution = available_resolutions[resolution_index]
	
	# Fullscreen
	if fullscreen_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(current_resolution)

		
	# V-Sync
	DisplayServer.window_set_vsync_mode(vsync_on)

	# Brightness (Requires a CanvasModulate node in your main scene)
	brightness_changed.emit(brightness) # Emit the signal here

	# You would typically have a CanvasModulate node in your main scene (e.g., world.tscn)
	# and control its 'color' property.
	# Example in world.gd: $CanvasModulate.color = Color(brightness, brightness, brightness, 1.0)
	print("Global: Applied graphics settings: Fullscreen=" + str(fullscreen_on) + 
		  ", VSync=" + str(vsync_on) + ", Brightness (value stored)=" + str(brightness))
	
	# FPS Limit
	Engine.set_max_fps(fps_limit)
	print("Global: FPS Limit set to: " + str(fps_limit))


func apply_audio_settings():
	var master_bus_idx = AudioServer.get_bus_index("Master")
	var bgm_bus_idx = AudioServer.get_bus_index("BGM")
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	var voice_bus_idx = AudioServer.get_bus_index("Voice") # NEW: Voice bus index

	if master_bus_idx != -1:
		AudioServer.set_bus_volume_db(master_bus_idx, master_vol)
	if bgm_bus_idx != -1:
		AudioServer.set_bus_volume_db(bgm_bus_idx, bgm_vol)
	if sfx_bus_idx != -1:
		AudioServer.set_bus_volume_db(sfx_bus_idx, sfx_vol)
	if voice_bus_idx != -1: # NEW: Apply voice volume
		AudioServer.set_bus_volume_db(voice_bus_idx, voice_vol)
	
	print("Global: Applied audio settings: Master=" + str(master_vol) + 
		  ", BGM=" + str(bgm_vol) + ", SFX=" + str(sfx_vol) + 
		  ", Voice=" + str(voice_vol))


func _on_autosave_timer_timeout():
	print("Autosave timer triggered!")
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		if Global.current_scene_path.is_empty():
			printerr("Autosave: Global.current_scene_path is empty! Cannot autosave reliably.")
			return
		SaveLoadManager.save_game(player_node, "")
		print("Game autosaved by timer.")
	else:
		print("No player node found for timer-based autosave!")
		

func cleanup_all_shader_materials():
	"""Global cleanup called during exit"""
	print("Global: Cleaning up all shader materials")
	
	# Call emergency cleanup on player if it exists
	if playerBody and is_instance_valid(playerBody):
		if playerBody.has_method("emergency_cleanup_shaders"):
			playerBody.emergency_cleanup_shaders()
			
#func _notification(what):
#	if what == NOTIFICATION_SCENE_CHANGED:
#		cleanup_materials()

#func cleanup_materials():
	# Force garbage collection
#	RenderingServer.call_deferred("free_rids")
#	OS.delay_msec(100) # Small delay
	
