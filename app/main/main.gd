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

@onready var settings_window = $SettingsWindow

func _ready():
	EventBus.projects_scan_dirs_updated.connect(on_scan_dirs_updated)
	update_projects()
	run_button.pressed.connect(_run_project)
	edit_button.pressed.connect(_edit_project)
	settings_button.pressed.connect(settings_window.popup_centered)
	exit_button.pressed.connect(get_tree().quit)
	
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

func _update_projects_tree():
	projects_tree.clear()
	projects_dirs_by_item.clear()
	var root_item: TreeItem = projects_tree.create_item()
	
	for scan_dir in SaveManager.get_key("settings", "projects_scan_dirs"):
		var dir_item: TreeItem = projects_tree.create_item(root_item)
		dir_item.set_text(0, scan_dir)
		dir_item.collapsed = true
		
		dir_item.set_icon(0, preload("res://assets/icons/folder.png"))
		
		for project in projects_dirs.filter(func(a: String): return a.begins_with(scan_dir)):
			var config: ConfigFile = ConfigFile.new()
			config.load(project + "/project.godot")
			if not config.has_section_key("application", "config/name"): continue
			var project_name = str(config.get_value("application", "config/name"))
			var project_item: TreeItem = projects_tree.create_item(dir_item)
			
			projects_dirs_by_item[project_item] = {
				"path": project,
			}
			
			projects_configs[project] = {
				"version": SaveManager.get_key("settings", "versions_for_configs")[config.get_value("", "config_version")],
			}
			
			project_item.set_text(0, project_name)
			project_item.set_tooltip_text(0, projects_configs[project]["version"].get_file())
			project_item.set_suffix(0, projects_configs[project]["version"].get_file())
			
			project_item.set_icon(0, preload("res://assets/icons/godot.png"))
			#project_item.set_text_alignment(0, HORIZONTAL_ALIGNMENT_CENTER)

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
