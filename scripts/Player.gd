extends KinematicBody

var speed = 500
var stick_amount = 10
var mouse_sensitivity = 0.1
var scroll_sensitivity = 0.1

var direction = Vector3()

func _input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		$Camera.rotation_degrees.x = clamp(
			$Camera.rotation_degrees.x - event.relative.y * mouse_sensitivity,
			-90, 90)

	direction = Vector3()
	direction.x = -Input.get_action_strength("move_left") + Input.get_action_strength("move_right")
	direction.y = -Input.get_action_strength("move_down") + Input.get_action_strength("move_up")
	direction.z = -Input.get_action_strength("move_forward") + Input.get_action_strength("move_backward")
	direction = direction.normalized().rotated(Vector3.UP, rotation.y)

	var accell = -Input.get_action_strength("scroll_down") + Input.get_action_strength("scroll_up") 
	speed = max(int(speed + speed * accell * scroll_sensitivity), 1)

func _physics_process(delta):
	move_and_slide(direction * speed * delta)
	$Label.text = "Speed: %d ly/s" % (speed * delta)

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
