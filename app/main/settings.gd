extends Node
@onready var control = $Control

@onready var projects_scan_dirs_list = %ProjectsScanDirectioriesItemList
@onready var project_del_scan_dir_button = %DelProjectScanDirButton
@onready var project_add_scan_dir_button = %AddProjectScanDirButton
@onready var project_scan_dir_file_dialog = $ScanDirFileDialog

@onready var versions_tree: Tree = %VersionsItemTree
@onready var open_versions_dir_button = %OpenVersionsDirButton
@onready var gd_4_default_version_option_button = $Control/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer3/GD4DefaultVersionOptionButton
@onready var gd_3_default_version_option_button = %GD3DefaultVersionOptionButton
@onready var godot_version_file_dialog = $GodotVersionFileDialog

func _ready():
	control.visibility_changed.connect(_update)
	control.visibility_changed.connect(_update)
	EventBus.projects_scan_dirs_updated.connect(_update)
	EventBus.versions_scan_dirs_updated.connect(_update)
	EventBus.versions_for_configs_updated.connect(_update)
	
	project_del_scan_dir_button.pressed.connect(_on_project_del_scan_dir_pressed)
	project_add_scan_dir_button.pressed.connect(_on_add_scan_dir_pressed)
	project_scan_dir_file_dialog.dir_selected.connect(_on_project_scan_dir_dialog_dir_selected)
	gd_4_default_version_option_button.item_selected.connect(_on_version_selected.bind(5))
	gd_3_default_version_option_button.item_selected.connect(_on_version_selected.bind(4))
	open_versions_dir_button.pressed.connect(_on_versions_dir_open_pressed)
	godot_version_file_dialog.dir_selected.connect(_on_godot_version_dialog_dir_selected)

func _on_godot_version_dialog_dir_selected(dir: String):
	SaveManager.set_key("settings", "godot_versions_scan_dir", system_to_godot_dir(dir))
	EventBus.versions_scan_dirs_updated.emit()

func _on_versions_dir_open_pressed():
	godot_version_file_dialog.popup_centered()

func _on_version_selected(item, config):
	var version_file = gd_4_default_version_option_button.get_item_text(item)
	set_version_for_config(config, SaveManager.get_key("settings", "godot_versions_scan_dir")+version_file)

func _on_add_scan_dir_pressed():
	project_scan_dir_file_dialog.popup_centered()

func _on_project_scan_dir_dialog_dir_selected(dir: String):
	add_project_scan_dir(system_to_godot_dir(dir))

func _on_project_del_scan_dir_pressed():
	if projects_scan_dirs_list.is_anything_selected():
		var selected = projects_scan_dirs_list.get_selected_items()[0]
		var dir_to_delete = projects_scan_dirs_list.get_item_text(selected)
		projects_scan_dirs_list.remove_item(selected)
		
		remove_project_scan_dir(dir_to_delete)

func _update():
	_update_versions_dirs()
	_update_directories()

func _update_directories():
	projects_scan_dirs_list.clear()
	
	for scan_dir in SaveManager.get_key("settings", "projects_scan_dirs"):
		projects_scan_dirs_list.add_item(scan_dir)

func _update_versions_dirs():
	versions_tree.clear()
	gd_4_default_version_option_button.clear()
	gd_3_default_version_option_button.clear()
	var versions_scan_dir = SaveManager.get_key("settings", "godot_versions_scan_dir")
	var versions_root = versions_tree.create_item()
	versions_root.set_text(0, versions_scan_dir)
	
	var vfc = SaveManager.get_key("settings", "versions_for_configs")
	for file in DirAccess.get_files_at(versions_scan_dir):
		if not file.get_extension() == "exe": continue
		var item = versions_tree.create_item(versions_root)
		item.set_text(0, file.get_file())
		
		gd_4_default_version_option_button.add_item(file.get_file())
		gd_3_default_version_option_button.add_item(file.get_file())
		if vfc[4] == versions_scan_dir+file:
			gd_3_default_version_option_button.selected = gd_3_default_version_option_button.item_count-1
		elif vfc[5] == versions_scan_dir+file:
			gd_4_default_version_option_button.selected = gd_4_default_version_option_button.item_count-1

func set_version_for_config(config: int, version: String):
	var vfc = SaveManager.get_key("settings", "versions_for_configs")
	vfc[config] = version
	SaveManager.set_key("settings", "versions_for_configs", vfc)
	EventBus.versions_for_configs_updated.emit()
	Debug.out = ["config", config, "now is", version]

#TODO сократить как нибудь
func add_project_scan_dir(dir):
	var scan_dirs = SaveManager.get_key("settings", "projects_scan_dirs")
	scan_dirs.append(dir)
	
	SaveManager.set_key("settigns", "projects_scan_dirs", scan_dirs)
	EventBus.projects_scan_dirs_updated.emit()

func remove_project_scan_dir(dir):
	var scan_dirs = SaveManager.get_key("settings", "projects_scan_dirs")
	scan_dirs.erase(dir)
	
	SaveManager.set_key("settigns", "projects_scan_dirs", scan_dirs)
	EventBus.projects_scan_dirs_updated.emit()

func system_to_godot_dir(dir):
	return dir.replace("\\", "/")+"/"
