-- Pro Symmetry Tools 
-- Denys Almaral

-- Implement similar funcionality of 3ds Max Symmetry Tool and extends with useful advanced features..

--TODO:
-- ISSUE: paste vertices from Editable_Poly to Edit_Poly modifier has syscoord issues
-- collapse vertices, weld
-- Symmetry attach! Powerful thingy (think about UV mapping)
-- extrude face, edge


--future macro
struct TpxSymmetryCache (count=0, RightSide=#(), LinkedTo=#(), PairedWith=#(), vPos=#(), objName="")
global pxSymmetryGlobalCache
if pxSymmetryGlobalCache == undefined or not (isProperty pxSymmetryGlobalCache #objName) do pxSymmetryGlobalCache = TpxSymmetryCache()

(
	local g_vertsInfo = pxSymmetryGlobalCache


	local  Tolerance = 0.005
	local MySelection = #{}
	local MirrorRightToLeft  = true
	
	local baseObject = undefined
	local ClipboardIndexes = #() --array of indices;
	local ClipboardIndexes = #() --array of indices;
	local ClipboardVerts = #() --array of verts
	
	local DialogWidth = 250
	local DialogHeight = 800
	local maxBWidth = DialogWidth - 30
	--settings
	usingDllManager = false
    dllFuncs = undefined
	
	-- API Wrapper to abstract Editable_Poly vs Edit_Poly
	struct PolyAPI (
		obj, epMod, isEditPoly,
		fn init o = (
			obj = o
			if (classof o) == Editable_poly then (
				isEditPoly = false
			) else if (classof (modPanel.getCurrentObject())) == Edit_poly then (
				isEditPoly = true
				epMod = modPanel.getCurrentObject()
			) else (
				-- fallback
				isEditPoly = false 
			)
		),
		fn getNumVerts = (
			if isEditPoly then epMod.GetNumVertices() else polyop.getNumVerts obj
		),
		fn getVert i = (
			if isEditPoly then (
				(epMod.GetVertex i node:obj) * (inverse obj.transform)
			) else polyOp.getVert obj i
		),
		fn getVerts bs = (
			if isEditPoly then (
				local res = #()
				local invTM = inverse obj.transform
				for i in bs do append res ((epMod.GetVertex i node:obj) * invTM)
				res
			) else (
				polyOp.getVerts obj bs
			)
		),
		fn setVerts bs pArr = (
			if isEditPoly then (
				-- Simple optimizations: pre-calculate transforms and reuse a bitarray
				local tm = obj.transform
				local worldPosArr = for p in pArr collect p * tm
				local c = 1
				local theMod = epMod
				local vBit = #{}
				
				max modify mode -- Basic requirement for Edit_Poly commands to land
				with redraw off (
					for i in bs do (
						vBit[i] = true
						theMod.SetVert vBit worldPosArr[c]
						vBit[i] = false
						c += 1
					)
					theMod.Commit()
				)
			) else (
				polyOp.setVert obj bs pArr
			)
		),
		fn setVert i p = (
			if isEditPoly then (
				epMod.SetVert #{i as integer} (p * obj.transform)
				epMod.Commit()
			) else (
				polyOp.setVert obj i p
			)
		),
		fn getVertSelection = (
			if isEditPoly then epMod.GetSelection #Vertex else polyop.getVertSelection obj
		),
		fn setVertSelection bs = (
			if isEditPoly then (
				-- SetSelection successfully clears, but is broken for adding bits.
				-- We clear it first, then use the proven .Select method to apply the new bits.
				 if subObjectLevel == 0 then subObjectLevel = 1
				epMod.SetSelection #Vertex #{}
				epMod.Select #Vertex bs
				
			) else (
				polyop.setVertSelection obj bs
			)
		),
		fn selectModified pArr tolerance = (
			local num = getNumVerts()
			local diffBS = #{}
			if isEditPoly then (
				local invTM = inverse obj.transform
				for i = 1 to num do (
					local p = (epMod.GetVertex i node:obj) * invTM
					if (i <= pArr.count) and ((distance p pArr[i]) > tolerance) do diffBS[i] = true
				)
			) else (
				-- Optimized for Editable_Poly
				local currentPosArr
				in coordsys local ( currentPosArr = polyop.getVerts obj #{1..num} )
				for i = 1 to num do (
					if (i <= pArr.count) and ((distance currentPosArr[i] pArr[i]) > tolerance) do diffBS[i] = true
				)
			)
			setVertSelection diffBS
			diffBS
		)
	)
	
	local api = PolyAPI()

    -- common functions			
	
	function SetGVertsInfo_count count =
	(
		g_vertsInfo.RightSide.count = count
		g_vertsInfo.LinkedTo.count = count
		g_vertsInfo.PairedWith.count = count
		g_vertsInfo.vPos.count = count
		g_vertsInfo.count = count
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
            local pair = g_vertsInfo.PairedWith[ verts[i] ]
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
        local n_RightSide = #()
        local n_LinkedTo = #()
        local n_PairedWith = #()
        local n_vPos = #()
        
        n_RightSide.count = NewVerts.count
        n_LinkedTo.count = NewVerts.count
        n_PairedWith.count = NewVerts.count
        n_vPos.count = NewVerts.count

        print oldVerts.count
        print NewVerts.count			
        for o = 1 to NewIndex.count do
        (
            --moving to new location
            local ni = NewIndex[o]
            if ni != undefined then
            (
                n_RightSide[ni] = g_vertsInfo.RightSide[o]
                n_LinkedTo[ni]  = g_vertsInfo.LinkedTo[o]
                n_vPos[ni]      = g_vertsInfo.vPos[o]

                --Updating pairs				
                local newPair = g_vertsInfo.PairedWith[o]
                if newPair!= undefined then
                (
                    if newPair <= NewIndex.count then newPair = NewIndex[ newPair ] else newPair = undefined
                )
                n_PairedWith[ni] = newPair
            )
        )
        --replace old with new
        g_vertsInfo.RightSide = n_RightSide
        g_vertsInfo.LinkedTo = n_LinkedTo
        g_vertsInfo.PairedWith = n_PairedWith
        g_vertsInfo.vPos = n_vPos
        g_vertsInfo.count = NewVerts.count
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
			button btnPosToNeg "R << L"  height:26 width:70 align:#left tooltip:"Mirror from Left to Right"
			button btnNegToPos "R >> L" height:26 width:70  offset:[0,-31] align:#right tooltip:"Mirror from Right to Left"
			checkbox chkRelative "Relative translation" checked:false tooltip:"Keeps the original position mirroring the offset translation"
			button btnFlip " Flip Symmetry " width:maxBWidth 
			button btnRestore "Restore Original" width:maxBWidth tooltip:"Restore selected vertices to their original state. If nothing is selected, restores the entire object."
		)
		
		group "Vertex operations"
		(
			button btnCopySel "Copy Selected" width:maxBWidth
			button btnPaste "Paste" width:maxBWidth
			button btnPasteMultiple "Paste Multiple" width:maxBWidth
			button btnPasteOpposite "Paste Opposite" width:maxBWidth
			button btnSelectDiff "Select Diff" width:maxBWidth
		)
		
		function UpdateUISelectionState =
		(
			if g_vertsInfo == undefined or g_vertsInfo.count == 0 then (
				proBar.color = [200,0,0] -- Red
			) else (
				local matchingCount = 0
				local sel = selection as array
				if sel.count > 0 then (
					for obj in sel do (
						local vCount = -1
						try (
							if (classof obj.baseObject == Editable_Poly) then vCount = polyop.getNumVerts obj.baseObject
							else if (isProperty obj #GetNumVertices) then vCount = obj.GetNumVertices()
						) catch ( vCount = -1 )
						
						if vCount == g_vertsInfo.count do matchingCount += 1
					)
					
					if matchingCount == sel.count then proBar.color = [0,255,0] -- Green
					else if matchingCount > 0 then proBar.color = [255,255,0] -- Yellow
					else proBar.color = [255,165,0] -- Orange
				) else (
					proBar.color = [255,165,0] -- Orange (data exists but nothing selected)
				)
			)
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
			
			SetGVertsInfo_count N
			
			--initializing vertInfo
            tt = timeStamp()
			for i=1 to N do in coordsys local
			(
				local v1 = polyop.getVert EPolyObj i
				g_vertsInfo.vPos[i] = v1				
				if (v1.x >=0) then
				(
					g_vertsInfo.RightSide[i] = true  -- RightSide = positive
					append positiveVerts i 
				) else
				(
					g_vertsInfo.RightSide[i] = false
					append negativeVerts i					
				)
                
				
				--Vertices on the "center" Symmetry AXE paired with themselves. 
				If 	abs(v1.x) <= Tolerance then 
				(	
					g_vertsInfo.PairedWith[i] = i	
					Result[i]=false
				)
				
				--Links
				--Find the list of vertices connected via edge, store in LinkedTo bitarray
				local MyEdges = polyop.getEdgesUsingVert EPolyObj  i
				g_vertsInfo.LinkedTo[i] = #{}	
				for k in MyEdges do
				(
					g_vertsInfo.LinkedTo[i]  = g_vertsInfo.LinkedTo[i]  + (polyop.getVertsUsingEdge EPolyObj k )			
				)		
				--remove self
				g_vertsInfo.LinkedTo[i] =  g_vertsInfo.LinkedTo[i] - #{i}
			)
         
            Format "initializing: %ms\n" (timeStamp()-tt)
			
			
			--Finding Pairs by position------------------------------- The standard easy way				
			
            tt = timeStamp()
			proBar.color = [0,255,255]
			for i=1 to positiveVerts.count do in coordsys local
			(
				local v1 = g_vertsInfo.vPos[ positiveVerts[i] ]
				
				for j=1 to negativeVerts.count do
				(			
					local v2 = copy g_vertsInfo.vPos[ negativeVerts[j] ]
					v2.x = -v2.x
					local d = (distance v1 v2)
					
					if d<=Tolerance then
					(
						g_vertsInfo.PairedWith[ positiveVerts[i] ] = negativeVerts[j]
						g_vertsInfo.PairedWith[ negativeVerts[j] ] = positiveVerts[i] 
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
				linklist = g_vertsInfo.LinkedTo[index] as array
				len = linklist.count
				while ((not nextToPaired) and (alink <= len)) do
				(						
					nextToPaired = ( g_vertsInfo.PairedWith[ linkList[alink] ] != undefined)
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
					for k in g_vertsInfo.LinkedTo[i] do
					(
						if g_vertsInfo.PairedWith[k]==undefined then
						(
							RUnpairedLinks +=  1
						) else 
						(
							-- collect just the links indices for this side
							RSymLinks[k] = true
						)					
					)
					
						if (g_vertsInfo.PairedWith[i]==undefined) and (not RSymLinks.isEmpty) then
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
								for k in g_vertsInfo.LinkedTo[j] do
								(
									if g_vertsInfo.PairedWith[k]==undefined then
									(
										LUnpairedLinks += 1
									) else 
									(
										-- for this side The pairs of the links
										LSymLinks[g_vertsInfo.PairedWith[k]]=true
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
								g_vertsInfo.PairedWith[i] = MyCandidate
								g_vertsInfo.PairedWith[MyCandidate] = i
                                -- Revise the Side of the vertices.
                                
								FoundNewPairs += 1 
								Result[i]=false
								Result[MyCandidate]=false                                
								NewLinksCount += 1
								--updating progressbar
								proBar.value = (100 * NewLinkscount) / UnlinkedPairs	
									
							)--if MyCandidateNum == 1
							
						)--if g_vertsInfo.PairedWith[i]==undefined
					
				)--For I end
                
                --Rebuilding the border, just close to the old border
				UnpariedBorder = #{}
				for idx in ResultList do
				(
					for uIndex in g_vertsInfo.LinkedTo[idx] do 
					(
						if (g_vertsInfo.PairedWith[uIndex] == undefined) then CheckIfBorder uIndex UnpairedBorder;
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
				print "DLL functions vis DLL Manager"
			) else
			(
				--standard call to .net functions
				result = dllFuncs.FindPairs csVerts csVertConnections
			)
			
			tt = timeStamp()
			SetGVertsInfo_count numVerts;			
			
			g_vertsInfo.RightSide = result.rightSide
			g_vertsInfo.vPos = allVerts			
			vertConnections = result.connections
			
			pairedWith = result.pairedWith	
			
			for i=1 to numVerts do 
			(							
				pw = pairedWith[i]+1
				if pw==0 then pw = undefined;
				g_vertsInfo.PairedWith[i] = pw
				g_vertsInfo.LinkedTo[i] = vertConnections[i] as bitArray
				--format "%\n" g_vertsInfo.LinkedTo[i]
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
			tt = timeStamp();
			if PosToNeg == unsupplied then PosToNeg = true
			if Axis == unsupplied then Axis = "x"
			if Flip == unsupplied then Flip = false			
				
			-- copy Positive positions to Negative on selected object
			api.init $
			if api.obj != undefined then
			(
				local allSet =  #{1..(api.getNumVerts())}
				local allVerts
				in coordsys local (
					allVerts = api.getVerts allSet
				)
				
				for i=1 to g_vertsInfo.count do 
				(
					if g_vertsInfo.RightSide[i] then 
					(
						--is positive copy to paired
						local him = g_vertsInfo.PairedWith[i]
						if him != undefined then
						(
							local myPos = copy allVerts[i] --polyOp.getvert $ i	
							local hisPos = copy allVerts[him] --polyOp.getvert $ him
																								
							if chkRelative.checked==false then
							(
								--mirror positions
								myPos.x = - myPos.x 
								hisPos.x = - hisPos.x
								--set to my pair
								if (PosToNeg or Flip) then allVerts[him] = myPos --polyOp.setVert $ him myPos 
								if ((not PosToNeg) or Flip) then allVerts[i] = hisPos --polyOp.setVert $ i hisPos							
							) else
							(
								--calc offset translations taking oriignal vertices as origin
								local myOffset = myPos - g_vertsInfo.vPos[i]
								local hisOffset = hisPos - g_vertsInfo.vPos[him]
								--mirror the offset translation
								myOffset.x = - myOffset.x
								hisOffset.x = - hisOffset.x
								--apply mirrored  offset on opposite 
								if (PosToNeg or Flip) then allVerts[him] = (g_vertsInfo.vPos[him] + myOffset) --polyOp.setVert $ him (g_vertsInfo.vPos[him] + myOffset)
								if ((not PosToNeg) or Flip) then allVerts[i] = (g_vertsInfo.vPos[i] + hisOffset) --polyOp.setVert $ i (g_vertsInfo.vPos[i] + hisOffset)
							)
							
						)						
					)
				)
				in coordsys local (
					api.setVerts allSet allVerts
				)
			)
			--format "Symm op: %ms\n" (timeStamp()-tt)
		)
		
		on btnPickObject picked obj do
		(
			if (classof obj)==Editable_poly then 
			(				
				baseObject = obj
				tt = timeStamp()
				Print "Finding symmetrical pairs..."
				FindPairs_dotNet baseObject				
				--FindPairs baseObject				
				Format "Processing time: %\n" (timeStamp()-tt)
				btnPickObject.text = obj.name
				g_vertsInfo.objName = obj.name
				UpdateUISelectionState()
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
		
		on btnRestore pressed do in coordsys local
		(
			undo label:"Restore Original" on
			(
				api.init $
				if api.obj != undefined then
				(
					local vertSel = api.getVertSelection()
					if vertSel.isEmpty do vertSel = #{1..(api.getNumVerts())}
					
					if not vertSel.isEmpty then
					(
						local posArr = for i in vertSel collect g_vertsInfo.vPos[i]
						api.setVerts vertSel posArr
						format "Restored % vertices to original positions.\n" vertSel.numberSet
					)
				)
			)
		)
		
		on btnCopySel pressed do in coordsys local
		(
			api.init $
			if api.obj != undefined then
			(
				local vertSel = api.getVertSelection()
				ClipboardIndexes = vertSel as array
				ClipboardVerts = api.getVerts vertSel
				btnPaste.text = ("Paste (" + (ClipboardVerts.count as string) + ") ")
			)
		)
		
		on btnPaste pressed do in coordsys local
		(
			undo label:"Paste Verts" on
			(
				api.init $
				if api.obj != undefined then api.setVerts ClipboardIndexes ClipboardVerts
			)
		)

		on btnPasteMultiple pressed do in coordsys local
		(
			undo label:"Paste Multiple Verts" on
			(
				for obj in selection do
				(
					if classof obj.baseObject == Editable_Poly then
					(
						try (
							polyOp.setVert obj.baseObject ClipboardIndexes ClipboardVerts
						) catch (
							format "Warning: Paste Multiple failed on object: %\n" obj.name
						)
						update obj
					)
				)
				redrawViews()				
			)
		)
		
		on btnPasteOpposite pressed do in coordsys local
		(
			undo label:"Paste Opposite" on
			(
				api.init $
				if api.obj != undefined then (
					local targetIndices = #{}
					local targetPairs = #() -- Array to store #(index, mirroredPos)
					local maxverts = api.getNumVerts()
					
					for i=1 to ClipboardIndexes.count do
					(
						if ClipboardIndexes[i]<=maxverts then
						(
							local opposite = g_vertsInfo.PairedWith[ ClipboardIndexes[i] ]
							if opposite != undefined and opposite <= maxverts then
							(
								local opvert = copy ClipboardVerts[i] 
								opvert.x = -opvert.x
								append targetPairs #(opposite, opvert)
								targetIndices[opposite] = true
							)
						)
					)

					if not targetIndices.isEmpty then (
						-- Ensure positions match bitarray order (ascending index)
						fn sortByIndex v1 v2 = if v1[1] < v2[1] then -1 else if v1[1] > v2[1] then 1 else 0
						qsort targetPairs sortByIndex
						
						local targetPosArr = for pair in targetPairs collect pair[2]
						api.setVerts targetIndices targetPosArr
					)
				)
			)
		)

		on btnSelectDiff pressed do 
		(
			api.init $
			if g_vertsInfo.count > 0 and api.obj != undefined then (
				local diff = api.selectModified g_vertsInfo.vPos Tolerance
				format "Select Diff: % vertices found.\n" diff.numberSet
				--UpdateUISelectionState()
				--forceCompleteRedraw()
			)
		)
        
        on btnSwitchSides pressed do 
        (
			api.init $
            if (api.obj != undefined) and (SubobjectLevel == 1) then
            (
                verts = (api.getVertSelection()) as array
                for i=1 to verts.count do
                (
                    if verts[i] <= g_vertsInfo.count then
                    (
                        g_vertsInfo.RightSide[verts[i]] = not g_vertsInfo.RightSide[verts[i]]
                    )
                )
            )
        )
		
		on roll_proSymmetryTools open do
		(
			if g_vertsInfo.objName != "" do btnPickObject.text = g_vertsInfo.objName
			UpdateUISelectionState()
			callbacks.removeScripts id:#pxSymmetryCallbacks
			callbacks.addScript #selectionSetChanged roll_proSymmetryTools.UpdateUISelectionState id:#pxSymmetryCallbacks
		)
		
		on roll_proSymmetryTools close do
		(
			callbacks.removeScripts id:#pxSymmetryCallbacks
		)
		
		
	)--rollout roll_proSymmetryTools ---------
	
		
	rollout roll_EditGeometry "Edit Geometry Symmetrical" ----------------------------------
	(
		checkbox chkEnabledSym "Enabled Sym. Ops." checked:true tooltip:"Mirror edit operations"
		button btnDelete "Delete" 
		button btnConnect "Connect"
		button btnCollapse "Collapse"
		local targetObjects = #()
		group "Batch Operations" (
			checkbox chkApplyToTargets "Apply Edits to Targets" checked:false
			button btnPickTargets "Pick Targets..." tooltip:"Select objects to apply geometry Ops. to." width:maxBWidth
			listbox lstTargets "Target Objects:" height:3
		)
		
		fn getObjectsToProcess masterObj = (
			local list = #(masterObj)
			if chkApplyToTargets.checked then (
				for t in targetObjects where isValidNode t and (classOf t.baseObject == Editable_Poly) do (
					appendIfUnique list t
				)
			)
			list
		)
		
		on btnPickTargets pressed do (
			local selectionList = selectByName title:"Select Target Objects (Matching Topology)" filter:(fn pFilter o = classOf o.baseObject == Editable_Poly)
			if selectionList != undefined then (
				targetObjects = selectionList as array
				lstTargets.items = for o in targetObjects collect o.name
			)
		)
		
		on btnDelete pressed do undo on
		(
			if ( (classof $ ) == Editable_Poly) then
			(
				local masterO = $
				local objs = getObjectsToProcess masterO
				local vertSel = polyOp.getVertSelection masterO
				local oldVerts = #()
				local oldVertCount = polyOp.getNumVerts masterO
				
				-- saving old state of master Object
				oldVerts.count = oldVertCount
				for i=1 to oldVertCount do oldVerts[i] = polyOp.getVert masterO i
				
				-- destructive operation
				if SubObjectLevel == 1 then
				(
					if chkEnabledSym.checked then
					(
						local mirrSel = mirrorVertSel vertSel
						vertSel = vertSel + mirrSel
					)
					for o in objs where (polyOp.getNumVerts o.baseObject == oldVertCount) do (
						polyOp.deleteVerts o.baseObject vertSel
					)
				) else if SubObjectLevel == 4 then
				(
					local faceSel = polyOp.getFaceSelection masterO
					if chkEnabledSym.checked then
					(
						local mirrSel = mirrorFaceSel masterO faceSel
						faceSel = faceSel + mirrSel
					)
					for o in objs where (polyOp.getNumVerts o.baseObject == oldVertCount) do (
						polyOp.deleteFaces o.baseObject faceSel
					)
				)
				
				-- restoring the order verts info based on master
				local newVertCount = polyOp.getNumVerts masterO
				local newVerts = #()
				newVerts.count = newVertCount
				for i=1 to newVertCount do newVerts[i] = polyOp.getVert masterO i
				
				DetectNewVertsOrder oldVerts newVerts
			)
		)--on btnDelete
		
		on btnConnect pressed do in coordsys local undo on
		(
			if ( (classof $ ) == Editable_Poly) then
			(
				local masterO = $
				local objs = getObjectsToProcess masterO
				local oldVertCount = polyOp.getNumVerts masterO

				if SubObjectLevel == 1 then
				(
					local vertSel = polyOp.getVertSelection masterO					
					local verts = vertSel as array
					
					if verts.count == 2 then
					(
						for o in objs where (polyOp.getNumVerts o.baseObject == oldVertCount) do (
							polyOp.createEdge o.baseObject verts[1] verts[2]
						)
						
						if chkEnabledSym.checked then
						(
							local mirrSel = mirrorVertSel vertSel						
							local mirrVerts = mirrSel as array
							if mirrVerts.count == 2 then (
								for o in objs where (polyOp.getNumVerts o.baseObject == oldVertCount) do (
									polyOp.createEdge o.baseObject mirrVerts[1] mirrVerts[2]
								)
							)
						)
						for o in objs do update o
					) else messageBox "Please, select 2 vertices."
					
				) else if SubObjectLevel == 2 then
				( 
					-- edges
					local edgeSel = polyOp.getEdgeSelection masterO
					local edges = edgeSel as array
					if edges.count == 2 then 
					(
						if AreEdgesOnSameFace masterO edges then
						(			
							local edgeVerts1 = polyop.getEdgeVerts masterO edges[1]
							local edgeVerts2 = polyop.getEdgeVerts masterO edges[2]
							
							local mEdges = undefined
							if chkEnabledSym.checked then (
								local me1v = mirrorVerts edgeVerts1
								local me2v = mirrorVerts edgeVerts2
								if me1v.count == 2 and me2v.count == 2 then (
									local me1 = getEdgeByVerts masterO me1v
									local me2 = getEdgeByVerts masterO me2v
									if me1 != undefined and me2 != undefined then mEdges = #(me1, me2)
								)
							)
							
							local v1_master, v2_master, v3_master, v4_master
							
							for o in objs where (polyOp.getNumVerts o.baseObject == oldVertCount) do (
								local v1 = polyop.divideEdge o.baseObject edges[1] 0.5
								local v2 = polyop.divideEdge o.baseObject edges[2] 0.5
								polyOp.createEdge o.baseObject v1 v2
								
								if o == masterO then (v1_master = v1 ; v2_master = v2)
								
								if mEdges != undefined then (
									local v3 = polyop.divideEdge o.baseObject mEdges[1] 0.5
									local v4 = polyop.divideEdge o.baseObject mEdges[2] 0.5
									polyOp.createEdge o.baseObject v3 v4
									if o == masterO then (v3_master = v3 ; v4_master = v4)
								)
								update o
							)
							
							-- Update Master Symmetry Info
							if v1_master != undefined and v2_master != undefined then (
								SetGVertsInfo_count (polyOp.getNumVerts masterO)
								local v1Pos = polyOp.getVert masterO v1_master
								local v2Pos = polyOp.getVert masterO v2_master
								g_vertsInfo.RightSide[v1_master] = (v1Pos.x >= 0)
								g_vertsInfo.RightSide[v2_master] = (v2Pos.x >= 0)
								g_vertsInfo.vPos[v1_master] = v1Pos
								g_vertsInfo.vPos[v2_master] = v2Pos
								
								if v3_master != undefined and v4_master != undefined then (
									local v3Pos = polyOp.getVert masterO v3_master
									local v4Pos = polyOp.getVert masterO v4_master
									g_vertsInfo.RightSide[v3_master] = (v3Pos.x >= 0)
									g_vertsInfo.RightSide[v4_master] = (v4Pos.x >= 0)
									g_vertsInfo.vPos[v3_master] = v3Pos
									g_vertsInfo.vPos[v4_master] = v4Pos
									
									g_vertsInfo.PairedWith[v1_master] = v3_master
									g_vertsInfo.PairedWith[v3_master] = v1_master
									g_vertsInfo.PairedWith[v2_master] = v4_master
									g_vertsInfo.PairedWith[v4_master] = v2_master
								)
							)
							
						) else messageBox "Please, select 2 edges on the same face."
					) else messageBox "Please, select 2 edges."
					
				)
			)			
		)--on btnConnect pressed
		
		on btnCollapse pressed do in coordsys local undo on
		(
			if ((classof $) == Editable_Poly) then
			(
				local masterO = $
				local objs = getObjectsToProcess masterO
				local oldVertCount = polyOp.getNumVerts masterO

				if SubObjectLevel == 1 then
				(
					local vertSel = polyOp.getVertSelection masterO
					local verts = vertSel as array
					
					if verts.count == 2 then
					(
						local v1 = verts[1]
						local v2 = verts[2]
						local p1 = polyOp.getVert masterO v1
						local p2 = polyOp.getVert masterO v2
						local midPos = (p1 + p2) / 2.0
						
						local v3 = undefined
						local v4 = undefined
						local midPosMirr = undefined
						local weldSet = #{v1, v2}
						
						if chkEnabledSym.checked then
						(
							v3 = g_vertsInfo.PairedWith[v1]
							v4 = g_vertsInfo.PairedWith[v2]
							
							if (v3 != undefined) and (v4 != undefined) and (v3 != v1) and (v4 != v2) then
							(
								midPosMirr = copy midPos
								midPosMirr.x = -midPosMirr.x
								weldSet[v3] = true
								weldSet[v4] = true
							)
						)

						-- Batch reposition and capture snapshot for Master BEFORE weld
						-- but we move everyone to target first
						for o in objs where (polyOp.getNumVerts o.baseObject == oldVertCount) do (
							local base = o.baseObject
							polyOp.setVert base v1 midPos
							polyOp.setVert base v2 midPos
							if midPosMirr != undefined then (
								polyOp.setVert base v3 midPosMirr
								polyOp.setVert base v4 midPosMirr
							)
						)

						-- Update "Original" position for Master before snapshot
						g_vertsInfo.vPos[v1] = midPos
						if (midPosMirr != undefined and v3 != undefined) do g_vertsInfo.vPos[v3] = midPosMirr

						-- Spatial Snapshot of Master
						local oldVerts = for i=1 to oldVertCount collect (polyOp.getVert masterO i)
						
						-- Execute Max Native Rewiring for all
						for o in objs where (polyOp.getNumVerts o.baseObject == oldVertCount) do (
							o.weldThreshold = 0.001
							polyOp.weldVertsByThreshold o.baseObject weldSet
							update o
						)
						
						-- Restore logic structures based on master survivors
						local newCount = polyOp.getNumVerts masterO
						local newVerts = for i=1 to newCount collect (polyOp.getVert masterO i)
						
						DetectNewVertsOrder oldVerts newVerts
						
						-- Update interface
						polyOp.setVertSelection masterO #{}
					) 
					else messageBox "Please, select exactly 2 vertices."
				)
			)
		)--on btnCollapse
		
	)--rollout roll_EditGeometry ---end --
	
	loadDll()
	rf = newRolloutFloater "Pro Symmetry Tools"  DialogWidth DialogHeight
	addrollout roll_proSymmetryTools rf
	addrollout roll_EditGeometry rf
	--createDialog roll_proSymmetryTools DialogWidth 500

)

