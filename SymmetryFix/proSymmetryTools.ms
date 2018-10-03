-- Pro Symmetry Tools 
-- Denys Almaral

-- Iplement similar funcionality of 3ds Max symmetry tool and extends with useful advanced features..

--future macro
(


	struct TVertInfo  ( RightSide, LinkedTo, PairedWith, vPos ) --[ RightSide:boolean, LinkedTo, PairedWith, vertPos ]
	local  Tolerance = 0.005
	local MySelection = #{}
	local MirrorRightToLeft  = true
	
	local baseObject = undefined
	local VertsInfo = #() --array of TVertInfo
	
	local DialogWidth = 180
	local maxBWidth = DialogWidth - 20

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
			)
			print "Done."
			
			-- Find pairs by links -------------------------- the cool start here -------------- Edge Connections Analysis
			print "Finding pairs by edge connections..."
			if chkEdgeAnalysis.checked==true then 
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
								--Mirroring vertice
								--if MirrorRightToLeft then
								--(
								--	local newPos = VertsInfo[i].vPos 
								--	newPos.x = -newPos.x
								--	polyop.setVert  EPolyObj #(MyCandidate) newPos
								--)
								--print ("Pair:" + (i as string) + "-" + (MyCandidate as string) ) 
							)--if MyCandidateNum == 1
							
						)--if VertsInfo[i].PairedWith==undefined
					)--if VertsInfo[i].RightSide
				)--For I end
				--print ("Found New Pairs: " + (FoundNewPairs	as string))
			)	while FoundNewPairs!=0
				
			print "Done."
			proBar.color = [0,255,0]
			Result
			EPolyObj.selectedVerts = Result
		) -- FindPairs funciton END
	
		-- Mirroring vertices positions
		-- PosToNeg Boolean; Axis String "x"|"y"|"z"
		function MakeSymmetrical PosToNeg: Axis: Flip: =			
		(
			if PosToNeg == unsupplied then PosToNeg = true
			if Axis == unsupplied then Axis = "x"
			if Flip == unsupplied then Flip = false
			-- copy Positive positions to Negative on selected object
			if (classof $)==Editable_Poly then
			(
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
							
							if Axis=="y" then (myPos.y = - myPos.y;  hisPos.y = - hisPos.y ) else	
								if Axis=="z" then (myPos.z = - myPos.z; hisPos.z = -hisPos.z ) else
									if Axis=="x" then ( myPos.x = - myPos.x; hisPos.x = - hisPos.x)
										
							if (PosToNeg or Flip) then polyOp.setVert $ him myPos 
							if ((not PosToNeg) or Flip) then polyOp.setVert $ i hisPos							
							
						)						
					)
				)
			)
		)
		
		on btnPickObject picked obj do
		(
			if (classof obj)==Editable_poly then 
			(
				btnPickObject.text = obj.name	
				probar.color = [0,255,0]
				baseObject = obj
				FindPairs baseObject
			) else messageBox "Pick an Editable Poly object" title:"Pro Symmetry Tools"
		)
		
		
		
		on btnPosToNeg pressed do
		(
			MakeSymmetrical PosToNeg:True Axis:"x"
		)
		
		on btnNegToPos pressed do
		(
			MakeSymmetrical PosToNeg:False Axis:"x"
		)
		
		on btnFlip pressed do
		(
			MakeSymmetrical Flip:true Axis:"x"
		)
		
	)
	
	--rf = newRolloutFloater "Pro Symmetry Tools" 120 420
	--addrollout roll_proSymmetryTools rf
	createDialog roll_proSymmetryTools DialogWidth 500

)

