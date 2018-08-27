	(
		 local vert_selection = #{}
		 local base_obj = $.baseobject
		 local num_verts = polyop.getNumVerts base_obj
		 local currentVert = #()

		 for f = 1 to num_verts do
		 (
			currentVert[1] = f 
			local LinkedFaces = (polyop.getFacesUsingVert base_obj currentVert)			
			if ((LinkedFaces as array).count==2) do vert_selection[f] = true
		 )--end f loop

		 polyop.setVertSelection base_obj Vert_selection
		 max modify mode
		 modPanel.setCurrentObject base_obj
		 subobjectlevel = 1
	)--end on execute