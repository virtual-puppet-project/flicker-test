extends Spatial

onready var camera_mount: Spatial = $CameraMount
onready var camera: Camera = $CameraMount/Camera

onready var light: OmniLight = $OmniLight

onready var model: Spatial = $Alicia

#region Gui

onready var gui: Control = $Ui/PanelContainer

onready var light_toggle: CheckButton = $Ui/PanelContainer/ScrollContainer/VBoxContainer/LightToggle
onready var fov_le: LineEdit = $Ui/PanelContainer/ScrollContainer/VBoxContainer/FOV
onready var mouse_sensitivity_le: LineEdit = $Ui/PanelContainer/ScrollContainer/VBoxContainer/MouseSensitivity

onready var viewport_type: Label = $Ui/PanelContainer/ScrollContainer/VBoxContainer/ViewportType
onready var switch_viewport_type : Button = $Ui/PanelContainer/ScrollContainer/VBoxContainer/SwitchViewport

#endregion

var is_subviewport := false

var initial_model_transform := Transform.IDENTITY
var should_spin := false

var mouse_sensitivity: float = 0.001
var mouse_move_camera := false
# Uncapturing the mouse places it at the middle of the screen
var initial_mouse_position := Vector2.ZERO

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	OS.center_window()

func _ready() -> void:
	initial_model_transform = model.transform
	
	_on_light_toggled(true)
	light_toggle.set_pressed_no_signal(true)
	
	light_toggle.connect("toggled", self, "_on_light_toggled")
	
	fov_le.text = "%1.5f" % camera.fov
	fov_le.connect("text_changed", self, "_on_fov_changed")
	
	mouse_sensitivity_le.text = "%1.5f" % mouse_sensitivity
	mouse_sensitivity_le.connect("text_changed", self, "_on_sensitivity_changed")
	
	is_subviewport = get_tree().root.get_node_or_null("Subviewport") != null
	
	viewport_type.text = "Subviewport like in vpuppr" if is_subviewport else "Standard viewport"
	switch_viewport_type.connect("pressed", self, "_on_switch_viewport_type")

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.pressed:
			return
		
		match event.scancode:
			KEY_ESCAPE:
				gui.visible = not gui.visible
			KEY_SHIFT:
				should_spin = not should_spin
			KEY_SPACE:
				get_tree().reload_current_scene()
	elif event is InputEventMouseButton:
		if event.pressed:
			mouse_move_camera = true
			initial_mouse_position = get_viewport().get_mouse_position()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			mouse_move_camera = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.warp_mouse_position(initial_mouse_position)
	elif event is InputEventMouseMotion:
		if not mouse_move_camera:
			return
		
		camera_mount.rotate(Vector3.UP, -event.relative.x * mouse_sensitivity)
		camera.rotate(Vector3.RIGHT, -event.relative.y * mouse_sensitivity)

func _process(delta: float) -> void:
	var movement := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		movement += Vector3.FORWARD
	if Input.is_key_pressed(KEY_S):
		movement += Vector3.BACK
	if Input.is_key_pressed(KEY_A):
		movement += Vector3.LEFT
	if Input.is_key_pressed(KEY_D):
		movement += Vector3.RIGHT
	if Input.is_key_pressed(KEY_Q):
		movement += Vector3.DOWN
	if Input.is_key_pressed(KEY_E):
		movement += Vector3.UP
	camera_mount.translate(movement * delta)
	
	model.rotate_y(delta * float(should_spin))

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_light_toggled(state: bool) -> void:
	light.visible = state

func _on_fov_changed(text: String) -> void:
	if not text.is_valid_float():
		return
	
	var new_fov := text.to_float()
	if new_fov < 1.0 or new_fov > 179.0:
		return
	
	camera.fov = new_fov

func _on_sensitivity_changed(text: String) -> void:
	if not text.is_valid_float():
		return
	
	mouse_sensitivity = text.to_float()

func _on_switch_viewport_type() -> void:
	get_tree().change_scene("res://standard.tscn" if is_subviewport else "res://subviewport.tscn")

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
