extends MarginContainer

@onready var horse_scene = preload("res://horse.tscn")
@onready var horses = $ColorRect/CenterContainer/PanelContainer/Horses
@onready var horse_panel = $"ColorRect/CenterContainer/PanelContainer/Horses/Horse Spots"
@onready var days_elapsed = $ColorRect/CenterContainer/PanelContainer/Horses/DaysElapsed
@onready var pages_text = $ColorRect/CenterContainer/PanelContainer/Horses/Pages

@export var timestep = 48

var fpath = "res://first-names.json"
var horse_list = []
var active_page = 1
var names = []
var cities = []

var prev_tick = Time.get_ticks_msec()
var days = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var json_as_dict = JSON.parse_string(FileAccess.get_file_as_string(fpath))
	var name  = "not-found"
	if json_as_dict:
		names = json_as_dict["names"]
	
	var countries_cities = JSON.parse_string(FileAccess.get_file_as_string("res://countries+cities.json"))
	
	for country_city in countries_cities:
		cities.append_array(country_city["cities"])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var current_tick = Time.get_ticks_msec()
	
	if current_tick - prev_tick > 1000:
		days += timestep / 24
		for page in horse_list:
			for horse in page:
				var progress = horse.get_node("Panel/ProgressBar")
				horse.days += timestep / 24
				progress.value = round((5 * 24 * horse.days) / horse.distance * 100)
				
				
				if progress.value >= 100:
					if len(cities) != 0 and horse.city2 != null:
						var city2 = cities[randi() % cities.size()]
						
						while city2 == horse.city2:
							city2 = cities[randi() % cities.size()]
						var orig_dest: Label = horse.get_node("Panel/Origin-destination")
						var dist_label: Label = horse.get_node("Panel/distance")
						orig_dest.text = "%s-%s" % [horse.city2["name"], city2["name"]]
						var city1_lat = float(horse.city2["latitude"]) 
						var city1_lon = float(horse.city2["longitude"]) 
						var city2_lat = float(city2["latitude"])
						var city2_lon = float(city2["longitude"])
						
						horse.distance = round(haversine_distance(city1_lat, city1_lon, city2_lat, city2_lon))
						dist_label.text = str(round(haversine_distance(city1_lat, city1_lon, city2_lat, city2_lon))) + " km"
						horse.days = 0
						
						horse.city1 = horse.city2
						horse.city2 = city2
	
						
				
		days_elapsed.text = "Days: %s" % str(days)
		
		prev_tick = current_tick


func _on_button_pressed() -> void:
	var name = "IDK"
	var city1 = "IDK"
	var city2 = "IDK"
	
	if len(names) != 0:
		name = names[randi() % names.size()]
	
	if len(cities) != 0:
		city1 = cities[randi() % cities.size()]
		city2 = cities[randi() % cities.size()]
		
		while city2 == city1:
			city2 = cities[randi() % cities.size()]
		

	
	var horse = horse_scene.instantiate()
	horse.city1 = city1
	horse.city2 = city2
	var horse_status: Label = horse.get_node("Panel/Horse Name")
	var orig_dest: Label = horse.get_node("Panel/Origin-destination")
	var dist_label: Label = horse.get_node("Panel/distance")
	horse_status.text = name
	orig_dest.text = "%s-%s" % [city1["name"], city2["name"]]
	var city1_lat = float(city1["latitude"]) 
	var city1_lon = float(city1["longitude"]) 
	var city2_lat = float(city2["latitude"])
	var city2_lon = float(city2["longitude"])
	
	horse.distance = round(haversine_distance(city1_lat, city1_lon, city2_lat, city2_lon))
	dist_label.text = str(round(haversine_distance(city1_lat, city1_lon, city2_lat, city2_lon))) + " km"

	
	if len(horse_list) == 0:
		horse_list.append([horse])
	else:
		var found = false
		for page in horse_list.size():
			if len(horse_list[page]) < 4:
				horse_list[page].append(horse)
				found = true
		if not found:
			horse_list.append([horse])
	pages_text.text = "%s/%s" % [active_page, len(horse_list)]
	
	reload_horses()


func reload_horses() -> void:
	var horse_panel_children = horse_panel.get_children()
	for spot in horse_panel_children.size():
		for child in horse_panel_children[spot].get_children():
			horse_panel_children[spot].remove_child(child)
		if spot <= len(horse_list[active_page - 1]) - 1:
			horse_panel_children[spot].add_child(horse_list[active_page - 1][spot])
	

const EARTH_RADIUS_KM = 6371.0

func haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var lat1_rad = deg_to_rad(lat1)
	var lon1_rad = deg_to_rad(lon1)
	var lat2_rad = deg_to_rad(lat2)
	var lon2_rad = deg_to_rad(lon2)
	
	var dlat = lat2_rad - lat1_rad
	var dlon = lon2_rad - lon1_rad
	
	var a = sin(dlat / 2) * sin(dlat / 2) + cos(lat1_rad) * cos(lat2_rad) * sin(dlon / 2) * sin(dlon / 2)
	var c = 2 * atan2(sqrt(a), sqrt(1 - a))
	return EARTH_RADIUS_KM * c


func _on_prev_button_pressed() -> void:
	if active_page != 1 and len(horse_list) != 0:
		active_page -= 1
		pages_text.text = "%s/%s" % [active_page, len(horse_list)]
		reload_horses()


func _on_next_button_pressed() -> void:
	if (active_page + 1) <= len(horse_list) and len(horse_list) != 0:
		active_page += 1
		pages_text.text = "%s/%s" % [active_page, len(horse_list)]
		reload_horses()
