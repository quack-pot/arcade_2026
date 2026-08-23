@tool
extends EditorScript

@export var spacing: float = 4.0
@export var columns: int = 10

func _run():
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	
	if selection.is_empty():
		print("Error: Please select a parent node in the Scene tab first.")
		return
	
	var parent = selection[0]
	
	var index = 0
	
	for child in parent.get_children():
		if child is Node3D:
			var x = (index % columns) * spacing
			var z = (index / columns) * spacing
			child.position = Vector3(x, 0, z)
			index += 1
	
	print("Successfully arranged children of: ", parent.name)
