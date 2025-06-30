extends Node
class_name Preloader
static var found_scenes: Array[String] = []
const SCENE_EXTENSIONS: PackedStringArray = [".tscn", ".scn"]
const regexPattern = "\\[(sub_resource|ext_resource) type=\"(ParticleProcessMaterial|ShaderMaterial|Material)\""

func read_file_as_string(file_path: String) -> String:
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	return content

static func scan_for_scenes(path: String):
	found_scenes.clear()
	_scan_directory_recursive(path)
		
func _ready():
	var regex = RegEx.new()
	var list = []
	$CanvasLayer/Preloader.visible = true
	regex.compile(regexPattern)
	scan_for_scenes("res://scenes/")
	for scene_path in found_scenes:
		var file_content = read_file_as_string(scene_path)
		var all_results = regex.search_all(file_content)
		if all_results.size() > 0:
			list.append(scene_path)
	for scenePath in list:
		var scene = remove_scripts_from_scene(scenePath)
		scene.global_position = Vector2(512,512)
		add_child(scene)
	await get_tree().create_timer(0.1).timeout
	queue_free()

static func remove_scripts_from_scene(scene_path: String) -> Node:
	var instanced_scene: Node = load(scene_path).instantiate()
	remove_script_recursive(instanced_scene)
	return instanced_scene

static func remove_script_recursive(node: Node):
	if node is Camera2D:
		node.enabled = false
	node.set_script(null)
	for child in node.get_children():
		remove_script_recursive(child)

static func remove_script_from_children(node : Node):
	for child in node.get_children():
		remove_script_recursive(child)

static func _scan_directory_recursive(current_path: String):
	if not current_path.ends_with("/"):
		current_path += "/"
	var dir_access: DirAccess = DirAccess.open(current_path)
	dir_access.list_dir_begin()
	var file_name = dir_access.get_next()
	while file_name != "":
		if dir_access.current_is_dir():
			if file_name != "." and file_name != "..":
				var sub_dir_path = current_path + file_name
				_scan_directory_recursive(sub_dir_path)
		else:
			if _is_scene_file(file_name):
				var scene_path = current_path + file_name
				found_scenes.append(scene_path)
		file_name = dir_access.get_next()
	dir_access.list_dir_end()

static func _is_scene_file(file_name: String) -> bool:
	for ext in SCENE_EXTENSIONS:
		if file_name.ends_with(ext):
			return true
	return false
