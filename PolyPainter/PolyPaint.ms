-- Poly  Paint, a tool to paint polygos with a flat color from texture, setting all vertices of a UV face to a single point in texture, giving always a flat color
-- By Denys Almaral - 2018

-- Updates:

-- Migrated from Unwrap UVW functions to direct polyOp functions. Faster smooth calls.
-- Paint-edit Multiple objects at the same time. 
-- Remappping textures: Swap old with new, remapping UV, keeping same colors look.
-- UI review
-- 2021: Auto-isert Unwrap UVW modifier. APPLY button to collapse to Unwrap UVW position in stack.
-- 2019: ability to copy paste UV colors coords from Win clipboard 
-- implmented Undo levels
-- added Flood Fill algorithm
-- Added Mirror functionality
-- Full repaint the whole object with selected color 
-- 2018: v1.0 basic functionality 

--- TODO:

-- What to do when multiple selected objects have different textures? Limitation or feature?


--macroScript PolyPaint buttonText:"Poly Paint" category:"pX Tools" tooltip:"Poly UV Painter"
(

	local lastTriFace = -1
	local theObj = undefined
	local lastObj = undefined
	local theObjects = #()
	local mod_states = #()
	local masterObj = undefined
	local mapChannel = 1
	local curr_UV = [0.5,0.5,0]
	local currStrokeNum = 0
	local thePI = thePainterInterface
	local rmIntersect = RayMeshGridIntersect()m
	local faceMapUndo = #()
	local undoLevels = #()
	local undoLevelsMax = 5
	local fill_tolerance = 1
	local bmpSize = 320
	local tempBitmap = bitmap bmpSize bmpSize color:(color 40 40 40)
	local colorBitmap = bitmap 50 50 
	local paintBtnCaption_start = ">>>      START Paint Tool      <<<"
	local paintBtnCaption_stop = ">>>      END Paint Tool      <<<"
	
	local ini_file = (getDir #userMacros) + "\\pxpolypaint.ini"
	local ini_section = "config"
	
	function set_ini key val = (
		setINISetting ini_file ini_section key (val as string)
	)
	function get_ini key = (
		getINISetting ini_file ini_section key
	)
	
	function eval s = (
		try execute s catch ""
	)

	
	rollout roll_polyPaint "pX Poly Paint" 
	(

		
		imgTag bmpColorPal bitmap:tempBitmap pos:[0,0] style:#bmp_stretch transparent:(color 68 68 68)
	
		--label lblInfo "Select object and press Start Painting Tool" pos:[10,10]
		
			checkButton paint3D paintBtnCaption_start width:(bmpSize-5) height:25
			--checkbox chkAutoUV "Auto-insert UV (start)"  across:2 checked:true tooltip:"Adds Unwrap UV modifier over Edit_poly when  painting starts"
			--checkbox chkAutoUV_end "Auto-apply UV (end)"  across:2 checked:true tooltip:"Collaps Unwrap UV modifier over Edit_poly when painting ends"
			
			group "Paint" (
				label lbl3dPickColor "Alt+Click = Color picker" across:2 
				checkbox chkMirror "Mirror Paint" across:2
				button btnFullRepaint "   Full Repaint   " across:2
				checkbox chkSelectedOnly "Repaint selected faces only" across:2 
				checkButton btnFill "Fill Tool" across:2  width:90 height:30 			
				spinner spnSpread "Spread" range:[0,10,0] type:#integer across:2
				button btnUndo " UNDO (use this!)" 
			)
			group "Current Color" (
				imgTag imgCurrColor bitmap:colorBitmap width:50 height:35 across:3 
				spinner spnU "U" range:[0,1,0] type:#float across:3 
				spinner spnV "V" range:[0,1,0] type:#float across:3 
				editText editRGBColor "RGB" text:"[0,0,0]" across:4 readonly:true				
				button btnUV_copy "Copy" across:4 
				button btnUV_paste "Paste" across:4
				button btnUV_set "Set" across:4 
			)						
			
			progressBar pbar "" value:0
			
			group "Texture remapping & swapping" (
				button btnSwapMap "Remap Texture with -->" across:2 toolTip:"Remap UV based on texture target, keeping same colors as close as possible"				
				mapbutton mapBtnSwapMap "<none>" across:2 tooltip:"Select bitmap texture to be replaced with"				
				checkbox chkOptimizeBitmap "Pre-Optimize Bitmap" checked:true tooltip:"Useful if new texture has many repeated pixel colors" across:2
				checkbox chkNoReplace "Remap without replace" checked:false tooltip:"Do not replace with new bitmap when remapping"
			)
			
		local paint_enable = #( btnFullRepaint, btnFill, btnUndo, btnUV_set, btnSwapMap)
		
				
		--============================ FUNCTIONS ===============================------------------------
		
		function enable_tools bool = 
		(
			for ui in paint_enable do ui.enabled = bool				
		)
			
		function updateColorBitmap diffMap = 
		(
			copy diffMap.bitmap tempBitmap
			bmpColorPal.bitmap = tempBitmap
			g_currBitmap = tempBitmap
		)
		
		function UVtoColor UV gamma:true =
		(
			local w = tempBitmap.width
			local h = tempBitmap.height			
			(getPixels tempBitmap [ UV.x * w ,  (1-UV.y) * h ] 1 linear:gamma )[1]
		)
		
		function UVgetPixel UV diffMap gamma:false = (
			local w = diffMap.bitmap.width
			local h = diffMap.bitmap.height				
			if UV.x>=1 or UV.y>=1 or UV.x<=0 or UV.y<=0 then
			(
				print "ERROR: pixel coord out of bounds"
				UV.x = 0.5
				UV.y = 0.5
			)
			(getPixels diffMap.bitmap [ UV.x * w ,  (1-UV.y) * h ] 1 linear:gamma )[1]
		)
		
		function findMatDiffuseMap mat = 
		(
			local diffMap = undefined
			if mat != undefined then 
            (
                diffMap = case classof(mat) of
				(
					blend: mat.map1
					Arch___Design__mi: mat.diffuse_Color_Map
					standard: mat.diffuseMap
					VRayMtl: mat.texmap_diffuse
					default: undefined
				)
                
            )    
            (diffMap)
		)
		
		function replaceDiffuseMap mat diffmap =
		(
			case classof(mat) of
			(
				blend: mat.map1 = diffmap
				Arch___Design__mi: mat.diffuse_Color_Map = diffmap
				standard: mat.diffuseMap = diffmap
				VRayMtl: mat.texmap_diffuse = diffmap				
			)
		)
		
        function findDiffuseMap obj =
        (  
            local mat = obj.material
            findMatDiffuseMap mat
        )
		
        -- updates current Color box on interface.
        -- draw pixels over bitmap to show current color 
		function updateCurrColor =
		(	      
			local diffMap = findMatDiffuseMap masterObj.material
            copy diffMap.bitmap tempBitmap
						
			local p = UVtoColor curr_UV 								
			if p != undefined then
			(
				free colorBitmap
				colorBitmap = bitmap 50 50 color:p 
				imgCurrColor.bitmap = colorBitmap
				
				-- draw pixel marker                
				xx = curr_UV.x * tempBitmap.width
				yy = (1-curr_UV.y) * tempBitmap.height
                for i = 2 to 3 do 
                (
                    setPixels tempBitmap [xx+1*i, yy] #(color 255 255 255)
                    setPixels tempBitmap [xx-1*i, yy] #(color 255 255 255)
                    setPixels tempBitmap [xx, yy+1*i] #(color 0 0 0)
                    setPixels tempBitmap [xx, yy-1*i] #(color 0 0 0)
                )
				bmpColorPal.bitmap = tempBitmap                
                
			)
            
            --set UV coords on spinners
            spnU.value = curr_UV.x
            spnV.value = curr_UV.y
			editRGBColor.text = ((UVGetPixel curr_UV diffMap gamma:false) as point3) as string			
		)
		
			
		function clearUndo = 
		(
			-- store it, actually, in undo levels
			--btnUndo.enabled = false
			append undoLevels faceMapUndo
			if undoLevels.count > undoLevelsMax then deleteItem undoLevels 1
			faceMapUndo = #()		
			print ("undo levels" + (undoLevels.count as string) )
		)
		
		function startStroke = 
		( 
			--thePI.undoStart() 
			clearUndo()
			currStrokeNum = currStrokeNum + 1
		)
		
		fn getPolyFaceByTri node tri =
		(
			-- convert a mesh Face Index to a editable_poly poly index
			-- magic alert!
			local index = 1
			local poly = 0
			local getFaceDeg = polyop.getFaceDeg
			for k = 1 to polyop.getNumFaces node while poly == 0 do
			(
				index += getFaceDeg node k - 2
				if (tri < index) do poly = k
			)
			poly
		)
		
		function unwrap_getMapFace obj poly = 
		(			
			local result = #()
			result.count = obj.Unwrap_UVW.numberPointsInFace poly		
			for i=1 to result.count do
			(				
				result[i] = obj.Unwrap_UVW.getVertexIndexFromFace poly i				
			)
			--return
			(result)
		)
		
		function setAllUVto poly UV UndoOn:true =
		(			
			if theObj != lastObj then
			(
				--changed target node
				modPanel.setCurrentObject theObj.modifiers[#Unwrap_UVW]
			)
			local mapFace = unwrap_getMapFace theObj poly					
			
			
			if UndoOn do 
			(
				-- UNDO DATA			
				local faceUV = #()
				faceUV[1] = poly 			
				--saving, only the first vertex					
				faceUV[2] = theObj.Unwrap_UVW.getVertexPosition 0 mapFace[1]
				faceUV[3] = theObj
				
				append faceMapUndo faceUV
			)
			
			--modifiying
			for i=1 to mapFace.Count do
			(
				--with unwrap_modifier
				theObj.Unwrap_UVW.setFaceVertex [ UV.x, UV.y,0] poly i false
				--directly to Editpoly
				--polyop.setMapVert theObj 1 mapFace[i] [UV.x, UV.y, 0]
			)	
			lastObj = theObj
		)
		
		function setFaceUV faceIdx UV undoOn:true Obj:undefined =
		(	
			if Obj == undefined then
			(
				Obj = theObj
			) 
			if UndoOn do 
			(
				-- UNDO DATA			
				local faceUV = #()
				faceUV[1] = faceIdx			
				--saving, only the first vertex					
				faceUV[2] = polyop.getMapVert Obj mapChannel faceIdx
				faceUV[3] = Obj
				
				append faceMapUndo faceUV
			)
			
			--modifiying
			polyop.setMapVert Obj mapChannel faceIdx [UV.x, UV.y, 0]			
		)
		
		function putPlyxel faceIdx UV =
		(
			if spnSpread.value == 0 then setFaceUV faceIdx UV 
				else
			(
				local faces = #{faceIdx}
				local verts = #{}
				for j = 1 to spnSpread.value do
				(
					verts = verts + polyOp.getVertsUsingFace theObj faces
					faces = faces + polyOp.getFacesUsingVert theObj verts
				)
				for i in faces do
				(
					setFaceUV i UV
				)
				
			)
			
		)
		
		function unwrap_getPlyxel poly =
		(			
			--local face = polyop.getMapFace theObj 1 poly
			local face = unwrap_getMapFace theObj poly			
			--local vert = polyop.getMapVert theObj 1 face[1]
			local vert = theObj.Unwrap_UVW.getVertexPosition 0 Face[1]
			--return
			(vert)
		)
		
		function getPlyxel faceIdx =
		(				
			--return
			(polyop.getMapVert theObj mapChannel faceIdx)
		)
		
		
		function mirrorPaint =
		(
			local localHit = [0,0,0], localNormal=[0,0,0], worldHit=[0,0,0], worldNormal=[0,0,0]
			thePI.getMirrorHitPointData &localHit &localNormal &worldHit &worldNormal 0
			local p1 = worldHit - worldNormal
			local p2 = worldHit + worldNormal			
			local result = rmIntersect.intersectSegment p2 p1 false			
			if result>0 then
			(				
				local indexedHit = 1
				if result>1 then indexedHit = rmIntersect.getClosestHit()
				local Poly = getPolyFaceByTri theObj (rmIntersect.getHitFace indexedHit) 
								
				putPlyxel Poly curr_UV
			)			
			
		)	

		function SameColor c1 c2  =
		(			
			local d = distance (c1 as point3) (c2 as point3)
			result = d < fill_tolerance			
		)
		
		
		function fillArea iniPoly UV =
		(
			local faces = #{iniPoly}
			local bkColor = UVtoColor (getPlyxel iniPoly)  --storing the background color
			local fillColor = UVtoColor UV 
			putPlyxel iniPoly UV -- setting the color of the first Plyxel
			update theObj
			
			local paintLimit = 0 -- To avoid an unexpected ininite loop...  
			do
			(
			
				local edges = polyOp.getEdgesUsingFace theObj faces			
				local newFaces = polyOp.getFacesUsingEdge theObj edges
				local removeFaces = #{}
				for i in newFaces do
				(
					local c = UVtoColor (getPlyxel i)  --Check the current color of each face
					if (not ( sameColor c bkColor)) or (sameColor c fillColor)  then -- remove if not == bkColor, or == to fillColor
						( 
							removeFaces = removeFaces + #{i} 
						)
					else (putPlyxel i UV) --else paint				   
				)				
				newFaces = newFaces - removeFaces
				--print ( "filling faces " + ((newFaces as array).count as string) )			
				update theObj
				redrawViews()
				faces = newFaces
				paintLimit = paintLimit + 1
			
			) while ( ((faces as array).count > 0 ) and  (paintLimit < 1000 )  )
		)
		
		-- The main thing happens here ------------ PAINT STROKE -------------- ******************************
		function paintStroke = 
		( 	
			local bary = [0,0,0]
			local faceIndex = 1			
			local hitObj = thePI.getHitNode 0
			
			if hitObj != undefined then
			(	
				theObj = hitObj
				thePI.getHitFaceData &bary &faceIndex theObj 0	
				
				if (faceIndex != lastTriFace) and (bary != [0,0,0]) then
				--do not repeat stuff if we are still in the same face
				-- bary != [0,0,0] dirty trick to detect ourside of node strokes
				(				
					local PolyIndex = (getPolyfaceByTri theObj faceIndex)												
					--print bary	
					local shift=false , ctrl=false, alt=false, pressure=0
					thePI.getHitPressureData  &shift &ctrl &alt &pressure 0
					
					if alt then -- PICKING COLOR 
					(
					   curr_UV = getPlyxel polyIndex
					   updateCurrColor()
					) else if btnFill.checked then
					(
						fillArea polyIndex curr_UV					
					) else -- DRAWING COLOR
					(				
						
							putPlyxel polyIndex curr_UV
						
						if thePI.mirrorEnable == true then mirrorPaint()
						update theObj	
					)
					thePI.clearStroke()				
				)
				lastTriFace = faceIndex				
			)
		)
		
		function endStroke = 
		( 
			--thePI.undoAccept()
			print ("faces undo data: " + faceMapUndo.count as string)
			lastTriFace = -1		
			if faceMapUndo.count>0 then btnUndo.enabled = true
		)
		function cancelStroke = 
		( 
				--thePI.undoCancel()
				lastTriFace = -1
		)
		function systemEndPaintSession = 
		( 
			paint3d.checked = false
			lastTriFace = -1
		)
		
		local mpanel_showEndResult = false
		local mpanel_subObjectLevel = 0
		local mpanel_currObject = undefined
		
		function save_modpanel_state =
		(
			max modify mode
			mpanel_showEndResult = showEndResult
			mpanel_subObjectLevel = subObjectLevel
			mpanel_currObject = modPanel.getCurrentObject()
			if mpanel_currObject == theObj.baseObject then
			(
				mpanel_currObject = "base"
			)
		)
		
		function restore_modpanel_state =
		(
			
			--max modify mode			
			if mpanel_currObject == "base" then
			(
				mpanel_currObject = masterObj.baseObject
			)
			modPanel.setCurrentObject mpanel_currObject			
			subObjectLevel = mpanel_subObjectLevel
			showEndResult = mpanel_showEndResult
		)
		
		function prepareObj_for_unwrap obj = 
		(			
			if (obj.modifiers[#Unwrap_UVW] == undefined)  then
			(				
				if chkAutoUV.checked then
				(
					addModifier obj (Unwrap_UVW()) before:(obj.modifiers.count)
				)
			)
			
			if  (obj.modifiers[#Unwrap_UVW] != undefined) then
			(
				
				modPanel.setCurrentObject obj.modifiers[#Unwrap_UVW]
				obj.modifiers[#unwrap_uvw].unwrap5.setShowMapSeams off
			) else
			(
				messageBox "Unwrap_UVW not found in stack"
			)
		)
		
		function prepare_for_polyops obj = 
		(
			local meshFaces = polyop.getNumFaces obj
			local mapFaces = polyop.getNumMapFaces obj mapChannel
			if mapFaces != meshFaces then
			(
				--in case faces difer
				polyop.setNumMapFaces obj mapChannel meshFaces keep:true
				mapFaces = meshFaces
			)
			local mapVerts = polyOp.getNumMapVerts obj mapChannel
			
			-- rebuild map verts for our convenience, one unique vert for each face, each face vert point to that vert
			-- keep one old vert
			local vertsCopy = #()
			vertsCopy.count = mapFaces
			local mapFaceSizes = #()
			for i = 1 to mapFaces do 
			(
				local mapFace = polyop.getMapFace obj mapChannel i
				mapFaceSizes[i] = mapFace.count
				vertsCopy[i] = polyop.getMapVert obj mapChannel mapFace[1]
			)
			polyop.setNumMapVerts obj mapChannel mapFaces keep:true
			for i = 1 to mapFaces do
			(
				polyop.setMapVert obj mapChannel i vertsCopy[i]
				local newFace = #()
				newFace.count = mapFaceSizes[i]
				for j = 1 to newFace.count do
				(
					newFace[j] = i
				)
				polyop.setMapFace obj mapChannel i newFace
			)
			update obj
		)
		
		function prepareObj obj = 
		(
			--modPanel.setCurrentObject  obj.baseObject			
			prepare_for_polyops obj
		)
			
		
			
		
		function startPainting3D =
		(
			if  thePI.InPaintMode() or theObj == undefined then 
			(
				thePI.endPaintSession()
				paint3D.checked = false
			) else
			(				
				updateCurrColor()				
				--lblInfo.visible = false
				paint3D.checked = true
				thePI.pointGatherEnable = false
				thePI.initializeNodes 0 theObjects
				thePI.offMeshHitType =2
				thePI.minSize = 0.1
		        thePI.maxSize = 2
				thePI.drawring = true
				thePI.drawTrace = false
				thePI.drawNormal = true
				thePI.normalScale = 5
				thePI.pressureEnable = true
				thePI.mirrorEnable = chkMirror.checked
				if chkMirror.checked then
				(
					rmIntersect.free
					rmIntersect.nodeList = #()
					rmIntersect.initialize 10
					rmIntersect.addNode( theObj )
					rmIntersect.buildGrid()
				)
				thePI.mirrorAxis = 1
				thePI.scriptFunctions startStroke paintStroke endStroke cancelStroke SystemEndPaintSession
				thePI.startPaintSession()
			)			
		)
		
		function endPainting3D =
		(
			thePI.endPaintSession()
			if paint3D.checked then paint3D.checked = false
		)
		
		function findClosestColor thisColor fromBitmap = 
		(
			thisColor = thisColor as point3
			found = [0,0]
			otherColor = (color 0 0 0)
			min_dist = distance [0,0,0] [255,255,255]
			for y = 0 to (fromBitmap.height-1) do
			(
				local pixels = getPixels fromBitmap [0, y] fromBitmap.width linear:false
				for x = 0 to (pixels.count-1) do
				(
					local dist = distance (pixels[x+1] as point3) thisColor
					if dist<min_dist then 
					(
						min_dist = dist
						found = [x, y]
						otherColor = pixels[x+1]
					)
				)
			)
			--return
			( #( found, otherColor) )
		)
		
		--converts bitmap to 2D table
		function getPixelTable fromBitmap =
		(
			pixelTable = #()
			pixelTable.count = fromBitmap.height
			for y = 0 to (fromBitmap.height-1) do
			(
				pixelTable[y+1] = getPixels fromBitmap [0, y] fromBitmap.width linear:false
			)
			--return
			(pixelTable)
		)
		
		--convert bitmap to RLE compressed data
		function getPixelData fromBitmap =
		(			
			local c = color 0 0 0
			local last_c = color 0 0 -1
			local pixelData = #()
			for y = 0 to (fromBitmap.height-1) do
			(
				local pixels = getPixels fromBitmap [0,y] fromBitmap.width linear:false
				for x = 0 to (fromBitmap.width-1) do
				(
					c = pixels[x+1]
					if c != last_c then 
					(
						append pixelData #(c, [x,y])
					)
					last_c = c
				)
			)
			--return
			(pixelData)
		)
		
		--This one use what getPixelTable returns
		function findClosestColorTable thisColor fromPixelTable = 
		(
			thisColor = thisColor as point3
			local found = [0,0]
			local otherColor = (color 0 0 0)
			local min_dist = distance [0,0,0] [255,255,255]
			local dist = 0.0
			for y = 0 to (fromPixelTable.count-1) do
			(
				local pixels = fromPixelTable[y+1]
				for x = 0 to (pixels.count-1) do
				(
					dist = distance (pixels[x+1] as point3) thisColor
					if dist<min_dist then 
					(
						min_dist = dist
						found = [x, y]
						otherColor = pixels[x+1]
						if dist < 0.01 then return #( found, otherColor)
					)
				)
			)
			--return
			( #( found, otherColor) )
		)
		
       function findClosestColorData thisColor fromPixelData = 
		(
			thisColor = thisColor as point3
			local found = [0,0]
			local otherColor = (color 0 0 0)
			local min_dist = distance [0,0,0] [255,255,255]
			local dist = 0.0
			local pixelData
			for pixelData in fromPixelData do
			(					
					dist = distance (pixelData[1] as point3) thisColor
					if dist<min_dist then 
					(
						min_dist = dist
						found = pixelData[2]
						otherColor = pixelData[1]
						if dist < 0.01 then return #( found, otherColor)
					)
				
			)
			--return
			( #( found, otherColor) )
		)
		
		
		--- big deal, find closest similar colors from incoming map to remap all UVs
		function remapTo newBitmap = 
		(
			if theObj != undefined then
			(				
				local t1 = timeStamp()
				--local pixelTable = getPixelTable newBitmap				
				local pixelData 
				local findFunc 
				local diffMap = findDiffuseMap theObj
				if chkOptimizeBitmap.checked then	
				(
					pixelData = getPixelData newBitmap
					findFunc = findClosestColorData
				) else 
				( 
					pixelData = getPixeltable newBitmap
					findFunc = findClosestColorTable
				)
				format "Preparing table, elapsed time: %\n" (timeStamp()-t1)
				t1 = timeStamp()
				for poly=1 to (polyOp.getNumFaces theObj) do
				(					
					local uv = (getPlyxel poly)
					local c1 = UVgetPixel uv diffMap gamma:false
					--local result = findClosestColor c1 newBitmap
					--local result = findClosestColorTable c1 pixelTable
					local result = findFunc c1 pixelData
					local new_uv = [0,0]
					new_uv.x = (( result[1].x + 0.5 ) as float) / (newBitmap.width)
					new_uv.y = 1.0 - ( (( result[1].y + 0.5 ) as float) / (newBitmap.height) )
					--format "% - % : % - %\n" uv c1 new_uv result[2]
					--setAllUVto poly new_uv undoOn:false
					setFaceUV poly new_uv undoOn:false
					pbar.value =  (100*poly/(polyOp.getNumFaces theObj))
				)
				format "Elapsed time: %\n" (timeStamp() - t1)
				update theObj				
				pbar.value = 0
			)
		)
		
		--return array with Enabled/Disabled modifiers states.
		--while disabling all
		function saveMod_states obj disableThem:true =
		(
			local states = #()
			states.count = obj.modifiers.count
			for i=1 to states.count do
			(
				states[i] = obj.modifiers[i].enabled
				obj.modifiers[i].enabled = false
			)
			--return
			(states)
		)
	
		
		------------================== UI EVENTS HANDLERS =====================--------------------------------
		
		on paint3D changed state do 
		( 
			if paint3D.checked == true then
			(
				local isOk = 0
				local objList = #()
				theObjects = #() --reseting
				mod_states = #()
				
				if ($==undefined) then 
				(
					messageBox "Object not Selected" title:"Warning" beep:true					
				) else
				(
					if (classof $) == objectSet then
					(
						objList = $ as array
					) else
					(
						objList = #($)
					)
					for Obj in objList do
					(
						theObj = obj
						if ((isKindOf theObj Editable_poly) or (isKindOf theObj PolyMeshObject)) or ((classof theObj.baseObject) == Editable_poly) then
						(
							--TODO: Maybe .baseObject is better than PolyMeshObject test
							if theObj.material != undefined then
							(
								local diffMap = findDiffuseMap(theObj)								
								
								if diffMap != undefined then
								( 						
									if isOk == 0 then
									(
										masterObj = theObj
										save_modpanel_state()
										updateColorBitmap(diffMap)
										updateCurrColor()
									)									
									append theObjects theObj
									append mod_states (saveMod_states theObj) 
									prepareObj theObj
									isOk = isOk + 1
									
								) else messageBox  "Need material applied with diffuseMap bitmap"
							) else messageBox "Need material applied with diffuseMap bitmap"
						) else 
						( 
							messageBox "Object need to be  Editable Poly object." title:"Warning" beep:true						
						)
					)
				)
				
				if isOk > 0 then
				(
					paint3D.checked = true
					theObj = masterObj
					startPainting3D()
				) else paint3D.checked = false
				
			) else
			(
				endPainting3D()
				if false then --chkAutoUV_end.checked then
				(	
					for obj in theObjects do
					(
						local mods = Obj.modifiers
						local m = mods[#Unwrap_UVW]
						local idx = findItem mods m				
						print "collapsing"
						maxOps.CollapseNodeTo Obj idx off
					)
				)
				--restoring stacks and modify panel
				for i=1 to theObjects.count do
				(
					local states = mod_states[i]
					for j = 1 to states.count do
					(
						theObjects[i].modifiers[j].enabled = states[j]
					)
				)
				if theObjects.count==1 then restore_modpanel_state()
			)
			enable_tools (paint3D.checked == true)
		)
		

		on bmpColorPal lbuttondown pos flags do
		(
			if (pos.y <= bmpSize) then
			(
			   --	get the position of mouse clicks over the Texture Image and convert it to UV coordinates.
				curr_UV.x =  pos.x / bmpSize
				curr_UV.y = 1 - ( pos.y / bmpSize )				
				
				updateCurrColor()
				
				
			)			
		)
		
		on roll_polyPaint close do
		(	
			local p = getDialogPos roll_PolyPaint
			set_ini "dialogPos" (p as string)
		)
		
		on roll_polyPaint open do
		(
			local s = get_ini "dialogPos"
			p = eval s
			if (classof p ) == point2 then
			(
				setDialogPos roll_PolyPaint p
			)
			enable_tools false
		)
		
		on btnFullRepaint pressed do
		(
			if theObj != undefined then
			(
				if chkSelectedOnly.checked then
				(
					-- TODO: make this work without unwrap and get selected faces from polyop
					--local sp = theObj.unwrap_UVW.getSelectedPolygons()
					local sp = polyop.getFaceSelection theObj
					for i in sp do 
					(
						putPlyxel i curr_UV
					)
				) else
				(
					for i=1 to (polyOp.getNumFaces theObj) do
					(
						putPlyxel i curr_UV
					)
				)
				update theObj
				redrawViews()
			)
		)
		
		on chkMirror changed state do
		(
			    thePI.mirrorEnable = chkMirror.checked
				if chkMirror.checked then
				(
					rmIntersect.free
					rmIntersect.nodeList = #()
					rmIntersect.initialize 10
					rmIntersect.addNode( theObj )
					rmIntersect.buildGrid()
				)
		)
		
		on btnUndo pressed do
		(		
			local obj = undefined
			local prevObj = undefined
			for i=faceMapUndo.count to 1 by -1 do
			(
				local faceUV = faceMapUndo[i]				
				obj = faceUV[3]
				local faceIdx = faceUV[1]
				local UVpoint = faceUV[2]
				--local faceMap = polyop.getMapFace theObj 1 faceUV[1] --get the vertex indices; may have changed				
/* 				if obj != prevObj then modPanel.setCurrentObject obj.modifiers[#Unwrap_UVW]
				local faceMap = unwrap_getMapFace obj faceIdx
				for j=1 to faceMap.count do
				(					
					obj.Unwrap_UVW.setFaceVertex UVpoint faceIdx j false				
				) */
				polyop.setMapVert obj mapChannel faceIdx UVpoint
				prevObj = obj
			)
			for obj in theObjects do update obj
			redrawViews() 
			--more undo levels?
			if undoLevels.count > 0 then
			(
				faceMapUndo = undoLevels[ undoLevels.count ] 
				deleteItem undoLevels undoLevels.count
			) else  
			(
				faceMapUndo = #()
				btnUndo.enabled = false
			)
		)
        
        on btnUV_copy pressed do
        (
           local ss = (stringStream "") 
           print spnU.value to:ss
           print spnV.value to:ss
           setclipboardText (ss as string)
        )
		
        on btnUV_paste pressed do
        (
            local s = getclipboardText()
            if s!=undefined then
            (
                local ss = (stringStream s)
                seek ss 0
                spnU.value = (readValue ss)
                spnV.value = (readValue ss)                
            )
        )
        
        on btnUV_set pressed do             
        (
            curr_UV.x =  spnU.value
			curr_UV.y = spnV.value
			updateCurrColor() 
        )
		
		on mapBtnSwapMap picked textmap do 
		( 
			if (classof mapBtnSwapMap.map) ==Bitmaptexture then 
			(
					mapBtnSwapMap.text = textmap.name 
			) else
			(
				messageBox "Map needs to be Bitmaptexture class"				
				mapBtnSwapMap.map = undefined
				
			)
		)
		
		on btnSwapMap pressed do
		(
			if theObj != undefined then
			(
				local map = mapBtnSwapmap.map
				if map != undefined then
				(
					if (classof map) ==Bitmaptexture then 
					(
						remapTo map.bitmap
						if not chkNoReplace.checked then 	replaceDiffuseMap theObj.material map
						redrawViews()
						updateColorBitmap map						
					) else
					(
						messageBox "Map needs to be Bitmaptexture class"
					)
				)
			)
		)
	)

	--// has to be with CreateDialog in order to get the lButtonDown event with mouse position

    
	createdialog roll_PolyPaint bmpSize (bmpSize + 420 )        
)