macroScript BFF_Exporter category:"Bobo_s Tools" tooltip:"Exporter to scripted format"
(
---------------------------------------------------------------------
--BOBO'S FILE FORMAT (BFF) 
--(formerly known as "Back From Five")
--Beta 0.4.2
--Started: 01/10/2002
--Edited : 09/24/2003
--Code by Borislav Petrov
--bobo@email.archlab.tuwien.ac.at
---------------------------------------------------------------------
--SHORT DESCRIPTION:
--Transfer basic scene data between different 3ds max versions
--using a MAXScript intermediate format which re-creates the
--objects when evaluated. No importer is required! 
---------------------------------------------------------------------
--WHY NOT USE ONE OF THE OTHER EXPORTERS?
--.3DS does not preserve UV coordinates completely
--.OBJ does not translate all max-specific properties 
--.ASE can only export, the unsupported importer is not available for all Max versions
---------------------------------------------------------------------
--CURRENTLY SUPPORTED FEATURES:
--*Geometry as EditableMesh incl. Modified Objects, Patches, NURBS, R4 Bones
--*EPoly via EditableMesh conversion on supported platforms, otherwise import as Editable Mesh.
--*Smoothing Groups
--*Edge Visibility
--*Material IDs
--*Name and Transforms
--*General Object Properties
--*User Properties Buffer
--*Texture coordinates - all UVW channels (both R4+ and R3+DLX implementation supported)
--*ColorVertices
--*Basic Material Tree support. Converts Materials and Maps, preserves most properties
--*Root Materials Instancing support
--*Texture Map Coordinate, Timing and Output Settings
--*Material Editor materials
--*Native SplineShape support
--*Cameras
--*Standard Lights
--*Helpers
--*Base Primitives
--*Basic Modifier Stack (limited number of non-topology dependent Modifiers supported)
--*Parent-Child Hierarchy
--*Animation controllers hierarchies, Bezier and TCB keys, Tangents, Before&After ORT
--*Scene Animation Segment and Current Time
---------------------------------------------------------------------
--POSSIBLE FUTURE FEATURES
--*Vertex Animation support
--*Skin Modifier support with Vertex Weights, Bones, Envelopes etc.
--*Environment settings
--*Basic Rendering settings 
--*Basic Patch support
---------------------------------------------------------------------

global bff_floater

local bff_roll
local generated_mesh_fn = false
local generated_spline_fn = false

local bff_version_number = "0.4.2"
local bff_version_date = "09/24/2003"
local scene_name = "Untitled"

local test_stack, out_name, materials_to_export_index, obj_cnt, base_dir_name

local max_version = maxversion()
max_version = max_version[1]
max_version /= 1000.0 


---------------------------------------------
-- EXPORT SPLINE DATA TO EXTERNAL BFF FILE -- 	
---------------------------------------------

fn export_spline_external o external_file_name =
(
	local out_file = createFile external_file_name
	e_spline = copy o
	addmodifier e_spline (edit_spline())
	collapsestack e_spline
	format "-------------------------------------------------------------------\n" to:out_file
	format "--  BFF Spline Definition For [%]\n" o.name to:out_file
	format "--  Version % - % \n" bff_version_number bff_version_date to:out_file
	format "--  Exporter by Borislav 'Bobo' Petrov \n" to:out_file
	format "--  http://www.scriptspot.com/bobo/    \n" to:out_file
	format "-------------------------------------------------------------------\n" to:out_file
	format "--  SOURCE SCENE NAME:    \t[%]          \n" scene_name to:out_file
	format "--  EXPORT DATE:          \t[%]          \n" localtime  to:out_file
	format "--  SOURCE VERSION:       \t[%]          \n" max_version to:out_file
	format "-------------------------------------------------------------------\n" to:out_file
	
	format "% \t--Spline Count\n" e_spline.NumSplines  to:out_file
	
	for s = 1 to e_spline.NumSplines do 
	(
		format "% \t--Spline Knot Count\n" (numKnots e_spline s) to:out_file
		format "% \t--Spline Closed?\n" (isClosed e_spline s) to:out_file
	)
	
	for s = 1 to e_spline.NumSplines do
	(	
		num_verts = (numKnots e_spline s)
 		bff_roll.current_action.text =  o.name + " : Knots in Spline " + s as string
		format "--KNOT LIST FOR SPLINE %\n" s to:out_file
		for v = 1 to num_verts do
		(
			bff_roll.local_progress.value = 100.0 * v / num_verts
			get_type = getKnotType e_spline s v
			get_vert = getKnotPoint e_spline s v
			get_in = getInVec e_spline s v
			get_out = getOutVec e_spline s v
			format "%, %, %, %, %\n" v get_type get_vert get_in get_out to:out_file
		)--end v loop

	)--end c loop
	
	format "-----------------\n" to:out_file
	format "-- End Of File --\n" to:out_file
	format "-----------------\n" to:out_file
	close out_file
	delete e_spline
)


-------------------------------------------
-- EXPORT MESH DATA TO EXTERNAL BFF FILE -- 	
-------------------------------------------

fn export_geometry_external o external_file_name =
(
	local out_file = createFile external_file_name
	o_mesh = snapshotAsMesh o
	format "-------------------------------------------------------------------\n" to:out_file
	format "--  BFF Mesh Definition For [%]\n" o.name to:out_file
	format "--  Version % - % \n" bff_version_number bff_version_date to:out_file
	format "--  Exporter by Borislav 'Bobo' Petrov \n" to:out_file
	format "--  http://www.scriptspot.com/bobo/    \n" to:out_file
	format "-------------------------------------------------------------------\n" to:out_file
	format "--  SOURCE SCENE NAME:    \t[%]          \n" scene_name to:out_file
	format "--  EXPORT DATE:          \t[%]          \n" localtime  to:out_file
	max_version = maxversion()
	max_version = max_version[1]
	max_version /= 1000.0 
	format "--  SOURCE VERSION:       \t[%]          \n" max_version to:out_file
	format "-------------------------------------------------------------------\n" to:out_file
	
	format "% \t--Vertex Count\n" o_mesh.numverts to:out_file
	format "% \t--Face Count\n" o_mesh.numfaces to:out_file
	
	channel_support_array = #()
	for c = 0 to 99 do if meshop.getMapSupport o_mesh c then append channel_support_array c
	
	format "% \t--Supported Texture Channels Count\n" channel_support_array.count to:out_file
	for c in channel_support_array do
	(
		format "% \t--Texture Channel Number\n" c to:out_file
		format "% \t--Texture Vertex Count \n" (meshop.getNumMapVerts o_mesh c) to:out_file
		format "% \t--Texture Faces Count  \n" (meshop.getNumMapFaces o_mesh c) to:out_file
	)
	
	format "% \t--Available Texture Channels\n" (meshop.getNumMaps o_mesh) to:out_file
	bff_roll.current_action.text = o.name + " : Verices"
	format "--VERTEX LIST:\n" to:out_file
	
	for v = 1 to o_mesh.numverts do
	(
		bff_roll.local_progress.value = 100.0 * v / o_mesh.numverts
		get_vert = getVert o_mesh v
		format "%, %\n" v get_vert to:out_file
	)--end v loop
	bff_roll.current_action.text =  o.name + " : Faces"
	format "--FACE LIST IN FORMAT\n" to:out_file
	format "--Index FaceDef MatID SmoothingGroup Edge1 Edge2 Egde3\n" to:out_file
	for f = 1 to o_mesh.numfaces do
	(
		bff_roll.local_progress.value = 100.0 * f / o_mesh.numfaces
		get_face = getFace o_mesh f
		format "%, %, " f get_face to:out_file
		get_face = getFaceMatId o_mesh f
		format "%, " get_face to:out_file
		get_face = getFaceSmoothGroup o_mesh f
		format "%, " get_face to:out_file
		get_edgevis_1 = getEdgeVis o_mesh f 1
		get_edgevis_2 = getEdgeVis o_mesh f 2
		get_edgevis_3 = getEdgeVis o_mesh f 3
		format "%, %, % \n" get_edgevis_1 get_edgevis_2 get_edgevis_3 to:out_file
	)--end f loop
	
	for c = 0 to channel_support_array.count-1 do
	(	
		num_map_verts = meshop.GetNumMapVerts o_mesh channel_support_array[c+1]
		bff_roll.current_action.text =  o.name + " : TVerices C:" + c as string
		format "--TEXTURE VERTEX LIST FOR CHANNEL %\n" c to:out_file
		for v = 1 to num_map_verts do
		(
			bff_roll.local_progress.value = 100.0 * v / num_map_verts
			get_vert = meshop.getMapVert o_mesh channel_support_array[c+1] v
			format "%, %\n" v get_vert to:out_file
		)--end v loop

		num_map_faces = meshop.GetNumMapFaces o_mesh channel_support_array[c+1]
		bff_roll.current_action.text =  o.name + " : TFaces C:" + c as string
		format "--TEXTURE FACES LIST FOR CHANNEL %\n" c to:out_file
		for f = 1 to num_map_faces do
		(
			bff_roll.local_progress.value = 100.0 * f / num_map_faces
			get_face = meshop.getMapFace o_mesh channel_support_array[c+1] f
			format "%, %\n" f get_face to:out_file
		)--end f loop
	)--end c loop
	
	format "-----------------\n" to:out_file
	format "-- End Of File --\n" to:out_file
	format "-----------------\n" to:out_file
	close out_file
)



------------------------------------
--EXPORT ANIMATION CONTROLLER TREE--
------------------------------------

fn getSubControllers contr =
(
	return_array = #()
	for i = 1 to contr.numsubs do
	(
		append return_array contr[i].controller
	)
return_array 	
)

fn exportControllerTree contr out_file rot_flag =
(
	subControllerArray = #(contr)
	subControllerPaths  = #("")
	cnt = 0
	while cnt < subControllerArray.count do
	(
		cnt += 1
		current_path = subControllerPaths[cnt]
		if cnt > 1 then 
		(
			try(format "try(bff_new_controller%.controller = %())catch()\n" current_path (classof subControllerArray[cnt]) to:out_file)catch()
			try(format "try(setBeforeORT bff_new_controller%.controller %)catch()\n" current_path (getBeforeORT subControllerArray[cnt]) to:out_file)catch()
			try(format "try(setAfterORT bff_new_controller%.controller %)catch()\n"  current_path (getAfterORT  subControllerArray[cnt]) to:out_file)catch()
		)
		
		try
		(
			keys_count = subControllerArray[cnt].keys.count
			if keys_count > 0 then
			(
				for k = 1 to keys_count do
				(
					current_key = getKey subControllerArray[cnt] k
					if cnt > 1 then
						try(format "try(bff_newKey = addNewKey bff_new_controller%.controller %)catch()\n" current_path current_key.time to:out_file)catch()
					else	
						try(format "try(bff_newKey = addNewKey bff_new_controller% %)catch()\n" current_path current_key.time to:out_file)catch()
					
					if rot_flag then
						try(format "try(bff_newKey.value = % )catch()\n" (degToRad current_key.value) to:out_file)catch()
					else
						try(format "try(bff_newKey.value = % )catch()\n" current_key.value to:out_file)catch()
					
					key_type = current_key as string
					if findstring key_type "Bezier" != undefined then
					(
						try(format "try(bff_newKey.inTangentType = #custom )catch()\n"  to:out_file)catch()
						try(format "try(bff_newKey.outTangentType = #custom )catch()\n" to:out_file)catch()
						try(format "try(bff_newKey.inTangent = % )catch()\n" (current_key.inTangent) to:out_file)catch()
						try(format "try(bff_newKey.outTangent = % )catch()\n" (current_key.outTangent) to:out_file)catch()
						try(format "try(bff_newKey.inTangentType = % )catch()\n" (current_key.inTangentType) to:out_file)catch()
						try(format "try(bff_newKey.outTangentType = % )catch()\n" (current_key.outTangentType) to:out_file)catch()
						try(format "try(bff_newKey.inTangentLength = % )catch()\n" (current_key.inTangentLength) to:out_file)catch()
						try(format "try(bff_newKey.outTangentLength = % )catch()\n" (current_key.outTangentLength) to:out_file)catch()
						try(format "try(bff_newKey.xLocked  = % )catch()\n" (current_key.xLocked) to:out_file)catch()
						try(format "try(bff_newKey.yLocked = % )catch()\n" (current_key.yLocked ) to:out_file)catch()
						try(format "try(bff_newKey.zLocked = % )catch()\n" (current_key.zLocked ) to:out_file)catch()
						try(format "try(bff_newKey.constantVelocity = % )catch()\n" (current_key.constantVelocity ) to:out_file)catch()
					)
					if findstring key_type "TCB" != undefined then
					(
						try(format "try(bff_newKey.tension = % )catch()\n" (current_key.tension ) to:out_file)catch()
						try(format "try(bff_newKey.continuity = % )catch()\n" (current_key.continuity ) to:out_file)catch()
						try(format "try(bff_newKey.bias = % )catch()\n" (current_key.bias ) to:out_file)catch()
						try(format "try(bff_newKey.easeTo = % )catch()\n" (current_key.easeTo ) to:out_file)catch()
						try(format "try(bff_newKey.easeFrom = % )catch()\n" (current_key.easeFrom ) to:out_file)catch()
					)
				)
			)
		)catch()	
		
		subs_array = (getSubControllers subControllerArray[Cnt])
		join subControllerArray subs_array
		for i = 1 to subs_array.count do 
			append subControllerPaths (current_path+"[" + i as string +"]")
	)
)

-------------------------------------------------
--PREPARE USER PROPERTIES BUFFER FOR EXPORT    --
-------------------------------------------------
fn getFixedUserPropBuffer obj =
(
  txt = getUserPropBuffer obj
  newtxt = ""
  for i = 1 to txt.count do 
  (
    subtxt = substring txt i 1
	if subtxt == "\"" then 
	  newtxt += "\\\""
	else
	  newtxt += subtxt
  )
  newtxt
)


-------------------------------------------------
--EXPORT PRS DATA AND GENERAL OBJECT PROPERTIES--
-------------------------------------------------
fn export_object_props o out_file =
(
	----------------------------
	--Export Object Properties--
	----------------------------
	format "-----------------------------------------------\n" to:out_file
	format "-- General Object Properties of [%] \n" o.name to:out_file
	format "-----------------------------------------------\n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"> Importing General Object Properties of [%]\" \n" o.name to:out_file	

	try(format "try(bff_new_obj.name = \"%\")catch()\n" o.name to:out_file)catch()
	try(format "try(bff_new_obj.scale = %)catch()\n" o.scale to:out_file)catch()
	try(format "try(bff_new_obj.rotation = %)catch()\n" o.rotation to:out_file)catch()
	try(format "try(bff_new_obj.pos = %)catch()\n" o.pos to:out_file)catch()
	
	
	try(format "try(bff_new_obj.castShadows = %)catch()\n" o.castShadows to:out_file)catch()
	try(format "try(bff_new_obj.receiveShadows = %)catch()\n" o.receiveShadows to:out_file)catch()
	try(format "try(bff_new_obj.gBufferChannel = %)catch()\n" o.gBufferChannel to:out_file)catch()
	
	try(format "try(bff_new_obj.inheritVisibility = %)catch()\n" o.inheritVisibility to:out_file)catch()
	try(format "try(bff_new_obj.renderable = %)catch()\n" o.renderable to:out_file)catch()
	try(format "try(bff_new_obj.renderOccluded = %)catch()\n" o.renderOccluded to:out_file)catch()
	try(format "try(bff_new_obj.motionBlurOn = %)catch()\n" o.motionBlurOn to:out_file)catch()
	try(format "try(bff_new_obj.motionBlur = %)catch()\n" o.motionBlur to:out_file)catch()
	try(format "try(bff_new_obj.imageMotionBlurMultiplier = %)catch()\n" o.imageMotionBlurMultiplier to:out_file)catch()
	try(format "try(bff_new_obj.rcvCaustics = %)catch()\n" o.rcvCaustics to:out_file)catch()
	try(format "try(bff_new_obj.generateCaustics = %)catch()\n" o.generateCaustics to:out_file)catch()
	try(format "try(bff_new_obj.rcvGlobalIllum = %)catch()\n" o.rcvGlobalIllum to:out_file)catch()
	try(format "try(bff_new_obj.generateGlobalIllum = %)catch()\n" o.generateGlobalIllum to:out_file)catch()
	
	format "-----------------------------------------------\n" to:out_file
	format "-- Display Properties of [%] \n" o.name to:out_file
	format "-----------------------------------------------\n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"> Importing Display Properties of [%]\" \n" o.name to:out_file	

	try(format "try(bff_new_obj.wirecolor = %)catch()\n" o.wirecolor to:out_file)catch()
	
	try(format "try(bff_new_obj.isSelected = %)catch()\n" o.isSelected to:out_file)catch()
	try(format "try(bff_new_obj.isHidden = %)catch()\n" o.isHidden to:out_file)catch()
	try(format "try(bff_new_obj.xRay = %)catch()\n" o.xRay to:out_file)catch()
	try(format "try(bff_new_obj.ignoreExtents = %)catch()\n" o.ignoreExtents to:out_file)catch()
	try(format "try(bff_new_obj.boxMode = %)catch()\n" o.boxMode to:out_file)catch()
	try(format "try(bff_new_obj.allEdges = %)catch()\n" o.allEdges to:out_file)catch()
	try(format "try(bff_new_obj.backFaceCull = %)catch()\n" o.backFaceCull to:out_file)catch()
	try(format "try(bff_new_obj.showLinks = %)catch()\n" o.showLinks to:out_file)catch()
	try(format "try(bff_new_obj.showLinksOnly = %)catch()\n" o.showLinksOnly to:out_file)catch()
	try(format "try(bff_new_obj.isFrozen = %)catch()\n" o.isFrozen to:out_file)catch()
	try(format "try(bff_new_obj.showTrajectory = %)catch()\n" o.showTrajectory to:out_file)catch()
	try(format "try(bff_new_obj.showVertexColors = %)catch()\n" o.showVertexColors to:out_file)catch()
	try(format "try(bff_new_obj.vertexColorType = %)catch()\n" o.vertexColorType to:out_file)catch()
	try(format "try(bff_new_obj.vertexColorsShaded = %)catch()\n" o.vertexColorsShaded to:out_file)catch()
	
	if bff_roll.export_animation.checked then 
	(
		format "-----------------------------------------------\n" to:out_file
		format "-- Animation Controllers of [%] \n"  o.name to:out_file
		format "-----------------------------------------------\n" to:out_file
		if bff_roll.include_report.checked then 
			format "bff_progressLog \"> Importing Animation Data of [%]\" \n" o.name to:out_file	
		
		subs = #()
		for i = 1 to o.numsubs do append subs o[i]
		for c = 1 to subs.count do
		(	
			for s = 1 to subs[c].numsubs do
			(
				try
				(
					if subs[c][s].isAnimated then 
					(
						format "try(bff_new_controller = %())catch()\n" (classof subs[c][s].controller) to:out_file
						format "try(bff_new_obj[%][%].controller = bff_new_controller)catch()\n" c s to:out_file
						exportControllerTree subs[c][s].controller out_file (superclassof subs[c][s].controller == RotationController)
					)	
				)
				catch()
			)--end s loop	
		)--end c loop
	)
	
	------------------------------	    
    --0.3.4: EXPORT USER PROPS! --
	------------------------------
	try(format "try(setUserPropBuffer bff_new_obj \"%\")catch()\n" (getFixedUserPropBuffer o) to:out_file)catch()
	
)--end export props

fn fixPath txt =
(
	new_txt = ""
	for i = 1 to txt.count do
	(
		if substring txt i 1 == "\\" then new_txt += "/" else new_txt += substring txt i 1 
	)--end i loop
new_txt 	
)--end fn

-------------------------------
--EXPORT MATERIAL PROPERTIES --
-------------------------------

fn export_material_tree mat out_file =
(
	if mat == undefined then
	(
		format "try(append bff_imported_materials undefined)catch()\n" to:out_file
	)
	else
	(
	--Initialize an array with the material tree root as the only element.
	mat_tree = #(mat)
	mat_path = #("root_material")
	counter = 0
	--Loop through all elements of the array
	while counter < mat_tree.count do
	(
		counter += 1								-- increase the index 
		current_object = mat_tree[counter]			-- get the current element of the array
		current_map_path = mat_path[counter]		-- get the current object path 

		current_props = GetPropNames current_object -- get the properties list of the current element
		--Create an instance of the material's/map's class in the target scene:
		
		
		if bff_roll.include_report.checked then 
		(
			if superclassof current_object == Material then 
				format "try(new_mat = % = %())catch(new_mat = % = Standardmaterial())\n" current_map_path (classof current_object) current_map_path to:out_file
			else
				format "try(new_mat = % = %())catch(new_mat = % = bitmaptexture())\n" current_map_path (classof current_object) current_map_path to:out_file
		)
		else
		(
			if superclassof current_object == Material then 
				format "try(new_mat = % = %())catch()\n" current_map_path (classof current_object) to:out_file
			else
				format "try(new_mat = % = %())catch()\n" current_map_path (classof current_object) to:out_file
		)	
		
		--and set the name, too
		format "try(new_mat.name = \"%\")catch()\n"  current_object.name to:out_file	
		
		if superclassof current_object == textureMap then
		(
			try (test_coords = classof current_object.coordinates)catch(test_coords = undefined)
			if test_coords == StandardUVGen then
			(
				coord_props = getPropNames current_object.coordinates
				for u = coord_props.count to 1 by -1 do
				(
					current_uv_prop = GetProperty current_object.coordinates coord_props[u]
				    if classof current_uv_prop == String then
						format "try(SetProperty new_mat.coordinates #% \"%\")catch()\n"  (coord_props[u] as string) current_uv_prop to:out_file
					else
						format "try(SetProperty new_mat.coordinates #% %)catch()\n" (coord_props[u] as string) current_uv_prop to:out_file
				)--end u loop
			)
			try (test_out = classof current_object.output) catch(test_out = undefined)
			if test_out == StandardTextureOutput then
			(
				output_props = getPropNames current_object.output
				for p in output_props do
				(
					current_out_prop = GetProperty current_object.output p
				    if classof current_out_prop == String then
						format "try(SetProperty new_mat.output #% \"%\")catch()\n"  (p as string) current_out_prop to:out_file
					else
						format "try(SetProperty new_mat.output #% %)catch()\n" (p as string) current_out_prop to:out_file
				)--end u loop
			)
		)
		--Now go through all properties found in the current element...
		for i in current_props do
		(
			current_prop = GetProperty current_object i		--get the value of the property
			if superclassof current_prop == material then	--if the property itself is a material...
			(
				append mat_tree current_prop
				new_map_path = (current_map_path+"."+ i as string )
				append mat_path new_map_path
				--create a new sub-leaf of the current element
				format "try(% = %())catch()\n" new_map_path (classof current_prop) to:out_file
				format "try(%.name = \"%\")catch() \n" new_map_path current_prop.name to:out_file
				--append this as an element for future recursion
			)--end if Material
			
			if superclassof current_prop == textureMap then
			(
				append mat_tree current_prop
				new_map_path = (current_map_path+"."+ i as string )
				append mat_path new_map_path
				--create a new sub-leaf of the current element
				format "try(% = %())catch()\n" new_map_path (classof current_prop) to:out_file
				format "try(%.name = \"%\")catch()\n" new_map_path current_prop.name to:out_file
				--append this as an element for future recursion
			)--end if texture				
			if superclassof current_prop == value or superclassof current_prop == Number then
			(
				if i != #bitmap then
				(
				    if classof current_prop == String then
					(
						if i == #filename then
							format "try(SetProperty new_mat #% \"%\")catch()\n"  (i as string) (fixPath current_prop) to:out_file
						else
							format "try(SetProperty new_mat #% \"%\")catch()\n"  (i as string) current_prop to:out_file
					)	
					else
					(
						format "try(SetProperty new_mat #% %)catch()\n" (i as string) current_prop to:out_file
					)	
				)
			)--end if Value
			if classof current_prop == ArrayParameter then
			(
				for a = 1 to current_prop.count do
				(
					if superclassof current_prop[a] == Value or superclassof current_prop[a] == Number  then
					(
						if classof current_prop[a] == String then
							format "try(new_mat.%[%] = \"%\")catch()\n" (i as string) a current_prop[a] to:out_file
						else						
							format "try(new_mat.%[%] = %)catch()\n" (i as string) a current_prop[a] to:out_file
					)	
					else	
					(
						append mat_tree current_prop[a]
						new_map_path = (current_map_path+"."+ i as string + "["+ a as string +"]" )
						append mat_path new_map_path
					)	
				)--end a loop
			)--end if ArrayParameter
		)--end i loop
	)--end while
	format "try(append bff_imported_materials root_material)catch(append bff_imported_materials (standardmaterial()))\n" to:out_file
	)
)--end export material


------------------------------
-- EXPORT OBJECT PROPERTIES --
------------------------------

fn export_properties o out_file =
(
	current_props = GetPropNames o
	for i in current_props do
	(
		try
		(
			current_prop = GetProperty o i		
			if superclassof current_prop == Value or superclassof current_prop == Number then
			(
			    if classof current_prop == String then 					format "try(SetProperty bff_new_obj #% \"%\")catch()\n"  (i as string) current_prop to:out_file
				else
					format "try(SetProperty bff_new_obj #% %)catch()\n" (i as string) current_prop to:out_file
			)--end if 
		)catch()	
	)
)

--------------------------------
-- EXPORT MODIFIER PROPERTIES --
--------------------------------

fn export_mod_properties o out_file =
(
	current_props = GetPropNames o
	for i in current_props do
	(
		try
		(
			current_prop = GetProperty o i		
			if superclassof current_prop == Value or superclassof current_prop == Number then
			(
			    if classof current_prop == String then
					format "try(SetProperty new_mod #% \"%\")catch()\n"  (i as string) current_prop to:out_file
				else
					format "try(SetProperty new_mod #% %)catch()\n" (i as string) current_prop to:out_file
			)--end if 
		)catch()
	)
)

-----------------------------
-- EXPORT PRIMITIVE OBJECT --
-----------------------------

fn export_primitives o obj out_file =
(
	format "-----------------------------------------------\n" to:out_file
	format "-- Primitive: [%] \n" o.name to:out_file
	format "-----------------------------------------------\n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"> Importing Primitive [%]\"  \n" o.name to:out_file	
	format "try(bff_new_obj = %())catch()\n" (classof obj) to:out_file
)

--------------------------
-- EXPORT HELPER OBJECT --
--------------------------

fn export_helpers o out_file =
(
	format "-----------------------------------------------\n" to:out_file
	format "-- Helper Object: [%] \n" o.name to:out_file
	format "-----------------------------------------------\n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"> Importing Helper [%]\"  \n" o.name to:out_file	

	format "try(bff_new_obj = %())catch()\n" (classof o) to:out_file
	if o.target != undefined then
	(
		format "try(bff_new_obj.target = TargetObject name:\"%\" pos:%)catch()\n" o.target.name o.target.pos to:out_file
	)
)


-------------------------
-- EXPORT LIGHT OBJECT --
-------------------------

fn export_standard_lights o out_file =
(
	format "-----------------------------------------------\n" to:out_file
	format "-- Light Object: [%] \n" o.name to:out_file
	format "-----------------------------------------------\n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"> Importing Light [%]\"  \n" o.name to:out_file	
	format "try(bff_new_obj = %())catch()\n" (classof o) to:out_file
	if o.target != undefined then
	(
		format "try(bff_new_obj.target = TargetObject name:\"%\" pos:%)catch()\n" o.target.name o.target.pos to:out_file
	)
)


--------------------------
-- EXPORT CAMERA OBJECT --
--------------------------

fn export_cameras o out_file =
(
	format "-----------------------------------------------\n" to:out_file
	format "-- Camera Object: [%] \n" o.name to:out_file
	format "-----------------------------------------------\n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"> Importing Camera [%]\"  \n" o.name to:out_file	

	format "try(bff_new_obj = %())catch()\n" (classof o) to:out_file
	if o.target != undefined then
	(
		format "try(bff_new_obj.target = TargetObject name:\"%\" pos:%)catch()\n" o.target.name o.target.pos to:out_file
	)
)

------------------------------
-- GENERATE PROGRESS DIALOG --
------------------------------
fn generate_progress_dialog out_file =
(
	format "global bff_import_floater,bff_import_progress, bff_progressLog \n" to:out_file
	format "rollout bff_import_progress \"BFF Import Progress Report\" (\n" to:out_file
	format "listbox bff_import_messages items:#() align:#center\n" to:out_file	
	format "progressbar bff_import_bar height:10 width:450 align:#center\n" to:out_file	
	format ")\n" to:out_file	
	format "try(closeRolloutFloater bff_import_floater)catch()\n" to:out_file	
	format "bff_import_floater = newRolloutFloater \"BFF Import\" 500 220 0 100\n" to:out_file	
	format "addRollout bff_import_progress bff_import_floater\n" to:out_file	
	format "fn bff_progressLog txt = (\n" to:out_file	
	format "old_items = bff_import_progress.bff_import_messages.items\n" to:out_file	
	format "append old_items txt\n" to:out_file	
	format "bff_import_progress.bff_import_messages.items = old_items\n" to:out_file	
	format "bff_import_progress.bff_import_messages.selection = old_items.count\n" to:out_file	
	format ")\n" to:out_file	
)

-------------------------------------
-- GENERATE SPLINE IMPORT FUNCTION --
-------------------------------------

fn generate_spline_code out_file =
(
	format "fn bff_import_external_spline ext_file = (\n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"> Importing Spline Data From External File...\"\n" to:out_file	
	format "try(\n" to:out_file
	format "num_splines = readValue ext_file \n" to:out_file
	format "spline_verts = #()\n" to:out_file
	format "spline_closed= #()\n" to:out_file
				
	format "for s = 1 to num_splines do\n(\n" to:out_file
	format "  append spline_verts (readValue ext_file)\n" to:out_file
	format "  append spline_closed (readValue ext_file)\n" to:out_file
	format ")\n" to:out_file

	format "bff_new_obj = splineShape() \n" to:out_file

	format "for s = 1 to num_splines do\n(\n" to:out_file
	format "  addNewSpline bff_new_obj\n" to:out_file
	format "  for v = 1 to spline_verts[s] do\n  (\n" to:out_file
	format "    readValue ext_file\n" to:out_file
	format "    addKnot bff_new_obj s (readValue ext_file) #curve (readValue ext_file) (readValue ext_file) (readValue ext_file) \n  )\n" to:out_file
	format "  if spline_closed[s] then close bff_new_obj s \n" to:out_file
	
	format ")\n" to:out_file
	format "updateShape bff_new_obj\n" to:out_file
	format "bff_new_obj\n" to:out_file
	if bff_roll.include_report.checked then 
		format ")catch(bff_progressLog \"-- Spline Import From External File FAILED.\")\n" to:out_file	
	else	
		format ")catch()\n" to:out_file	
	format ")\n" to:out_file
)


-----------------------------------
-- GENERATE MESH IMPORT FUNCTION --
-----------------------------------

fn generate_meshing_code out_file =
(
	format "fn bff_import_external_geometry ext_file = (\n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"> Importing Mesh Data From External File...\"\n" to:out_file	
	format "try(\n" to:out_file
	format "num_verts = readValue ext_file \n" to:out_file
	format "num_faces = readValue ext_file \n" to:out_file
	format "num_uvw_channels = readValue ext_file \n" to:out_file
	format "uvw_channels = #()\n" to:out_file
	format "uvw_channel_verts = #()\n" to:out_file
	format "uvw_channel_faces = #()\n" to:out_file
				
	format "for c = 1 to num_uvw_channels do\n(\n" to:out_file
	format "  append uvw_channels (readValue ext_file)\n" to:out_file
	format "  append uvw_channel_verts (readValue ext_file)\n" to:out_file
	format "  append uvw_channel_faces (readValue ext_file)\n" to:out_file
	format ")\n" to:out_file

	format "num_maps = readValue ext_file \n" to:out_file
				
	format "bff_new_obj = mesh numverts:num_verts numfaces:num_faces \n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"+ Created EditableMesh Object.\"\n" to:out_file

	if bff_roll.include_report.checked then 
		format "bff_progressLog \"> Reading Vertex Data...\"\n" to:out_file

	format "for v = 1 to num_verts do\n(\n" to:out_file
	format "  readValue ext_file\n" to:out_file
	if bff_roll.include_report.checked then 
		format "  bff_import_progress.bff_import_bar.value = 100.0*v/num_verts \n" to:out_file
	format "  setVert bff_new_obj v (readValue ext_file) \n" to:out_file
	format ")\n" to:out_file

	if bff_roll.include_report.checked then 
		format "bff_progressLog \"> Reading Face Data...\"\n" to:out_file
			
	format "for f = 1 to num_faces do\n(\n" to:out_file
	format "  readValue ext_file\n" to:out_file
	if bff_roll.include_report.checked then 
		format "  bff_import_progress.bff_import_bar.value = 100.0*f/num_verts \n" to:out_file
	format "  new_face = readValue ext_file \n" to:out_file		 		
	format "  setFace bff_new_obj f new_face.x new_face.y new_face.z \n" to:out_file
	format "  setFaceMatID bff_new_obj f (readValue ext_file)\n" to:out_file
	format "  setFaceSmoothGroup bff_new_obj f (readValue ext_file)\n" to:out_file
	format "  setEdgeVis bff_new_obj f 1 (readValue ext_file)\n" to:out_file
	format "  setEdgeVis bff_new_obj f 2 (readValue ext_file)\n" to:out_file
	format "  setEdgeVis bff_new_obj f 3 (readValue ext_file)\n" to:out_file
	format ")\nupdate bff_new_obj\n" to:out_file	
	if bff_roll.include_report.checked then 
		format ")catch(bff_progressLog \"-- Mesh Import From External File FAILED.\")\n" to:out_file	
	else	
		format ")catch()\n" to:out_file	
				

	-----------------------------------
	--Assign UVW Coordinates in 4.x+ --
	-----------------------------------
				
	format "try(\n" to:out_file
	format "meshop.setNumMaps bff_new_obj num_maps \n" to:out_file
	format "for c = 1 to uvw_channels.count do\n(\n" to:out_file
	format "  meshop.setMapSupport bff_new_obj uvw_channels[c] true\n" to:out_file
	format "  meshop.setNumMapVerts bff_new_obj uvw_channels[c] uvw_channel_verts[c]\n" to:out_file
	format "  meshop.setNumMapFaces bff_new_obj uvw_channels[c] uvw_channel_faces[c]\n" to:out_file
	if bff_roll.include_report.checked then 
		format "  bff_progressLog (\"> Reading TextureVertex Data for Channel \" + (c-1) as string) \n" to:out_file
	format "  for v = 1 to uvw_channel_verts[c] do\n  (\n" to:out_file
	if bff_roll.include_report.checked then 
		format "    bff_import_progress.bff_import_bar.value = 100.0*v/num_verts \n" to:out_file
	format "    readValue ext_file\n" to:out_file
	format "    meshop.setMapVert bff_new_obj uvw_channels[c] v (readValue ext_file)\n  )\n" to:out_file
	if bff_roll.include_report.checked then 
		format "  bff_progressLog (\"> Reading TextureFace Data for Channel \"+ (c-1) as string) \n" to:out_file
	format "  for f = 1 to uvw_channel_faces[c] do \n  (\n" to:out_file
	format "    readValue ext_file\n" to:out_file
	if bff_roll.include_report.checked then 
		format "    bff_import_progress.bff_import_bar.value = 100.0*f/num_verts \n" to:out_file
	format "    meshop.setMapFace bff_new_obj uvw_channels[c] f (readValue ext_file)\n  )\n" to:out_file
	format ")\n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"+ Assigned R4-Style Texture Coordinates.\"\n" to:out_file
	if bff_roll.include_report.checked then 
		format ")catch(bff_progressLog \"!! Failed to assign R4-Style Texture Coordinates\")\n" to:out_file
	else		
		format ")catch()\n" to:out_file

	----------------------------------------------------------------
	--Try to Assign UVW Coordinates in 3.x with Simon's Extension --
	----------------------------------------------------------------

	format "try(\n" to:out_file
	format "setNumMaps bff_new_obj num_maps \n" to:out_file
	format "for c = 1 to uvw_channels.count do\n(\n" to:out_file
	format "  setMapSupport bff_new_obj uvw_channels[c] true\n" to:out_file
	format "  setNumMapVerts bff_new_obj uvw_channels[c] uvw_channel_verts[c]\n" to:out_file
	format "  setNumMapFaces bff_new_obj uvw_channels[c] uvw_channel_faces[c]\n" to:out_file
	if bff_roll.include_report.checked then 
		format "  bff_progressLog (\"> Reading TextureVertex Data for Channel \" + (c-1) as string) \n" to:out_file
	format "  for v = 1 to uvw_channel_verts[c] do \n  (\n" to:out_file
	format "    readValue ext_file\n" to:out_file
	if bff_roll.include_report.checked then 
		format "    bff_import_progress.bff_import_bar.value = 100.0*v/num_verts \n" to:out_file
	format "    setMapVert bff_new_obj uvw_channels[c] v (readValue ext_file)\n  )\n" to:out_file
	if bff_roll.include_report.checked then 
		format "  bff_progressLog (\"> Reading TextureFace Data for Channel \"+ (c-1) as string) \n" to:out_file
	format "  for f = 1 to uvw_channel_faces[c] do \n  (\n" to:out_file
	format "    readValue ext_file\n" to:out_file
	if bff_roll.include_report.checked then 
		format "    bff_import_progress.bff_import_bar.value = 100.0*f/num_verts \n" to:out_file
 	format "    setMapFace bff_new_obj uvw_channels[c] f (readValue ext_file)\n  )\n" to:out_file
	format ")\n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"+ Assigned R3-Style Texture Coordinates.\"\n" to:out_file
	if bff_roll.include_report.checked then 
		format ")catch(bff_progressLog \"!! Failed to assign R3-Style Texture Coordinates.\")\n" to:out_file
	else
		format ")catch()\n" to:out_file

	format "bff_new_obj)\n" to:out_file	
)


--------------------------------------------
--CHECK WHETHER THE STACK CAN BE EXPORTED --
--------------------------------------------

fn canExportStack o =
(
	supported_modifiers = #(Bend, Extrude, Materialmodifier, MeshSmooth, Skin, Twist, Taper)
	supported = true
	if (superclassof o.baseobject) != GeometryClass and (classof o.baseobject) != SplineShape and (classof o.baseobject) != Line and (superclassof o.baseobject) != Shape then supported = false
	try
	(
		if ((getFaceSelection o)as array).count > 0 then supported = false
		if ((getVertSelection o)as array).count > 0 then supported = false
		if ((getEdgeSelection o)as array).count > 0 then supported = false
	)catch()
	for m in o.modifiers do if findItem supported_modifiers (classof m) == 0 then supported = false
	if bff_roll.force_emesh.checked then supported = false
supported
)


--------------------------
--EXPORT MODIFIER STACK --
--------------------------

fn export_supported_modifiers o out_file = 
(
	for m = o.modifiers.count to 1 by -1 do
	(
		format "-----------------------------------------------\n" to:out_file
		format "-- Modifier Object: [%] \n" o.modifiers[m] to:out_file
		format "-----------------------------------------------\n" to:out_file
		format "try(new_mod = %())catch()\n" (classof o.modifiers[m]) to:out_file
		format "try(new_mod.enabled = %)catch()\n" (o.modifiers[m].enabled) to:out_file
		format "try(new_mod.enabledInViews = %)catch()\n" (o.modifiers[m].enabledInViews) to:out_file
		export_mod_properties o.modifiers[m] out_file	
		format "try(addModifier bff_new_obj new_mod)catch()\n" to:out_file
	)
)


fn export_emesh o obj out_file =
(
	modifiers_enabled_state = #()
	if test_stack then 
	(
		for m in o.modifiers do 
		(
			append modifiers_enabled_state m.enabled
			m.enabled = false
		)	
	)	
    format "----------------------------------------\n" to:out_file
	format "-- Mesh Object: [%]\n" o.name to:out_file
    format "----------------------------------------\n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"> Importing EditableMesh [%]\" \n" o.name to:out_file	

	old_tm = o.transform
	o.transform = (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
	create_geometry_path = (base_dir_name+"Meshes")
	makeDir create_geometry_path 
	full_external_name = (base_dir_name+"Meshes/"+o.name+".bff")
	external_name = (getFileNameFile out_name + "/Meshes/"+o.name+".bff")
	export_geometry_external o full_external_name
	o.transform = old_tm 
	
	format "bff_ext_file = openFile \"%\"\n" external_name to:out_file
	
	format "try(bff_new_obj = bff_import_external_geometry bff_ext_file)catch()\n" to:out_file
	format "try(close bff_ext_file)catch()\n" to:out_file					
	if classof obj == Editable_poly do 
		format "try(convertTo bff_new_obj Editable_Poly)catch()\n" to:out_file					
	
	if test_stack then 
	(
		for m = 1 to o.modifiers.count do 
		(
			o.modifiers[m].enabled = modifiers_enabled_state[m]
		)	
		export_supported_modifiers o out_file
	)	
	export_object_props o out_file
	if bff_roll.export_mats.checked do 
		format "try(bff_new_obj.material = bff_imported_materials[%])catch()\n" materials_to_export_index[obj_cnt] to:out_file					
)--end export mesh	


fn export_spline o obj out_file = 
(
	modifiers_enabled_state = #()
	if test_stack then 
	(
		for m in o.modifiers do 
		(
			append modifiers_enabled_state m.enabled
			m.enabled = false
		)	
	)	

    format "----------------------------------------\n" to:out_file
	format "-- EditableSpline Object: [%]\n" o.name to:out_file
	format "----------------------------------------\n" to:out_file
	if bff_roll.include_report.checked then 
		format "bff_progressLog \"> Importing EditableSpline [%]\" \n" o.name to:out_file	
	
	old_tm = o.transform
	o.transform = (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
	create_spline_path = (base_dir_name+"Splines")
	makeDir create_spline_path 
	full_external_name = (base_dir_name+"Splines/"+o.name+".bff")
	external_name = (getFileNameFile out_name + "/Splines/"+o.name+".bff")
	export_spline_external o full_external_name
	o.transform = old_tm 
	
	format "bff_ext_file = openFile \"%\"\n" external_name to:out_file
	
	format "try(bff_new_obj = bff_import_external_spline bff_ext_file)catch() \n" to:out_file
	format "try(close bff_ext_file)catch()\n" to:out_file	
	if test_stack then 
	(
		for m = 1 to o.modifiers.count do 
		(
			o.modifiers[m].enabled = modifiers_enabled_state[m]
		)	
		export_supported_modifiers o out_file
	)	
	export_object_props o out_file		
	if bff_roll.export_mats.checked then 
	(
		format "-----------------------------------------------\n" to:out_file
		format "-- Material Assignment \n" to:out_file
		format "-----------------------------------------------\n" to:out_file
		format "try(bff_new_obj.material = bff_imported_materials[%])catch()\n" materials_to_export_index[obj_cnt] to:out_file					
	)	
)

fn build_zip_file out_file base_dir =
(
	thePath = GetFileNamePath out_file 
	print thePath 
	archive_file = (thePath+"Archive.txt")
	thePath += GetFileNameFile out_file
	zip_destination = (thePath + ".zip")
	temp_archive_file = createfile archive_file 
	files_to_archive = #(out_file)
	join files_to_archive (getFiles (thePath + "/Objects/*.ms"))
	join files_to_archive (getFiles (thePath + "/Splines/*.bff"))
	join files_to_archive (getFiles (thePath + "/Meshes/*.bff"))
	for f in files_to_archive do format "%\n" f to:temp_archive_file 
	close temp_archive_file 
	ShellLaunch ((GetDir #maxroot)+"maxzip.exe") (zip_destination+(" @"+archive_file))
)

fn export_to_bff file_name base_dir=
(
	generated_mesh_fn = false
	scene_name = maxFileName
	if scene_name == "" then scene_name = "Untitled"
	out_name = file_name
	base_dir_name = base_dir
	out_file = createfile out_name
	format "-------------------------------------------------------------------\n" to:out_file
	format "--  BFF MAXScript Scene I/O   \n" to:out_file
	format "--  Version % - %         \n" bff_version_number bff_version_date to:out_file
	format "--  Exporter by Borislav 'Bobo' Petrov \n" to:out_file
	format "--  http://www.scriptspot.com/bobo/darkmoon/bff \n" to:out_file
	format "-------------------------------------------------------------------\n" to:out_file
	format "--  SOURCE SCENE NAME:    \t[%]          \n" scene_name to:out_file
	format "--  EXPORT DATE:          \t[%]          \n" localtime  to:out_file
	format "--  ORIGINAL EXPORT PATH: \t[%]          \n" out_name to:out_file
	format "--  SOURCE VERSION:       \t[%]          \n" max_version to:out_file
	format "-------------------------------------------------------------------\n" to:out_file
	format "undo off (\n" to:out_file
	format "global bff_new_obj, bff_ext_file, bff_new_controller, bff_newKey, bff_import_external_geometry, bff_import_external_spline \n" to:out_file
	if bff_roll.include_report.checked then generate_progress_dialog out_file	
	format "resetmaxfile() \n" to:out_file

	format "animationrange = %\n" animationrange to:out_file
	format "sliderTime = %\n" SliderTime to:out_file

	format "------------------------\n" to:out_file
	format "-- IMPORTER FUNCTIONS --\n" to:out_file
	format "------------------------\n" to:out_file	
	generate_meshing_code out_file
	generate_spline_code out_file
	
	if bff_roll.include_report.checked then 
	(
		format "import_start_time = timestamp()\n" to:out_file
		format "bff_progressLog \"> INITIATED BFF SCENE IMPORT...\"\n" to:out_file	
	)	
	
	if bff_roll.export_mats.checked then 
	(
		if bff_roll.include_report.checked then 
			format "bff_progressLog \"> Preparing Materials...\"\n" to:out_file	
		format "global bff_imported_materials = #()\n" to:out_file
	)	
	obj_cnt = 0
	if bff_roll.export_selected.checked then objects_to_export = selection as array else objects_to_export = objects as array 

	if bff_roll.export_mats.checked then 
	(
		--Collect a list of all materials assigned to the objects to export...
		materials_to_export = #()
		materials_to_export_index = #()

		if bff_roll.export_medit.checked then
		(
			for m in meditmaterials do
				append materials_to_export m
		)
		
		format "---------------------\n" to:out_file
		format "-- SCENE MATERIALS --\n" to:out_file
		format "---------------------\n" to:out_file
		
		for o in objects_to_export do
		(
			if findItem materials_to_export o.material == 0 then 
			(
				append materials_to_export_index (materials_to_export.count+1)
				append materials_to_export o.material
			)	
			else
			(
				append materials_to_export_index (findItem materials_to_export o.material)
			)
		)--end o loop
		for m in materials_to_export do
			export_material_tree m out_file

		if bff_roll.export_medit.checked then
		(
			format "---------------------\n" to:out_file
			format "-- MEDIT MATERIALS --\n" to:out_file
			format "---------------------\n" to:out_file		
			format "try(for i = 1 to 24 do meditmaterials[i] = bff_imported_materials[i])catch()\n" to:out_file
		)	
	)	
	
	
	--Now go through all objects and export them...
	
	format "-------------------\n" to:out_file
	format "-- SCENE OBJECTS --\n" to:out_file
	format "-------------------\n" to:out_file	
	
	for o in objects_to_export do
	(
		create_object_path = (base_dir_name+"Objects")
		makeDir create_object_path 
		full_external_name = (base_dir_name+"Objects\\"+o.name+".ms")
		external_name = (getFileNameFile out_name + "\\Objects\\"+o.name+".ms")
		external_object_file = createFile full_external_name 
		if bff_roll.include_report.checked then 
			txt = "bff_progressLog \"-- Import of Object [" + o.name + "] FAILED! \""
		else
			txt = ""
		format "try(fileIn \"%\")catch(%)" (external_name) txt to:out_file					
		
		obj_cnt += 1
		bff_roll.scene_progress.value = (100.0 * obj_cnt / objects_to_export.count)
		test_stack = canExportStack o
		if test_stack then 
			obj = o.baseObject
		else
			obj = o
		if superclassof o == GeometryClass and classof o != TargetObject and bff_roll.export_geometry.checked  then
		(
			if (test_stack and classof o.baseobject != SplineShape and classof o.baseobject != Line and classof o.baseobject != Editable_mesh and classof o.baseobject != Editable_patch and classof o.baseobject != Editable_Poly and classof o != BoneGeometry) then
			(
				export_primitives o obj external_object_file
				export_properties obj external_object_file	
				if test_stack do export_supported_modifiers o external_object_file
				export_object_props o external_object_file
				if bff_roll.export_mats.checked do 
					format "try(bff_new_obj.material = bff_imported_materials[%])catch()\n" materials_to_export_index[obj_cnt] to:external_object_file					
			)
			if (classof o.baseobject == Editable_mesh or classof o.baseobject == Editable_patch or classof o.baseobject == Editable_Poly or classof o == BoneGeometry or not test_stack) then
			(
				export_emesh o obj external_object_file
            )
		)--end if geometry
		
		if superclassof o == Shape and classof o != SplineShape and o.modifiers.count == 0 and classof o != Line do
		(
			export_primitives o obj external_object_file
			export_properties o external_object_file	
			export_object_props o external_object_file		
			if bff_roll.export_mats.checked do 
				format "try(bff_new_obj.material = bff_imported_materials[%])catch()\n" materials_to_export_index[obj_cnt] to:external_object_file					
		)--end if shape
		
		if (superclassof obj == Shape and classof obj == SplineShape and bff_roll.export_splines.checked) or (classof obj == Line and bff_roll.export_splines.checked) do
		(
			export_spline o obj external_object_file
		)--end spline 
		
		if superclassof o == Light and bff_roll.export_lights.checked then
		(
			export_standard_lights o external_object_file
			export_properties o external_object_file	
			export_object_props o external_object_file		
		)--end if light
		
		if superclassof o == Camera and bff_roll.export_cameras.checked then
		(
			export_cameras o external_object_file
			export_properties o external_object_file	
			export_object_props o external_object_file		
		)--end if camera
		
		if superclassof o == Helper and bff_roll.export_helpers.checked then
		(
			export_helpers o external_object_file
			export_properties o external_object_file	
			export_object_props o external_object_file	
		)--end if helper
		
		format "\n" to:out_file
		close external_object_file
	)--end o loop
	
	
	
	format "---------------\n" to:out_file
	format "-- Hierarchy --\n" to:out_file
	format "---------------\n" to:out_file		
	
	for o in objects_to_export do
	(
		if o.parent != undefined then 
			format "try($'%'.parent = $'%')catch() \n" o.name o.parent.name to:out_file		
	)-- end o loop
	
	if bff_roll.include_report.checked then 
	(
		format "import_end_time = timestamp()\n" to:out_file
		format "bff_progressLog (\"+ BFF SCENE IMPORT FINISHED IN \"+ ((import_end_time-import_start_time)/1000.0) as string + \" sec.\" )\n" to:out_file	
		format "bff_progressLog \"Ready.\"\n" to:out_file	
	)
	format ")\n" to:out_file
	format "-----------------\n" to:out_file
	format "-- End Of File --\n" to:out_file
	format "-----------------\n" to:out_file
	close out_file 
	gc light:true
	edit out_name
)--end function



rollout bff_roll "BFF Exporter"
(
	group "Export Classes:"
	(
		checkbutton export_geometry "Geometry"  across:2 align:#left 	width:85  highlightcolor:(color 200 255 200)	checked:true
		checkbutton export_mats     "Materials" align:#right 			width:85  highlightcolor:(color 200 255 200) 	checked:true
		checkbutton export_lights   "Lights"    across:2 align:#left 	width:85  highlightcolor:(color 200 255 200)	checked:true
		checkbutton export_cameras  "Cameras"   align:#right         	width:85  highlightcolor:(color 200 255 200)	checked:true
		checkbutton export_splines  "Splines"  	across:2 align:#left 	width:85  highlightcolor:(color 200 255 200)	checked:true
		checkbutton export_helpers  "Helpers"  	align:#right         	width:85  highlightcolor:(color 200 255 200)	checked:true
	) 
	group "Preferences:"
	(
		checkbutton force_emesh "Collapse Stack"  		across:2 align:#left 	width:85  	highlightcolor:(color 255 200 200)	checked:false
		checkbutton export_animation "Animation" 		align:#right			width:85	highlightcolor:(color 200 255 200)	checked:true
		
		checkbutton export_medit "Material Editor"  	across:2 align:#left 	width:85  	highlightcolor:(color 200 255 200)	checked:true
		checkbutton export_to_zip "ZIP Archive" 		align:#right			width:85	highlightcolor:(color 255 255 200)	checked:false
		
		checkbutton include_report "Progress Report" 	across:2 align:#left 	width:85	highlightcolor:(color 200 255 200)	checked:true tooltip:"Uncheck for partial MAX 2.5 compatibility"
		checkbutton export_selected "Selected Only" 	align:#right			width:85	highlightcolor:(color 255 255 200)	checked:false

		
	) 
	
	button export_the_scene "EXPORT SCENE" width:190 height:30 align:#center
	label current_action "Ready." align:#center
	progressbar scene_progress height:10 width:180 align:#center color:(color 0 0 100)
	progressbar local_progress height:10 width:180 align:#center color:(color 100 0 0)
	on export_selected changed state do 
	(
		if state then 
			export_the_scene.text = "EXPORT SELECTED OBJECTS"
		else	
			export_the_scene.text = "EXPORT SCENE"
	)
	
	on export_the_scene pressed do 
	(
		generated_spline_fn = false
		generated_mesh_fn = false
		out_name = getSaveFileName Types:"MAXScript Scene *.ms |*.ms"
		if out_name != undefined then 
		(
			baseDir = (getFileNameFile out_name)
			makeDir baseDir
			new_path = (getFileNamePath out_name)
			final_name = new_path + (fileNameFromPath out_name)
			export_to_bff final_name (baseDir+"\\")
			if export_to_zip.checked do
			(
				build_zip_file final_name (baseDir+"\\")
			)
		)	
		scene_progress.value = 0.0
		local_progress.value = 0.0
		current_action.text = "Ready."
	)	
)
try(closeRolloutFloater bff_floater)catch()
bff_floater = newRolloutFloater "BFF v0.4.2" 212 326
addrollout bff_roll bff_floater 
)--end script
