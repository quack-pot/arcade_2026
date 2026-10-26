@tool
extends EditorScript

const SPACING := 4.0
const COLUMNS := 10

func _run() -> void:
	var root := EditorInterface.get_edited_scene_root()
	var selection := EditorInterface.get_selection().get_selected_nodes()

	if selection.is_empty():
		push_error("Please select a parent node in the Scene tab first.")
		return

	var parent: Node = selection[0]
	var index := 0

	for child in parent.get_children():
		child.scene_file_path = ""
		_set_owner_recursive(child, root)

		if child is Node3D:
			var x := (index % COLUMNS) * SPACING
			var z := floori(index / float(COLUMNS)) * SPACING
			child.position = Vector3(x, 0, z)
			index += 1

	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(parent, meshes)
	for mesh_instance in meshes:
		_add_collision(mesh_instance, root)

	print("Successfully arranged children of: ", parent.name)

func _set_owner_recursive(node: Node, root: Node) -> void:
	node.owner = root
	for c in node.get_children():
		_set_owner_recursive(c, root)

func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		_collect_meshes(c, out)

func _add_collision(mesh_instance: MeshInstance3D, root: Node) -> void:
	if mesh_instance.mesh == null:
		push_warning("%s has no mesh" % mesh_instance.name)
		return

	# Unwrap bodies created by earlier runs, so the mesh is the parent again.
	var wrapper := mesh_instance.get_parent() as StaticBody3D
	if wrapper != null:
		var grandparent := wrapper.get_parent()
		var combined := wrapper.transform * mesh_instance.transform
		mesh_instance.reparent(grandparent, false)
		mesh_instance.transform = combined
		mesh_instance.owner = root
		wrapper.free() # also frees its collision shapes

	# Skip meshes that already have a body underneath.
	for c in mesh_instance.get_children():
		if c is StaticBody3D:
			return

	mesh_instance.create_trimesh_collision()

	for c in mesh_instance.get_children():
		if c is StaticBody3D:
			_set_owner_recursive(c, root)
