-- Pro Symmetry Tools 
-- Denys Almaral

-- Iplement similar funcionality of 3ds Max symmetry tool and extends with useful advanced features..

--TODO:
-- relative symmetrical vertex move; 

--future macro
(


	struct TVertInfo  ( RightSide, LinkedTo, PairedWith, vPos ) --[ RightSide:boolean, LinkedTo, PairedWith, vertPos ]
	local  Tolerance = 0.005
	local MySelection = #{}
	local MirrorRightToLeft  = true
	
	local baseObject = undefined
	local VertsInfo = #() --array of TVertInfo
	local ClipboardIndexes = #() --array of indices;
	local ClipboardVerts = #() --array of verts
	
	local DialogWidth = 200
	local DialogHeight = 600
	local maxBWidth = DialogWidth - 30

	rollout roll_proSymmetryTools "Pro Symmetry Tools"
	(
		progressbar proBar value:100 height:8 color:[200,0,0]
		pickbutton btnPickObject " Pick Object " toolTip:"Pick Editable Poly to base symmetry on" width:maxBWidth height:30
		checkbox chkEdgeAnalysis "Edge Analysis" checked:true tooltip:"Analyze edge connections to find symmetry. Slow for high poly counts."  align:#left
		radioButtons radioAxis "" labels:#("X" ) default:1 tooltip:"Axis"
		spinner spnTolerance "Tolerance:" range:[0,100,0.005] type:#float scale:0.001 align:#left 
		
		group "Make Symmetrical"
		(
			button btnPosToNeg "+ to -"  height:26 width:70 align:#left
			button btnNegToPos "- to +" height:26 width:70  offset:[0,-31] align:#right
			checkbox chkRelative "Relative translation" checked:false tooltip:"Keeps the original position mirroring the offset translation"
			button btnFlip " Flip Symmetry " width:maxBWidth 
			button btnRestore "Restore Original" width:maxBWidth
		)
		
		group "Vertex operations"
		(
			button btnCopySel "Copy Selected" width:maxBWidth
			button btnPaste "Paste" width:maxBWidth
			button btnPasteOpposite "Paste Opposite" width:maxBWidth
		)		

		/*----------  Advanced FindPairs Algorithm  -----------------		 
		 
		 - Find symmetrical pairs of vertices.
		 - Consider x=0 vertices as paired.
		 - go for every non-paired vertices and link
		 -- Store all edge conextions for each non-paired vertices.
		 REPEAT PASSES
		 - go for each non-paired Right-Side vertice
		 -- Check its edge conections.
		 -- Find a Left-Side vertice with same connections. 
		 --- FOUND IF: Exist only one with same connections.
		 --- Update connections.
		 UNTIL CAN'T find more new pairs   	*/
		function FindPairs EPolyObj  = 
		(
			local N = polyop.getNumVerts EPolyObj 
			local Result = #{} -- Result is a bitArray, will tell non paired (=true) vertices at the end 
			Result.count = N	  --with N elements			
			Result = - Result  -- inverting makes all elements true.
			
			local UnPairedTag = N+99
			
			VertsInfo.count = N
			
			--initializing vertInfo
			for i=1 to N do in coordsys local
			(
				local v1 = polyop.getVert EPolyObj i
				VertsInfo[i] = TVertInfo undefined undefined undefined v1
				VertsInfo[i].RightSide = ( v1.x >= 0 )  -- RightSide = positive
				
				--Vertices on the "center" Symmetry AXE paired with themselves. 
				If 	abs(v1.x) <= Tolerance then 
				(	
					VertsInfo[i].PairedWith = i	
					Result[i]=false
				)
				
				--Links
				--Find the list of vertices connected via edge, store in LinkedTo bitarray
				local MyEdges = polyop.getEdgesUsingVert EPolyObj  i
				VertsInfo[i].Linkedto = #{}	
				for k in MyEdges do
				(
					VertsInfo[i].Linkedto  = VertsInfo[i].Linkedto  + (polyop.getVertsUsingEdge EPolyObj k )			
				)		
				--remove self
				VertsInfo[i].Linkedto =  VertsInfo[i].Linkedto - #{i}
			)
			
			
			--Finding Pairs by position------------------------------- The standard easy way				
			print "Finding symmetrical pairs..."
			proBar.color = [0,255,255]
			for i=1 to N-1 do in coordsys local
			(
				local v1 = polyop.getVert EPolyObj i							
				
				for j=(i+1) to N do
				(			
					v2 = polyop.getVert EPolyObj j
					v2.x = -v2.x
					d = (distance v1 v2)
					
					if d<=Tolerance then
					(
						VertsInfo[i].PairedWith = j
						VertsInfo[j].PairedWith = i	
						Result[i]=false
						Result[j]=false
					)	
				)
				proBar.value = (i * 100) / N
			)
			print "Done."
			
			-- Find pairs by links -------------------------- the cool start here -------------- Edge Connections Analysis
			print "Finding pairs by edge connections..."
			--proBar.value = 0
			proBar.color = [255, 255, 0]
			local NewLinksCount = 0
			local UnlinkedPairs = ((Result as array ).count / 2) +1
			if (chkEdgeAnalysis.checked==true) and (Result.count!= 0) then 
			do
			(
				Local FoundNewPairs=0
				
				for i=1 to N do in coordsys local
				(		
					
					if VertsInfo[i].RightSide then
					(
						if VertsInfo[i].PairedWith==undefined then
						(
							Result[i] = true
							local MyCandidate = 0
							local MyCandidateNum = 0
							
							for j=1 to N-1 do
							(
								if i!=j then 
								(							
									local RSymLinks = #{}
									local RUnpairedLinks = 0
									local LSymLinks = #{}
									local LUnpairedLinks = 0
									--Remap the links using paired Vertice Numbers. 
									--Right
									for k in VertsInfo[i].LinkedTo do
									(
										if VertsInfo[k].PairedWith==undefined then
										(
											RUnpairedLinks +=  1
										) else 
										(
											if VertsInfo[k].RightSide then 
											(
												RSymLinks = RSymLinks + #{ k }
											) else
											(
												RSymLinks = RSymLinks + #{ VertsInfo[k].PairedWith }
											)
										)					
									)
									--left
									for k in VertsInfo[j].LinkedTo do
									(
										if VertsInfo[k].PairedWith==undefined then
										(
											LUnpairedLinks += 1
										) else 
										(
											if VertsInfo[k].RightSide then 
											(
												LSymLinks = LSymLinks + #{ k }
											) else
											(
												LSymLinks = LSymLinks + #{ VertsInfo[k].PairedWith } 
											)
										)					
									)
									
									-- And now the moment of "almost" truth!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
									-- The left vert qualify for pairing???
									
									--Empty links sets, cant prove nothing 
									if (not RSymLInks.isEmpty) and (not RSymLinks.isEmpty )then 
									(
										-- Testing if two SETS are EQUAL:
										if (RSymLinks-LSymLinks).isEmpty and (LSymLinks-RSymLinks).IsEmpty  then
										(
											--but wat about the Unpaired links?
											if RUnpairedLinks == LUnpairedLinks then
											(
												--this is a good candidate!
												--lets see if  there not already one before...
												if MyCandidate==0 then 
												(
													--Nice this is the first (hope only)
													MyCandidate=j 
													MyCandidateNum+= 1
													--print ("Candidate! " + (MyCandidate as string) )
												) else
												(
													--no need for more searching there are duplicated "ideal" conditions
													--but instead of exiting the loops, lets just count the candidates
													MyCandidateNum += 1
												)
											)
										)
									)
								
								)
							)--For J end
							
							--if One and only One then yeah
							if MyCandidateNum == 1 then
							(
								--We can pair vert I with vert MyCandidate
								VertsInfo[i].PairedWith = MyCandidate
								VertsInfo[MyCandidate].PairedWith = i
								FoundNewPairs += 1 
								Result[i]=false
								Result[MyCandidate]=false
								NewLinksCount += 1
								--updating progressbar
								proBar.value = (100 * NewLinkscount) / UnlinkedPairs	
									
							)--if MyCandidateNum == 1
							
						)--if VertsInfo[i].PairedWith==undefined
					)--if VertsInfo[i].RightSide
				)--For I end
				--print ("Found New Pairs: " + (FoundNewPairs	as string))
			)	while FoundNewPairs!=0
				
			print "Done."
			print NewLinkscount
			print UnlinkedPairs
			proBar.value = 100;
			proBar.color = [0,255,0]
			
			EPolyObj.selectedVerts = Result
			Result
		) -- FindPairs funciton END
	
		-- Mirroring vertices positions
		-- PosToNeg Boolean; Axis String "x"|"y"|"z"
		function MakeSymmetrical PosToNeg: Axis: Flip: =			
		(
			if PosToNeg == unsupplied then PosToNeg = true
			if Axis == unsupplied then Axis = "x"
			if Flip == unsupplied then Flip = false
				
			-- copy Positive positions to Negative on selected object
			if ((classof $)==Editable_Poly) then
			(
				-- TODO: Find Solution. Currently limited to Editable_Poly objects
				-- there is a problem with Edit_Poly modifier, I can't set vertices: see: https://forums.cgsociety.org/t/help-me-maxscript-and-editpoly/1026305/7 
				for i=1 to VertsInfo.count do  in coordsys local
				(
					if VertsInfo[i].RightSide then 
					(
						--is positive copy to paired
						local him = VertsInfo[i].PairedWith
						if him != undefined then
						(
							local myPos = polyOp.getvert $ i	
							local hisPos = polyOp.getvert $ him
																								
							if chkRelative.checked==false then
							(
								--mirror positions
								myPos.x = - myPos.x 
								hisPos.x = - hisPos.x
								--set to my pair
								if (PosToNeg or Flip) then polyOp.setVert $ him myPos 
								if ((not PosToNeg) or Flip) then polyOp.setVert $ i hisPos							
							) else
							(
								--calc offset translations taking oriignal vertices as origin
								local myOffset = myPos - VertsInfo[i].vPos
								local hisOffset = hisPos - VertsInfo[him].vPos
								--mirror the offset translation
								myOffset.x = - myOffset.x
								hisOffset.x = - hisOffset.x
								--apply mirrored  offset on opposite 
								if (PosToNeg or Flip) then polyOp.setVert $ him (VertsInfo[him].vPos + myOffset)
								if ((not PosToNeg) or Flip) then polyOp.setVert $ i (VertsInfo[i].vPos + hisOffset)
							)
							
						)						
					)
				)
			)
		)
		
		on btnPickObject picked obj do
		(
			if (classof obj)==Editable_poly then 
			(				
				baseObject = obj
				FindPairs baseObject
				btnPickObject.text = obj.name	
			) else messageBox "Pick an Editable Poly object" title:"Pro Symmetry Tools"
		)
		
		
		
		on btnPosToNeg pressed do
		(
			undo label:"+ to - symmetry" on
			(
				MakeSymmetrical PosToNeg:True Axis:"x"
			)
		)
		
		on btnNegToPos pressed do
		(
			undo label:"- to + symmetry" on
			(
			MakeSymmetrical PosToNeg:False Axis:"x"
			)
		)
		
		on btnFlip pressed do
		(
			undo label:"Symmetry Flip" on
			(
			MakeSymmetrical Flip:true Axis:"x"
			)
		)
		
		on btnCopySel pressed do
		(
			if ((classof $)==Editable_poly) then
			(
				ClipboardIndexes = (polyop.getVertSelection $) as array
				ClipboardVerts.count = ClipboardIndexes.count
				for i=1 to ClipboardIndexes.count do in coordsys local
				(
					ClipboardVerts[i] = (polyop.getVert $ ClipboardIndexes[i])
				)
				btnPaste.text = ("Paste (" + (ClipboardVerts.count as string) + ") ")
			)
		)
		
		on btnPaste pressed do in coordsys local
		(
			undo label:"Paste Verts" on
			(
			polyOp.setVert $ ClipboardIndexes ClipboardVerts
			)
		)
		
		on btnPasteOpposite pressed do in coordsys local
		(
			undo label:"Paste Opposite" on
			(
				for i=1 to ClipboardIndexes.count do
				(
					local maxverts = $.numVerts
					if ClipboardIndexes[i]<=maxverts then
					(
						local opposite = VertsInfo[ ClipboardIndexes[i] ].pairedWith
						if opposite != undefined then
						(
							if opposite <= maxverts then
							(
								local opvert = copy ClipboardVerts[i] 
								opvert.x = -opvert.x
								polyOp.setVert $ opposite opvert
							)
						)
					)
				)
			)
		)
		
		
	)--rollout roll_proSymmetryTools ---------
	
		
	rollout roll_EditGeometry "Edit Geometry Symmetrical" ----------------------------------
	(
		checkbox chkEnabledSym "Enabled Sym. Op." checked:true tooltip:"When disabled the Edits are not mirrored."
		button btnDelete "Delete" 
		button btnConnect "Connect"
		button btn3 "btn1"
		button btn4 "btn1"
		button btn5 "btn1"
		button btn6 "btn1"		
		
		-- VertsInfo is broken, there is a New Verts Order, fix it!
		function DetectNewVertsOrder OldVerts NewVerts =
		(
			
			local NewIndex = #()
			local NotFound = #()
			local found = false
			NewIndex.count = OldVerts.count
			-- detecting by position where are the old vertices
			for o=1 to OldVerts.count do
			(
				found = false
				for n=1 to NewVerts.count do
				(
					if (distance OldVerts[o] NewVerts[n]) <= Tolerance then
					(
						-- found my new me
						NewIndex[o] = n
						found = true
					)
				)
				if not found then append NotFound o
			)
			
			--	Fix VertsInfo
			local newVertsInfo = #()
			newVertsInfo.count = NewVerts.count
			print oldVerts.count
			print NewVerts.count			
			for o = 1 to NewIndex.count do
			(
				--moving to new location
				local ni = NewIndex[o]
				if ni != undefined then
				(
					newVertsInfo[ni] = vertsInfo[o]
					--Updating pairs				
					local newPair = VertsInfo[o].pairedWith
					if newPair!= undefined then
					(
						if newPair <= NewIndex.count then newPair = NewIndex[ newPair ] else newPair = undefined
					)
					newVertsInfo[ni].pairedWith = newPair
					--Updating linkedTo???
					-- newVertsInfo[o].linkedTo =  --linkedTo is a bitArray, its info gets obsolete now, update it IF NEEDED.
				
				)
			)
			--replace old with new
			vertsInfo = newVertsInfo
		)
			
		-- get the mirrored vertex selection; vertSel is bitArray, return bitArray
		function mirrorVertSel  vertSel =
		(
			local result = #{}
			vertlist = vertSel as array
			for i=1 to vertlist.count do
			(
				local pair = VertsInfo[ vertlist[i] ].pairedWith
				if pair != undefined then
				(
					append result pair
				)
			)
			result
		)
		
		--get Edge formed by Verts (array of two indices), return Edge Num or Undefined
		function getEdgeByVerts epoly Verts =
		(
			local edges1 = polyOp.getEdgesUsingVert epoly #(Verts[1])
			local edges2 = polyOp.getEdgesUsingVert epoly #(Verts[2])
			local Result = edges1 * edges2			
			if Result.isEmpty then Result = undefined else
			(
				Result = Result as array
				if Result.count == 1 then Result = Result[1] else Result = undefined
			)
			Result
		)
		
		--check if edges are part of the same face, edges:Array ,return boolean,
		function AreEdgesOnSameFace EPoly Edges =
		(
			--get all faces with relationship to the given edges
			local bitEdges = Edges as bitarray
			local faces = polyop.getFacesUsingEdge EPoly Edges 
			faces = faces as array
			local result = false
            print faces
			for i=1 to faces.count do
		 	(
				-- get each face edges
				local faceEdges =  polyOp.getFaceEdges EPoly faces[i]
				--check if one of the faces contains all the edges
				faceEdges = faceEdges as bitarray
				--check the intersection between sets
				faceEdges = faceEdges * bitEdges				
                -- if the intersection count is = to Edges count then is a match
				Result = (faceEdges as array).count == Edges.count
                if Result then exit
			)
			Result
		)
		
		on btnDelete pressed do undo on
		(
			if ( (classof $ ) == Editable_Poly) then
			(
				--Vertices?
				if SubObjectLevel == 1 then
				(
					local vertSel = polyOp.getVertSelection $
					local oldVerts = #()
					local newVerts = #()
					
					--saving old estate
					oldVerts.count = polyOp.getNumVerts $
					for i=1 to oldVerts.count do
					(
						oldVerts[i] = polyOp.getVert $ i
					)
					
					-- destructive operation
					if chkEnabledSym.checked then
					(
						local mirrSel = mirrorVertSel vertSel
						vertSel = vertSel + mirrSel
					)
					polyOp.deleteVerts $ vertSel
					
					-- restoring the order verts info
					newVerts.count = polyOp.getNumVerts $
					for i=1 to newVerts.count do
					(
						newVerts[i] = polyOp.getVert $ i
					)
					DetectNewVertsOrder OldVerts NewVerts
					
				)--end-if subobjectlevel 
			)
		)--on btnDelete
		
		on btnConnect pressed do in coordsys local undo on
		(
			if ( (classof $ ) == Editable_Poly) then
			(
				--Vertices?
				if SubObjectLevel == 1 then
				(
					local vertSel = polyOp.getVertSelection $					
					local verts = vertSel as array
					
					if verts.count == 2 then
					(
						polyOp.createEdge $ verts[1] verts[2]
						if chkEnabledSym.checked then
						(
							local mirrSel = mirrorVertSel vertSel						
							verts =mirrSel as array
							polyOp.createEdge $ verts[1] verts[2]
						)
						update $
					) else messageBox "Please, select 2 vertices."
					
				) else if SubObjectLevel == 2 then
				( 
					-- edges
					local edgeSel = polyOp.getEdgeSelection $
					local edges = edgeSel as array
					if edges.count == 2 then 
					(
						if AreEdgesOnSameFace $ edges then
						(			
							
							--  store the original verts of each edge
							local edgeVerts1 = polyop.getEdgeVerts $ edges[1]
							local edgeVerts2 = polyop.getEdgeVerts $ edges[2]
							
							-- divide the edges, connect the two new vertices
							local v1 = polyop.divideEdge $ edges[1] 0.5
							local v2 = polyop.divideEdge $ edges[2] 0.5
							local v3 = undefined
							local v4 = undefined
							polyOp.createEdge $ v1 v2
							
							-- find the Symmetrical EdgeVerts
							edgeVerts1[1] = VertsInfo[ edgeVerts1[1] ].pairedWith
							edgeVerts1[2] = VertsInfo[ edgeVerts1[2] ].pairedWith
							edgeVerts2[1] = VertsInfo[ edgeVerts2[1] ].pairedWith
							edgeVerts2[2] = VertsInfo[ edgeVerts2[2] ].pairedWith
							
							--if any of them are undefined end of story
							if (edgeVerts1[1] != undefined) and (edgeVerts1[2] != undefined) and
							   (edgeVerts2[1] != undefined) and (edgeVerts2[2] != undefined) then
							(
								--get the correspondant edges
								local edge1 = getEdgeByVerts $ edgeVerts1
								local edge2 = getEdgeByVerts $ edgeVerts2						
								if (edge1 != undefined) and (edge2 != undefined) then
								(
									v3 = polyop.divideEdge $ edge1 0.5
									v4 = polyop.divideEdge $ edge2 0.5
									polyop.createEdge $ v3 v4
								)
							)						  
							
							--TODO: update/add the new vertices to VertsInfo data
							-- because potato, we know the new vertices are added to the end, so expand array
							VertsInfo.count = polyOp.getNumVerts $
							VertsInfo[ v1 ] = TVertInfo undefined undefined undefined undefined
							VertsInfo[ v2 ] = TVertInfo undefined undefined undefined undefined
							local v1Pos = polyOp.getVert $ v1
							local v2Pos = polyOp.getVert $ v2
							VertsInfo[v1].RightSide = (v1Pos.x >= 0)
							VertsInfo[v2].RightSide = (v2Pos.x >= 0)
							VertsInfo[v1].vPos = v1Pos
							VertsInfo[v2].vPos = v2Pos						
							if (v3 != undefined) and (v3 != undefined) then 
							(
								VertsInfo[ v3 ] = TVertInfo undefined undefined undefined undefined
								VertsInfo[ v4 ] = TVertInfo undefined undefined undefined undefined
								local v3Pos = polyOp.getVert $ v3
								local v4Pos = polyOp.getVert $ v4
								VertsInfo[ v3 ].RightSide = (v3Pos.x >= 0 );
								VertsInfo[ v4 ].RightSide = (V4Pos.x >= 0);
								VertsInfo[v3].vPos = v3Pos
								VertsInfo[v4].vPos = v4Pos
								-- pairing
								VertsInfo[v1].PairedWith = v3
								VertsInfo[v3].Pairedwith = v1
								VertsInfo[v2].Pairedwith = v4
								VertsInfo[v4].PairedWith = v2
							)
							
						) else messageBox "Please, select 2 edges on the same face."
					) else messageBox "Please, select 2 edges."
					
				)
			)			
		)--on btnConnect pressed
		
	)--rollout roll_EditGeometry ---end --
	
	rf = newRolloutFloater "Pro Symmetry Tools"  DialogWidth DialogHeight
	addrollout roll_proSymmetryTools rf
	addrollout roll_EditGeometry rf
	--createDialog roll_proSymmetryTools DialogWidth 500

)

