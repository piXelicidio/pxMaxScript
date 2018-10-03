-- Pro Symmetry Tools 
-- Denys Almaral

-- Iplement similar funcionality of 3ds Max symmetry tool and extends with useful advanced features..

--future macro
(


	struct TVertInfo  ( RightSide, LinkedTo, PairedWith, vPos ) --[ RightSide:boolean, LinkedTo, PairedWith, vertPos ]
	local  Tolerance = 0.005
	local MySelection = #{}
	local MirrorRightToLeft  = true
	
	local DialogWidth = 180
	local maxBWidth = DialogWidth - 20

	rollout roll_proSymmetryTools "Pro Symmetry Tools"
	(
		progressbar pbar value:100 height:8 color:[200,0,0]
		pickbutton btnPickObject " Pick Object " toolTip:"Pick Editable Poly to base symmetry on" width:maxBWidth height:30
		checkbox chkEdgeAnalysis "Edge Analysis" checked:true tooltip:"Analyze edge connections to find symmetry. Slow for high poly counts."  align:#left
		radioButtons radioAxis "" labels:#("X","Y","Z" ) default:1 tooltip:"Axis"
		spinner spnTolerance "Tolerance:" range:[0,100,0.005] type:#float scale:0.001 align:#left 
		
		group "Make Symmetrical"
		(
			button btnPosToNeg "+ to -"  height:26 width:70 align:#left
			button btnNegToPos "- to +" height:26 width:70  offset:[0,-31] align:#right
			button btnFlip " Flip Symmetry " width:maxBWidth
		)
		
		group "Vertex operations"
		(
			button btnCopySel "Copy Selected" width:maxBWidth
			button btnPaste "Paste" width:maxBWidth
			button btnPasteOpposite "Paste Opposite" width:maxBWidth
		)
		
		group "Edit Geometry Symmetrical"
		(
			
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
		 --- FOUND IF: Exist only one wieh same connections.
		 --- Update connections.
		 UNTIL CAN'T find more new pairs   	*/
		function FindPairs EPolyObj  = 
		(
			local N = polyop.getNumVerts EPolyObj 
			local Result = #{}
			Result.count = N	
			Result = - Result
			
			UnPairedTag = N+99
			
			local VertsInfo = #() --array of TVertInfo
			VertsInfo.count = N
			
			--initializing vertInfo
			for i=1 to N do in coordsys local
			(
				local v1 = polyop.getVert EPolyObj i
				VertsInfo[i] = TVertInfo undefined undefined undefined v1
				VertsInfo[i].RightSide = ( v1.x >= 0 )
				
				--Vertices on the Symmetry AXE paired with themselves. 
				If 	abs(v1.x) <= Tolerance then 
				(	
					VertsInfo[i].PairedWith = i	
					Result[i]=false
				)
				
				--Links
				--FindingEdge connections with other vertices
				local MyEdges = polyop.getEdgesUsingVert EPolyObj  i
				VertsInfo[i].Linkedto = #{}	
				for k in MyEdges do
				(
					VertsInfo[i].Linkedto  = VertsInfo[i].Linkedto  + (polyop.getVertsUsingEdge EPolyObj k )			
				)		
				VertsInfo[i].Linkedto =  VertsInfo[i].Linkedto - #{i}
			)
			
			for i=1 to N-1 do in coordsys local
			(
				local v1 = polyop.getVert EPolyObj i			
				
				
				--Finding first pairs by position	
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
			)
			
			-- Find pairs by links -------------------------- the cool start here --------------
			
			
			
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
													print ("Candidate! " + (MyCandidate as string) )
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
								--Mirroring vertice
								if MirrorRightToLeft then
								(
									local newPos = VertsInfo[i].vPos 
									newPos.x = -newPos.x
									polyop.setVert  EPolyObj #(MyCandidate) newPos
								) else
								(
								)
								print ("Pair:" + (i as string) + "-" + (MyCandidate as string) ) 
							)
							
						)
					)
				)--For I end
				print ("Found New Pairs: " + (FoundNewPairs	as string))
			)	while FoundNewPairs!=0
				
				
			Result
			$.selectedVerts = FindPairs $
		) -- FindPairs funciton END
	
		on btnPickObject picked obj do
		(
			if (classof obj)==Editable_poly then 
			(
				btnPickObject.text = obj.name	
				pbar.color = [0,255,0]
			) else messageBox "Pick an Editable Poly object" title:"Pro Symmetry Tools"
		)
		
	)
	
	--rf = newRolloutFloater "Pro Symmetry Tools" 120 420
	--addrollout roll_proSymmetryTools rf
	createDialog roll_proSymmetryTools DialogWidth 500

)

