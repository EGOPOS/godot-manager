extends Node

var projects_dirs_by_item: Dictionary = {}
var projects_configs: Dictionary = {}
var projects_dirs: Array[String] = []
@onready var projects_tree = %ProjectsTree
@onready var search_line_edit = %SearchLineEdit

@onready var edit_button = %EditButton
@onready var run_button = %RunButton
@onready var settings_button = %SettingsButton
@onready var exit_button = %ExitButton
@onready var create_button = %CreateButton
@onready var run_options_button = %RunOptionsButton

@onready var settings_window = $SettingsWindow
@onready var create_window = $CreateWindow
@onready var run_options_window = $RunOptionsWindow

func _ready():
	EventBus.projects_scan_dirs_updated.connect(on_scan_dirs_updated)
	EventBus.versions_for_configs_updated.connect(on_scan_dirs_updated)
	update_projects()
	run_button.pressed.connect(_run_project)
	edit_button.pressed.connect(_edit_project)
	projects_tree.item_activated.connect(_edit_project)
	settings_button.pressed.connect(settings_window.popup_centered)
	create_button.pressed.connect(create_window.popup_centered)
	run_options_button.pressed.connect(run_options_window.popup_centered)
	exit_button.pressed.connect(get_tree().quit)
	search_line_edit.text_changed.connect(func(text):
		if not text.is_empty():
			sort_projects_tree(sort_by_search.bind(text))
			#filter_projects_tree(filter_by_search.bind(text))
		else:
			_update_projects_tree(true)
	)
	
	var disable_items = func():
		run_button.disabled = true
		edit_button.disabled = true
	
	var enable_items = func():
		if projects_tree.get_selected().get_parent() != projects_tree.get_root():
			run_button.disabled = false
			edit_button.disabled = false
	
	projects_tree.item_selected.connect(enable_items)
	projects_tree.cell_selected.connect(disable_items)
	projects_tree.nothing_selected.connect(disable_items)
	disable_items.call()

func on_scan_dirs_updated():
	update_projects()

func update_projects():
	_update_projects_dirs()
	_update_projects_tree()

func _run_project(project: String = get_selected_project.call(), version = get_project_version(project)):
	open_godot(project, version, false)

func _edit_project(project: String = get_selected_project.call(), version = get_project_version(project)):
	open_godot(project, version, true)

func open_godot(project: String, version, edit = false):
	var output = []
	OS.execute(version, ["--path", project, "-e" if edit else ""], output)
	Debug.out = project
	Debug.out = output

var get_selected_project = func():
	return projects_dirs_by_item[projects_tree.get_selected()]["path"]

func get_project_version(project):
	return projects_configs[project]["version"]

func get_project_data(project):
	var config: ConfigFile = ConfigFile.new()
	config.load(project + "/project.godot")
	
	if not config.has_section_key("application", "config/name"): return null
	
	var project_name = str(config.get_value("application", "config/name"))
	var project_icon_path = project_res_path_to_system(project, config.get_value("application", "config/icon"))
	var project_icon: ImageTexture = ImageTexture.create_from_image(Image.new().load_from_file(project_icon_path))
	var config_veriosn = config.get_value("", "config_version")
	
	var data: Dictionary = {
		"name": project_name,
		"description": "",
		"icon": project_icon,
		"config_version": config_veriosn
	}
	return data

func _update_projects_tree(auto_collapse: bool = true):
	projects_tree.clear()
	projects_dirs_by_item.clear()
	var root_item: TreeItem = projects_tree.create_item()
	
	for scan_dir in SaveManager.get_key("settings", "projects_scan_dirs"):
		var dir_item: TreeItem = projects_tree.create_item(root_item)
		dir_item.set_text(0, scan_dir)
		dir_item.set_icon(0, preload("res://assets/icons/folder.png"))
		dir_item.collapsed = auto_collapse
		
		for project in projects_dirs.filter(func(a: String): return a.begins_with(scan_dir)):
			var project_data = get_project_data(project)
			if not project_data: continue
			
			var godot_version = SaveManager.get_key("settings", "versions_for_configs")[project_data.config_version]
			projects_configs[project] = {
				"version": godot_version,
			}
			
			var project_item: TreeItem = projects_tree.create_item(dir_item)
			projects_dirs_by_item[project_item] = {
				"path": project,
			}
			project_item.set_text(0, project_data.name)
			project_item.set_tooltip_text(0, godot_version.get_file())
			project_item.set_suffix(0, godot_version.get_file())
			project_item.set_icon(0, project_data.icon)
			#preload("res://assets/icons/godot.png")
			#project_item.set_text_alignment(0, HORIZONTAL_ALIGNMENT_CENTER)

func project_res_path_to_system(project, res_path):
	return str(res_path).replace("res:/", project)

func _update_projects_dirs():
	projects_dirs.clear()
	for scan_dir in SaveManager.get_key("settings", "projects_scan_dirs"):
		var unchecked_dirs = DirAccess.get_directories_at(scan_dir)
		
		for dir in unchecked_dirs:
			var current_dir = scan_dir + dir
			var dirs = DirAccess.get_directories_at(current_dir)
			var files = DirAccess.get_files_at(current_dir)
			
			if files.has("project.godot"):
				projects_dirs.append(current_dir)
				Debug.out = current_dir
			else:
				unchecked_dirs.append_array(Array(dirs).map(func(a): return dir + "/" + a))

func sort_projects_tree(sort_callable: Callable):
	projects_dirs.sort_custom(sort_callable)
	_update_projects_tree(false)

func sort_by_name(a: String, b: String):
	return a.to_int() > b.to_int()

func sort_by_search(a: String, b: String, request: String):
	#return a.similarity(request) > b.similarity(request)
	return a.countn(request) > b.countn(request)

func filter_by_search(a: String, request: String):
	return a.to_lower().contains(request.to_lower())
