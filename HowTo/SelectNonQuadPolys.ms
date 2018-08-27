macroscript SelectNonQuadPolys category:"HowTo"
(

	on isEnabled return 
	(
		selection.count == 1 and classOf selection[1].baseobject == Editable_Poly
	)

	on execute do
	(
		 local face_selection = #{}
		 local base_obj = $.baseobject
		 local num_faces = polyop.getNumFaces base_obj
		 for f = 1 to num_faces do
		 (
			  local num_face_verts = polyop.getFaceDeg base_obj f
			  if num_face_verts != 4 do face_selection[f] = true
		 )--end f loop

		 polyop.setFaceSelection base_obj face_selection
		 max modify mode
		 modPanel.setCurrentObject base_obj
		 subobjectlevel = 4
	)--end on execute

)--end script 

