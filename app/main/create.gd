extends Node

@onready var project_name_line_edit = %ProjectNameLineEdit
@onready var project_dir_line_edit = %ProjectDirLineEdit
@onready var open_project_dir_button = %OpenProjectDirButton
@onready var open_template_button = %OpenTemplateButton
@onready var template_option_button = %TemplateOptionButton
@onready var create_project_folder_button = %CreateProjectFolderButton
@onready var godot_version_option_button = %GodotVersionOptionButton
@onready var rendering_method_option_button = %RenderingMethodOptionButton

@onready var create_cancel_button = %CreateCancelButton
@onready var create_ok_button = %CreateOkButton
@onready var project_dir_file_dialog = %ProjectDirFileDialog
@onready var template_dir_file_dialog = %TemplateDirFileDialog

var godot_version_dir_by_file = {
	
}

var templates_dir_by_item = {
	0: "res://addons/templates/godot/"
}

func _ready():
	EventBus.versions_for_configs_updated.connect(_update_versions)
	EventBus.versions_scan_dirs_updated.connect(_update_versions)
	_update_versions()
	
	create_cancel_button.pressed.connect(_on_cancel_create_pressed)
	create_ok_button.pressed.connect(_on_create_ok_pressed)
	project_dir_line_edit.text_submitted.connect(_on_project_dir_changed)
	open_project_dir_button.pressed.connect(project_dir_file_dialog.popup_centered)
	open_template_button.pressed.connect(template_dir_file_dialog.popup_centered)
	project_dir_file_dialog.dir_selected.connect(_on_project_dir_changed)
	create_project_folder_button.pressed.connect(_on_create_project_folder_pressed)
	godot_version_option_button.item_selected.connect(_on_godot_version_selected)
	template_dir_file_dialog.dir_selected.connect(_on_template_dialog_dir_selected)

func _update_versions():
	godot_version_option_button.clear()
	var versions_scan_dir = SaveManager.get_key("settings", "godot_versions_scan_dir")
	for version_file in Array(DirAccess.get_files_at(versions_scan_dir)).filter(func(a): return a.get_extension() == "exe"):
		godot_version_option_button.add_item(version_file)
		godot_version_dir_by_file[version_file] = versions_scan_dir+version_file

func _on_godot_version_selected(version):
	var version_path = get_godot_version()
	var vfc = SaveManager.get_key("settings", "versions_for_configs")
	var config_version_indx = vfc.values().find(version_path)
	if config_version_indx != -1:
		var config_version = vfc[vfc.keys()[config_version_indx]]
		rendering_method_option_button.clear()
		
		match config_version:
			4:
				rendering_method_option_button.add_item("OpenGl ES 3.0")
				rendering_method_option_button.add_item("OpenGl ES 2.0")
			5:
				rendering_method_option_button.add_item("Forward")
				rendering_method_option_button.add_item("Mobile")
				rendering_method_option_button.add_item("Compability")
				
		rendering_method_option_button.select(0)

func _on_create_project_folder_pressed():
	var target_dir = system_to_godot_dir(project_dir_line_edit.text)+project_name_line_edit.text
	if not DirAccess.dir_exists_absolute(target_dir):
		DirAccess.make_dir_absolute(target_dir)
		project_dir_line_edit.text = target_dir
		_on_project_dir_changed(project_dir_line_edit.text)

func _on_cancel_create_pressed():
	get_parent().hide()

func _on_create_ok_pressed():
	var data = get_project_data()
	create_project(data)
	get_tree().current_scene._edit_project(data.dir, data.version)
	get_parent().hide()

func _on_template_dialog_dir_selected(dir):
	var godot_dir = system_to_godot_dir(dir)
	template_option_button.add_item(godot_dir)
	templates_dir_by_item[template_option_button.item_count-1] = godot_dir
	template_option_button.select(template_option_button.item_count-1)

func _on_project_dir_changed(dir):
	project_dir_line_edit.text = system_to_godot_dir(dir)

func get_godot_version():
	return godot_version_dir_by_file[godot_version_option_button.get_item_text(godot_version_option_button.selected)]

func create_project(project_data):
	if not DirAccess.dir_exists_absolute(project_data.dir):
		DirAccess.make_dir_absolute(project_data.dir)
	
	var files = DirAccess.get_files_at(project_data.template)
	var dirs = DirAccess.get_directories_at(project_data.template)
	
	for dir in dirs:
		dirs.append_array(Array(DirAccess.get_directories_at(project_data.template+dir)).map(func(a):
			return dir+"/"+a))
		files.append_array(Array(DirAccess.get_files_at(project_data.template+dir)).map(func(a):
			return dir+"/"+a))
	for file in files:
		var new_file_dir = String(project_data.dir + file).get_base_dir()+"/"
		if not DirAccess.dir_exists_absolute(new_file_dir):
			DirAccess.make_dir_absolute(new_file_dir)
			print(new_file_dir)
		
		var new_file = FileAccess.open(project_data.dir+file, FileAccess.WRITE)
		if not new_file: continue
		
		var exist_file = FileAccess.open(project_data.template+file, FileAccess.READ)
		new_file.store_buffer(exist_file.get_buffer(exist_file.get_length()))
		new_file.close()
		exist_file.close()

	if FileAccess.file_exists(project_data.dir+"project.godot"):
		var project_godot = ConfigFile.new()
		project_godot.load(project_data.dir+"project.godot")
		project_godot.set_value("application", "config/name", project_data.name)
		#project_godot.set_value("rendering", "renderer/rendering_method", project_data.rendering_method)
		project_godot.save(project_data.dir+"project.godot")

func get_project_data():
	return {
		"name": project_name_line_edit.text,
		"dir": project_dir_line_edit.text,
		#"rendering_method": "forward",
		"version": get_godot_version(),
		"template": templates_dir_by_item[template_option_button.selected],
	}

func system_to_godot_dir(dir):
	return (dir.replace("\\", "/")+"/").replace("//", "/")
