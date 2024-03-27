-- Pro Symmetry Tools 
-- Denys Almaral

-- Iplement similar funcionality of 3ds Max symmetry tool and extends with useful advanced features..

--TODO:
-- collapse vertices, weld
-- Symmetry attach! Powerful thingy (think about UV mapping)
-- extrude face, edge


--future macro
(


	local  Tolerance = 0.005
	local MySelection = #{}
	local MirrorRightToLeft  = true
	
	local baseObject = undefined
	local vertsInfo_count = 0;
	local vertsInfo_RightSide = #()
	local vertsInfo_LinkedTo = #()
	local vertsInfo_PairedWith = #()
	local vertsInfo_vPos = #()
	local ClipboardIndexes = #() --array of indices;
	local ClipboardVerts = #() --array of verts
	
	local DialogWidth = 200
	local DialogHeight = 600
	local maxBWidth = DialogWidth - 30
	--settings
	usingDllManager = true
    dllFuncs = undefined
    -- common functions			
	
	function SetVertsInfo_count count =
	(
		vertsInfo_RightSide.count = count
		vertsInfo_LinkedTo.count = count
		vertsInfo_PairedWith.count = count
		vertsInfo_vPos.count = count
		vertsInfo_count = count
	)
	
    function LoadDLL =
	(
		if (usingDllManager==false) or (dllManager==undefined) then
		(
			thisFile = getThisScriptFilename()
			dir = pathConfig.removePathLeaf thisFile 
			dllFile = pathConfig.appendPath dir @"dotnet\symmetry\symmetry.dll"
			Format "Loading assembly: %\n" dllFile
			dotNet.loadAssembly dllFile
			dllFuncs = dotNetClass "Symmetry.Functions"
			if dllFuncs==undefined then
			(
				print "Loading assembly failed"
			) else
			(
				print "Assembly loading success"
			)
			--print dllFuncs
		)
	)
	
    
    --get the mirrored vertecies, verts :array of vertices
    -- resulting order and count is not guarateed, some verts may not be found
    function mirrorVerts verts =
    (
        local result = #()
        for i=1 to verts.count do
        (
            local pair = vertsInfo_PairedWith[ verts[i] ]
            if pair != undefined then append result pair                
        )
        result
    )
    
    -- get the mirrored vertex selection; vertSel is bitArray, return bitArray
    function mirrorVertSel  vertSel =
    (
        local result = #{}
        local vertlist = vertSel as array
        result = mirrorVerts vertlist
        result as bitArray
    )
    
    
    
   --get Face formed by Verts (array of verts indices), return Face Num or Undefined
   -- if you provide not enough verts, result will return first face that include them all
    function getFaceByVerts epoly Verts =
    (
        local faces = ( polyOp.getFacesUsingVert epoly Verts ) as array
        local result = undefined
        local VertsSet = Verts as bitarray
        for i=1 to faces.count do
        (
            local faceVerts = (polyOp.getFaceVerts epoly faces[i]) as bitArray
            --coincidences
            local coincidences = faceVerts * (VertsSet)
            --all
            if  (coincidences as array).count == verts.count then
            (
                Result = Faces[i]
                exit
            )
            
        )
       Result
    )
    
    
    -- get the mirrored face selection; faceSel is bitArray;; return bitArray
    function mirrorFaceSel Epoly faceSel =
    (
        local result = #{}
        local faceList = faceSel as array
        for i=1 to faceList.count do
        (
            -- find pair face of faceList[i]
            local faceVerts = polyOp.getFaceVerts EPoly faceList[i]            
            -- get the mirrored vertices
           faceVerts = mirrorVerts faceVerts
           local mirroredFace = getFaceByVerts epoly faceVerts
           if mirroredFace != undefined then append result mirroredFAce 
        )
        result
    )   

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
                local newPair = vertsInfo_PairedWith[o]
                if newPair!= undefined then
                (
                    if newPair <= NewIndex.count then newPair = NewIndex[ newPair ] else newPair = undefined
                )
                newvertsInfo_PairedWith[ni] = newPair
                --Updating linkedTo???
                -- newvertsInfo_LinkedTo[o] =  --linkedTo is a bitArray, its info gets obsolete now, update it IF NEEDED.
            
            )
        )
        --replace old with new
        vertsInfo = newVertsInfo
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

    --rollouts
	rollout roll_proSymmetryTools "Pro Symmetry Tools"
	(
        group "Symmetry Data"
        (
            progressbar proBar value:100 height:8 color:[200,0,0]
            pickbutton btnPickObject " Pick Object " toolTip:"Pick Editable Poly to base symmetry on" width:maxBWidth height:30
            checkbox chkEdgeAnalysis "Edge Analysis" checked:true tooltip:"Analyze edge connections to find symmetry. Slow for high poly counts."  align:#left
            radioButtons radioAxis "" labels:#("X" ) default:1 tooltip:"Axis"
            spinner spnTolerance "Tolerance:" range:[0,100,0.005] type:#float scale:0.001 align:#left 
            button btnSwitchSides "Force Switch Sides" tooltip:"Tell selected vertices they are from the other side of the axis even if they are not."
        )
		
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
            local t1 = 0
			Result.count = N	  --with N elements			
			Result = - Result  -- inverting makes all elements true.
			
			local UnPairedTag = N+99
            
            local positiveVerts = #()
            local negativeVerts = #()
			
			SetVertsInfo_count N
			
			--initializing vertInfo
            tt = timeStamp()
			for i=1 to N do in coordsys local
			(
				local v1 = polyop.getVert EPolyObj i
				vertsInfo_vPos[i] = v1				
				if (v1.x >=0) then
				(
					vertsInfo_RightSide[i] = true  -- RightSide = positive
					append positiveVerts i 
				) else
				(
					vertsInfo_RightSide[i] = false
					append negativeVerts i					
				)
                
				
				--Vertices on the "center" Symmetry AXE paired with themselves. 
				If 	abs(v1.x) <= Tolerance then 
				(	
					vertsInfo_PairedWith[i] = i	
					Result[i]=false
				)
				
				--Links
				--Find the list of vertices connected via edge, store in LinkedTo bitarray
				local MyEdges = polyop.getEdgesUsingVert EPolyObj  i
				vertsInfo_LinkedTo[i] = #{}	
				for k in MyEdges do
				(
					vertsInfo_LinkedTo[i]  = vertsInfo_LinkedTo[i]  + (polyop.getVertsUsingEdge EPolyObj k )			
				)		
				--remove self
				vertsInfo_LinkedTo[i] =  vertsInfo_LinkedTo[i] - #{i}
			)
         
            Format "initializing: %ms\n" (timeStamp()-tt)
			
			
			--Finding Pairs by position------------------------------- The standard easy way				
			
            tt = timeStamp()
			proBar.color = [0,255,255]
			for i=1 to positiveVerts.count do in coordsys local
			(
				local v1 = vertsInfo_vPos[ positiveVerts[i] ]
				
				for j=1 to negativeVerts.count do
				(			
					local v2 = copy vertsInfo_vPos[ negativeVerts[j] ]
					v2.x = -v2.x
					local d = (distance v1 v2)
					
					if d<=Tolerance then
					(
						vertsInfo_PairedWith[ positiveVerts[i] ] = negativeVerts[j]
						vertsInfo_PairedWith[ negativeVerts[j] ] = positiveVerts[i] 
						Result[ positiveVerts[i] ]=false
						Result[ negativeVerts[j] ]=false
					)	

				)
				proBar.value = (i * 100) / N
			)
			format "Pairs by position: %ms\n" (timeStamp()-tt)
            
			
			-- Find pairs by links -------------------------- the cool start here -------------- Edge Connections Analysis            
            local ResultList = result as array
            -- ResultList cointatins the vertices that has not pairs yet.
			
            tt = timeStamp()
			--proBar.value = 0
			proBar.color = [255, 255, 0]
			local NewLinksCount = 0            
			local UnlinkedPairs = (ResultList.count / 2) +1            
			
			local Unpairedborder = #{}
			fn CheckIfBorder index border =
			(
				alink = 1
				nextToPaired = false
				linklist = vertsInfo_LinkedTo[index] as array
				len = linklist.count
				while ((not nextToPaired) and (alink <= len)) do
				(						
					nextToPaired = ( vertsInfo_PairedWith[ linkList[alink] ] != undefined)
					alink += 1
				)
				if nextToPaired then border[index] = true;
			)
							
			--Narrowing the search to just the border of interest
			for uIndex in ResultList do CheckIfBorder uIndex UnpairedBorder;				
            
			if (chkEdgeAnalysis.checked==true) and (ResultList.count != 0) then 
			do
			(
				Local FoundNewPairs=0


				ResultList = UnpairedBorder as array
				for r=1 to ResultList.count do in coordsys local                    
				(		
					local i = ResultList[r]
					--Side 1
					local RSymLinks = #{}
					local RUnpairedLinks = 0
					for k in vertsInfo_LinkedTo[i] do
					(
						if vertsInfo_PairedWith[k]==undefined then
						(
							RUnpairedLinks +=  1
						) else 
						(
							-- collect just the links indices for this side
							RSymLinks[k] = true
						)					
					)
					
						if (vertsInfo_PairedWith[i]==undefined) and (not RSymLinks.isEmpty) then
						(
							--Result[i] = true
							local MyCandidate = 0
							local MyCandidateNum = 0
							
							for rr=1 to ResultList.count do
							(                                
                                local j = ResultList[rr]  -- to avoid rename all J vars O.o
							 
														
								
								local LSymLinks = #{}
								local LUnpairedLinks = 0
								--Remap the links using paired Vertice Numbers. 
								
								--Side 2
								for k in vertsInfo_LinkedTo[j] do
								(
									if vertsInfo_PairedWith[k]==undefined then
									(
										LUnpairedLinks += 1
									) else 
									(
										-- for this side The pairs of the links
										LSymLinks[vertsInfo_PairedWith[k]]=true
									)					
								)
								
								-- And now the moment of "almost" truth!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
								-- The left vert qualify for pairing???
								
								--Empty links sets, cant prove nothing 
								if (not LSymLinks.isEmpty ) and								
									-- Testing if two SETS are EQUAL:
									(RSymLinks-LSymLinks).isEmpty and (LSymLinks-RSymLinks).IsEmpty  and									
										--but wat about the Unpaired links?
									(RUnpairedLinks == LUnpairedLinks) then
									(
										--this is a good candidate!
										--lets see if  there not already one before...
										if MyCandidate==0 then 
										(
											--Nice this is the first (hope only)
											MyCandidate=j 
											
											--print ("Candidate! " + (MyCandidate as string) )
										) 
										MyCandidateNum+= 1
									)
									
								
								
								
							)--For J end
							
							--if One and only One then yeah
							if MyCandidateNum == 1 then
							(
								--We can pair vert I with vert MyCandidate
								vertsInfo_PairedWith[i] = MyCandidate
								vertsInfo_PairedWith[MyCandidate] = i
                                -- Revise the Side of the vertices.
                                
								FoundNewPairs += 1 
								Result[i]=false
								Result[MyCandidate]=false                                
								NewLinksCount += 1
								--updating progressbar
								proBar.value = (100 * NewLinkscount) / UnlinkedPairs	
									
							)--if MyCandidateNum == 1
							
						)--if vertsInfo_PairedWith[i]==undefined
					
				)--For I end
                
                --Rebuilding the border, just close to the old border
				UnpariedBorder = #{}
				for idx in ResultList do
				(
					for uIndex in vertsInfo_LinkedTo[idx] do 
					(
						if (vertsInfo_PairedWith[uIndex] == undefined) then CheckIfBorder uIndex UnpairedBorder;
					)
				)
				
				--print ("Found New Pairs: " + (FoundNewPairs	as string))
			)	while FoundNewPairs!=0
				
			Format "Pairs by edge connections: %ms\n" (timeStamp()-tt)
			
			proBar.value = 100;
			proBar.color = [0,255,0]
			
			EPolyObj.selectedVerts = Result
			Result
		) -- FindPairs funciton END
		
		function GetVertsConnected EP vertIdx =
		(
			edges = polyop.getEdgesUsingVert EP vertIdx
			verts = polyop.getVertsUsingEdge EP edges
			--return
			(verts - #{vertIdx})
		)
		

		------------- Same as FindPairs but calling my .NET library

		function FindPairs_dotNet ePoly =
		(			
			--vertices
			tt = timeStamp()
			if (classOf ePoly) != Editable_poly then return undefined;
			numVerts = polyop.getNumVerts ePoly
			in coordsys local (
				allVerts = polyop.getVerts ePoly #{1..(numVerts)}	
			)			
			
						
			--conections
			vertConnections = #()
			
			numEdges = polyop.getNumEdges ePoly
			vertConnections = polyop.getEdgesVerts ePoly #{1..numEdges}				
		
-- 				vertConnections.count = numVerts
-- 				ttt = timeStamp()
-- 				for i = 1 to numVerts do
-- 				(
-- 					vertConnections[i] = (GetVertsConnected ePoly i) as array
-- 				)
-- 				Format "Getting connections: %ms\n" (timeStamp()-tt)
		
			
			TArrayArrayFloat = dotNetClass "System.single[][]"
			TArrayArrayInt = dotNetClass "System.int32[][]"
			csVerts = dotnet.valueToDotNetObject allVerts TArrayArrayFloat			
			csVertConnections = dotnet.valueToDotNetObject vertConnections TArrayArrayInt
			
			
			Format "Preparing data: %ms\n" (timeStamp()-tt)
			
			--.net calls
			result = undefined
			if usingDllManager and (dllManager!=undefined) then
			(
				result = dllManager.callMethod "Symmetry.Functions.FindPairs" args:#(csVerts, csVertConnections)
			) else
			(
				--standard call to .net functions
				result = dllFuncs.FindPairs csVerts csVertConnections
			)
			
			tt = timeStamp()
			SetVertsInfo_count numVerts;			
			
			vertsInfo_RightSide = result.rightSide
			vertsInfo_vPos = allVerts			
			vertConnections = result.connections
			
			pairedWith = result.pairedWith	
			
			for i=1 to numVerts do 
			(							
				pw = pairedWith[i]+1
				if pw==0 then pw = undefined;
				vertsInfo_PairedWith[i] = pw
				vertsInfo_linkedTo[i] = vertConnections[i] as bitArray
				--format "%\n" vertsInfo_linkedTo[i]
			)

			
			unpaired = result.unpaired as bitArray
			
			--return
			ePoly.selectedVerts = unpaired			
			Format "Parsing result: %\n" (timeStamp()-tt)
			(unpaired)
		)
	
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
				for i=1 to VertsInfo_count do  in coordsys local
				(
					if vertsInfo_RightSide[i] then 
					(
						--is positive copy to paired
						local him = vertsInfo_PairedWith[i]
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
								local myOffset = myPos - vertsInfo_vPos[i]
								local hisOffset = hisPos - vertsInfo_vPos[him]
								--mirror the offset translation
								myOffset.x = - myOffset.x
								hisOffset.x = - hisOffset.x
								--apply mirrored  offset on opposite 
								if (PosToNeg or Flip) then polyOp.setVert $ him (vertsInfo_vPos[him] + myOffset)
								if ((not PosToNeg) or Flip) then polyOp.setVert $ i (vertsInfo_vPos[i] + hisOffset)
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
				tt = timeStamp()
				Print "Finding symmetrical pairs..."
				FindPairs_dotNet baseObject				
				Format "Processing time: %\n" (timeStamp()-tt)
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
						local opposite = vertsInfo_PairedWith[ ClipboardIndexes[i] ]
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
        
        on btnSwitchSides pressed do 
        (
            if ((classof $)==Editable_poly) and (SubobjectLevel == 1) then
            (
                verts = (polyop.getVertSelection $) as array
                for i=1 to verts.count do
                (
                    if verts[i] < VertsInfo_count then
                    (
                        vertsInfo_RightSide[verts[i]] = not vertsInfo_RightSide[verts[i]]
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
		
		on btnDelete pressed do undo on
		(
			if ( (classof $ ) == Editable_Poly) then
			(
				--Vertices?
				
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
                    if SubObjectLevel == 1 then
                    (
                        if chkEnabledSym.checked then
                        (
                            local mirrSel = mirrorVertSel vertSel
                            vertSel = vertSel + mirrSel
                        )
                        polyOp.deleteVerts $ vertSel
                   ) else if SubObjectLevel == 4 then
                   (
                       local faceSel = polyOp.getFaceSelection $
                       if chkEnabledSym.checked then
                       (
                           local mirrSel = mirrorFaceSel $ faceSel
                           faceSel = faceSel + mirrSel
                       )
                       polyOp.deleteFaces $ faceSel                       
                   )
                   
                   
					
					-- restoring the order verts info
					newVerts.count = polyOp.getNumVerts $
					for i=1 to newVerts.count do
					(
						newVerts[i] = polyOp.getVert $ i
					)                    
                    
					DetectNewVertsOrder OldVerts NewVerts
					
				
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
							edgeVerts1[1] = vertsInfo_PairedWith[ edgeVerts1[1] ]
							edgeVerts1[2] = vertsInfo_PairedWith[ edgeVerts1[2] ]
							edgeVerts2[1] = vertsInfo_PairedWith[ edgeVerts2[1] ]
							edgeVerts2[2] = vertsInfo_PairedWith[ edgeVerts2[2] ]
							
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
							-- because potato we know the new vertices are added to the end, so expand arrays
							SetVertsInfo_count (polyOp.getNumVerts $)							
							local v1Pos = polyOp.getVert $ v1
							local v2Pos = polyOp.getVert $ v2
							vertsInfo_RightSide[v1] = (v1Pos.x >= 0)
							vertsInfo_RightSide[v2] = (v2Pos.x >= 0)
							vertsInfo_vPos[v1] = v1Pos
							vertsInfo_vPos[v2] = v2Pos						
							if (v3 != undefined) and (v3 != undefined) then 
							(								
								local v3Pos = polyOp.getVert $ v3
								local v4Pos = polyOp.getVert $ v4
								vertsInfo_RightSide[ v3 ] = (v3Pos.x >= 0 );
								vertsInfo_RightSide[ v4 ] = (V4Pos.x >= 0);
								vertsInfo_vPos[v3] = v3Pos
								vertsInfo_vPos[v4] = v4Pos
								-- pairing
								vertsInfo_PairedWith[v1] = v3
								vertsInfo_PairedWith[v3] = v1
								vertsInfo_PairedWith[v2] = v4
								vertsInfo_PairedWith[v4] = v2
							)
							
						) else messageBox "Please, select 2 edges on the same face."
					) else messageBox "Please, select 2 edges."
					
				)
			)			
		)--on btnConnect pressed
		
	)--rollout roll_EditGeometry ---end --
	
	loadDll()
	rf = newRolloutFloater "Pro Symmetry Tools"  DialogWidth DialogHeight
	addrollout roll_proSymmetryTools rf
	addrollout roll_EditGeometry rf
	--createDialog roll_proSymmetryTools DialogWidth 500

)

