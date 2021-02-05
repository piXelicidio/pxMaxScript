--pX Step Cap--
--Cap a hole by step, reducing polycount using triangles.

macroScript StepCap buttonText:"Step Cap" category:"pX Tools" tooltip:"Cap holes by step"
(
	
	
	--data inputs
	local theObj = $
	local selected = undefined
	local t_start = 0
	
	---------------------------------------- script starts preparation ------------------------------
	
	if theObj != undefined then
	(
		if (classof theObj) == Editable_poly then
		(
			selected = polyOp.getEdgeSelection theObj
			if (selected as array).count < 3 then
			(
				selected = undefined
			)
		) else
		(
			print "StepCap: Need Editable_poly selected, with border hole selected."
		)
	) else
	(
		print "StepCap: Select Editable_poly, then select border hole."
	)
		
	
	local vert_seq = #()	
	local verts_pos = #()
	--calculated
	local center = [0,0,0]
	local ave_len = 0	
	local ave_dist2center = 0
	--estimated
	local num_steps = 1
	local step_len = 1.0
	
	--
	local normal_bias = false
	
	-- STRUCTS
	struct shared_pos (vert_list, pos, dist2next, created_vert)	
	
	---------------------------------------------------- FUNCTIONS ------------------------------------------------------
	
	function reverse_if_needed sample_edge &curr_sequence =
	(
		local face = ((polyOp.getFacesUsingEdge theObj sample_edge) as array)[1]
		local fverts = polyOp.getFaceVerts theObj face
		append fverts fverts[1]			
		local sv1 = curr_sequence[1]
		local sv2 = curr_sequence[2]
		for i=1 to fverts.count-1 do
		(
			if (fverts[i] == sv1) and (fverts[i+1] == sv2) then
			(
				--on the same order, then need reverse!					
				last = curr_sequence.count
				for j = 1 to (last / 2) do
				(
					swap curr_sequence[j] curr_sequence[ last - j + 1] 
				)
				
				exit
			)
		)			
	)
	
	function CheckLoop edgeSel = 
	(
		if edgeSel == undefined then
		(
			return undefined
		)
		local pairs = #()
		for es in edgeSel do 
		(
			append pairs ((polyOp.getVertsUsingEdge theObj es) as array )
		)			
		
		local sequence = #()
		join sequence pairs[1]			
		deleteItem pairs 1
		
		--find conections
		local count = 0
		do 
		(
			local last = sequence[ sequence.count]
			local found = 0
			local found_where = #()
			for i=1 to pairs.count do
			(
				if (pairs[i][1] == last) or (pairs[i][2] == last) then
				(
					found = found + 1
					append found_where i
					if pairs[i][2] == last then 
					( --swap
						swap pairs[i][1] pairs[i][2]
					)
				)	
			)
			
			if found == 1 then
			(-- everthing is fine
				append sequence pairs[ found_where[1] ][2]
				deleteItem pairs found_where[1]
			) else
			(				
				if found > 1 then 
				(
					print "StepCap: Not a loop. Many conections."
				) else
				(
					--found == 0
					print "StepCap: Connection not found"
				)
				return undefined
			)
			count += 1
		) while ((pairs.count > 0) and (found == 1))
		
		if sequence[1] != sequence[ sequence.count ] then
		(
			print "Step: The loop is not closed"
			return undefined
		)
		
		--need reverse?			
		reverse_if_needed ((edgeSel as array)[1]) &sequence
		
		--return			
		(sequence)
	)
	
	function all_vert_pos curr_sequence = 
	(
		local vs = #()
		for i = 1 to  curr_sequence.count do
		(
			vs[i] = (polyOp.getVert theObj curr_sequence[i])
		)
		--return
		(vs)
	)
	
	function calc_stats = (
		local center_sum = [0,0,0]
		local total_len = 0
		for i=1 to verts_pos.count - 1 do
		(
			center_sum = center_sum + verts_pos[i]
			total_len = total_len + (distance verts_pos[i] verts_pos[i+1])			
		)
		center = center_sum / (verts_pos.count - 1.0) 
		ave_len = total_len / (verts_pos.count - 1.0) 
		--print center
		--print ave_len
		total_len = 0
		for i=1 to verts_pos.count - 1 do
		(			
			total_len = total_len + (distance center verts_pos[i])			
		)
		ave_dist2center = total_len / (verts_pos.count - 1.0)
		--print ave_dist2center
		return ok
	)
	
	function build_strip verts new_posis =
	(--POLYGONS BUILDING
		--new verts creation:
		for i =1 to new_posis.count-1 do
		(
			local idx  = polyOp.createVert theObj new_posis[i].pos
			new_posis[i].created_vert = idx
		)
		
		function find_bro posis v from_idx = 
		(
			local found = 0	
			if from_idx<1 then from_idx = 1
			for i = from_idx to posis.count-1 do
			(
				local j = findItem posis[i].vert_list v
				if j != 0 then 
				(
					found = i					
					exit
				)
			)
			if found == 0 then
			(
				print "StepCap: ERROR: something bad, vert not found"
				break()
			)
			--return
			(found)
		)
		
		--Finding the corresponding new vertices to complete a polygon (quad, or triangle)		
		local last_idx = 1
		local poly = #()
		for i = 1 to verts.count-1 do
		(			
			poly[1] = verts[i]
			poly[2] = verts[i+1]
			--firt my two or one brothers
			local p3i = find_bro new_posis poly[2] last_idx
			local p4i = find_bro new_posis poly[1] last_idx
			--format "p3i % - p4i %\n" p3i p4i
			if i < (verts.count-2) then last_idx = amin p3i p4i else last_idx = 1
			poly[3] = new_posis[ p3i  ].created_vert
			poly[4] = new_posis[ p4i ].created_vert
			--if the last two are the same, remove last
			if poly[3] == poly[4] then 
			(
				poly.count = 3
			)
			polyOp.createPolygon theObj poly
		)
	)
	
	function normal_effect curr_dir vert_idx curr_step =
	(
		--Average normal of faces using this vertex
		local fs = (polyop.getFacesUsingVert theObj vert_idx) as array
		local ave_normal = [0,0,0]
		for f in fs do 
		(
			ave_normal = ave_normal + (polyop.getFaceNormal theObj f)
		)
		ave_normal =  (ave_normal / fs.count) --no need for normalize yet
		local temp = cross curr_dir ave_normal
		local surface_dir = normalize (cross ave_normal temp)
		local step_len = length curr_dir
		curr_dir = normalize curr_dir
		local final_dir = (surface_dir * (curr_step*1.0)) + curr_dir
		final_dir = (normalize final_dir) * step_len
		--return
		(final_dir)
	)
	
	------------------------------- THE EXTRUDE-IN ALGORITHM -------------------------------------------------------	
	-----------------------------------------------------------------------------------------------------------------------------
	function extrude_in verts verts_pos steps reduce:0 = 
	(
		--Toward center verts extrussion 		
		local new_posis = #() -- #( shared_pos < vert_list = #(idx1, idx2...), pos = [x,y,z] >  ), ...
		new_posis[verts.count] = undefined
		for i=1 to verts.count-1 do
		(			
			local to_center =  (center - verts_pos[i])  *  (1.0/steps )
			if normal_bias then
			(
				to_center = normal_effect to_center verts[i] steps
			)
			
			to_center = verts_pos[i] +  to_center
			new_posis[i] = (shared_pos #(verts[i])  to_center )	
			
			--precarculating segment lengths
			if i>1 then
			(
				new_posis[i-1].dist2next = distance new_posis[i-1].pos new_posis[i].pos
			)
		)		
		new_posis[verts.count] = new_posis[1]  --close loop
		new_posis[verts.count-1].dist2next = distance new_posis[verts.count-1].pos new_posis[1].pos
		
				
		--verts reduccion
		if reduce > verts.count - 2 then
		(
			reduce = verts.count - 2
		)
		while reduce>0 do
		(
			local min_dist = new_posis[1].dist2next
			local min_segm = 1
			
			for i=1 to new_posis.count-1 do
			(
				
				local dist = new_posis[i].dist2next				
				if dist<min_dist then
				(
					min_dist = dist
					min_segm = i
				)
			)			
			--print ("min segment " + (min_segm as string) + " dist:" + (min_dist as string))
			
				
			--collapsing smaller segment
			join new_posis[min_segm].vert_list new_posis[min_segm + 1 ].vert_list --joining lists
			new_posis[min_segm].pos = (new_posis[min_segm].pos + new_posis[min_segm + 1 ].pos) * 0.5 --averaging verts			
			deleteItem new_posis (min_segm+1)
				
			if min_segm == new_posis.count then
			(	--was the tail! re-close the loop
				new_posis[1] = new_posis[ min_segm ]
			)		
			
 			--- update dist2next of affected vertices
			for i = (min_segm - 1) to min_segm do
			(
				local i1 = i
				local i2 = i + 1
				if i == 0 then i1 = new_posis.count - 1
				if i == new_posis.count then i2 = 2
				
				new_posis[i1].dist2next = distance new_posis[i1].pos new_posis[i2].pos
			) 
				
			reduce = reduce - 1
		)

		
		--print new_posis		
		build_strip verts new_posis
		
		--resulting vert sequence:
		local result = #()
		result[new_posis.count] = undefined
		for i = 1 to new_posis.count do
		(
			result[i] = new_posis[i].created_vert
		)
		--return
		(result)
	)
	
	function select_hole verts =
	(
		local edgesA = polyop.getEdgesUsingVert theObj #(verts[1])
		local edgesB = polyop.getEdgesUsingVert theObj #(verts[2])
		local myEdge = (edgesA * edgesB) as array
		if myEdge.count == 1 then
		(
			local myLoop = polyop.getBorderFromEdge theObj myEdge[1]
			polyop.setEdgeSelection theObj (myLoop as array)
		) 
		else		
		(
			print "StepCap ERROR: Edge not found, or too many"
		)
		
	)
	
	
	
	----------------------------------------- THE GOOD STUFF  ---------------------------
	t_start = timeStamp()
	
	vert_seq = checkLoop selected
	if vert_seq != undefined then
	(
		if vert_seq.count <= 5 then 
		( -- just close it if it's a quad or triangle
			deleteItem vert_seq vert_seq.count
			polyOp.createPolygon theObj vert_seq
			update theObj
		) 
		else
		(
			verts_pos = all_vert_pos vert_seq
			
			--calc values for: center, average edge len, average distance to center
			calc_stats() 
			num_steps = ((ave_dist2center / ave_len ) as integer) + 1
			if num_steps < 2 then num_steps = 2
			print ("StepCap: Estimated steps: "+ (num_steps as string))
			step_len = ave_dist2center / num_steps
				
			-- how many to reduce?
			local Num_edges = vert_seq.count - 1
			local to_reduce = (Num_edges-4) --leve 4 for the ending quad.
			to_reduce = (to_reduce / ( (num_steps - 1) as float))
			to_reduce = (to_reduce + 0.5 ) as integer			
			print ("StepCap: Reducing polys "+ (to_reduce as string))
			------------------------------------------------------------------------------------------------	
			vert_seq = extrude_in vert_seq verts_pos num_steps reduce:to_reduce
			------------------------------------------------------------------------------------------------	
			update theObj
				
			--progressive capper, step by step by the user, last loop created get selected			
			select_hole vert_seq
				
			--finished
			format "StepCap: Elapsed time: %\n" (timeStamp() - t_start)
		)
	)

)

