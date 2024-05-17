extends Window

func _ready():
	close_requested.connect(on_close_request)

func on_close_request():
	hide()
