extends Node
@onready var control = $Control

@onready var projects_scan_dirs_list = %ProjectsScanDirectioriesItemList
@onready var del_scan_dir_button = %DelProjectScanDirButton
@onready var add_scan_dir_button = %AddProjectScanDirButton
@onready var scan_dir_file_dialog = $ScanDirFileDialog

func _ready():
	control.visibility_changed.connect(_update_directories)
	EventBus.projects_scan_dirs_updated.connect(_update_directories)
	del_scan_dir_button.pressed.connect(_on_del_scan_dir_pressed)
	add_scan_dir_button.pressed.connect(_on_add_scan_dir_pressed)
	scan_dir_file_dialog.dir_selected.connect(_on_scan_dir_dialog_dir_selected)

func _on_add_scan_dir_pressed():
	scan_dir_file_dialog.popup_centered()

func _on_scan_dir_dialog_dir_selected(dir: String):
	add_project_scan_dir(dir.replace("\\", "/")+"/")

func _on_del_scan_dir_pressed():
	if projects_scan_dirs_list.is_anything_selected():
		var selected = projects_scan_dirs_list.get_selected_items()[0]
		var dir_to_delete = projects_scan_dirs_list.get_item_text(selected)
		projects_scan_dirs_list.remove_item(selected)
		
		remove_project_scan_dir(dir_to_delete)

func _update_directories():
	projects_scan_dirs_list.clear()
	for scan_dir in SaveManager.get_key("settings", "projects_scan_dirs"):
		projects_scan_dirs_list.add_item(scan_dir)

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
