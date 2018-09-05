-- Poly  Paint, a tool to paint polygos with a flat color from texture, setting all vertices of a UV face to a single point in texture, giving always a flat color
-- By Denys Almaral - 2018

-- Updates

-- implmented Undo levels
-- added Flood Fill algorithm
-- Added Mirror functionality
-- Full repaint the whole object with selected color 
-- 2018-08-25 v1.0 basic functionality 

macroScript PolyPaint buttonText:"Poly Paint" category:"pX Tools" tooltip:"Poly UV Painter"
(
	local bary = [0,0,0]
	local faceIndex = 1
	local lastTriFace = -1
	local theObj = undefined
	local bmpSize = 360
	local curr_UV = [0.5,0.5,0]
	local currStrokeNum = 0
	local thePI = thePainterInterface
	local rmIntersect = RayMeshGridIntersect()
	local faceMapUndo = #()
	local undoLevels = #()
	local undoLevelsMax = 5
	
	 
	local tempBitmap = bitmap bmpSize bmpSize color:(color 40 40 40)
	local colorBitmap = bitmap 50 50 
	
	rollout roll_polyPaint "pX Poly Paint" 
	(
		imgTag bmpColorPal bitmap:tempBitmap pos:[0,0] style:#bmp_stretch transparent:(color 68 68 68)
		label lblInfo "Select object and press Start Painting Tool" pos:[10,10]
		checkButton paint3D "Start Paint Tool" pos:[18, bmpSize + 10 ] width:126 height:55		
		button btnFullRepaint "Full Repaint" pos:[28,bmpSize + 20 + 55]  width:100 height:40
		checkbox chkSelectedOnly "Selected faces only" pos:[28, bmpSize + 30 + 90] checked:false
		imgTag imgCurrColor bitmap:colorBitmap pos:[150, bmpSize + 10] width:50 height:50
		label lbl3dPickColor "Alt = 3D color picker" pos:[210, bmpSize + 10] 
		checkbox chkMirror "Mirror Paint" pos:[210,bmpSize + 30] checked:false
		spinner spnSpread "Spread" range:[0,10,0] type:#integer pos:[240, bmpSize + 50] width:50
		checkButton btnFill "Fill Area" pos:[210, bmpSize + 80] width:90 height:30 enabled:false
		button btnUndo "Undo" pos:[210, bmpSize + 120] width:90 height:30 
		
		function updateColorBitmap = 
		(
			copy $.material.diffuseMap.bitmap tempBitmap
			bmpColorPal.bitmap = tempBitmap
		)
		
		function UVtoColor UV =
		(
			local w = tempBitmap.width
			local h = tempBitmap.height
			(getPixels tempBitmap [ UV.x * w ,  (1-UV.y) * h ] 1 linear:true )[1]
		)
		
		
		function updateCurrColor =
		(			
			copy $.material.diffuseMap.bitmap tempBitmap	
						
			local p = UVtoColor curr_UV 									
			if p != undefined then
			(
				free colorBitmap
				colorBitmap = bitmap 50 50 color:p 
				imgCurrColor.bitmap = colorBitmap
				
				-- draw pixel marker
				xx = curr_UV.x * tempBitmap.width
				yy = (1-curr_UV.y) * tempBitmap.height
				setPixels tempBitmap [xx+1, yy] #(color 255 255 255)
				setPixels tempBitmap [xx-1, yy] #(color 255 255 255)
				setPixels tempBitmap [xx, yy+1] #(color 0 0 0)
				setPixels tempBitmap [xx, yy-1] #(color 0 0 0)
				bmpColorPal.bitmap = tempBitmap
			)
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
		
		function setAllUVto poly UV =
		(
			local mapFace = polyop.getMapFace theObj 1 poly
			
			-- UNDO DATA			
			local faceUV = #()
			faceUV[1] = poly 			
			--saving, only the first vertex			
			faceUV[2] = polyop.getMapVert theObj 1 mapFace[1]			
			append faceMapUndo faceUV
			
			--modifiying
			for i=1 to mapFace.count do
			(
				theObj.Unwrap_UVW.setFaceVertex [ UV.x, UV.y,0] poly i false
			)	
		)
		
		function putPlyxel poly UV =
		(
			if spnSpread.value == 0 then setAllUVto poly UV 
				else
			(
				local faces = #{poly}
				local verts = #{}
				for j = 1 to spnSpread.value do
				(
					verts = verts + polyOp.getVertsUsingFace theObj faces
					faces = faces + polyOp.getFacesUsingVert theObj verts
				)
				for i in faces do
				(
					setAllUVto i UV
				)
				
			)
			
		)
		
		function getPlyxel poly =
		(			
			local face = polyop.getMapFace theObj 1 poly
			local vert = polyop.getMapVert theObj 1 face[1]
			vert
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
			result = d < 5			
		)
		
		
		function fillArea iniPoly UV =
		(
			local faces = #{iniPoly}
			local bkColor = UVtoColor (getPlyxel iniPoly) --storing the background color
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
				local c = UVtoColor (getPlyxel i) --Check the current color of each face
				if (not ( sameColor c bkColor)) or (sameColor c fillColor)  then -- remove if not == bkColor, or == to fillColor
					( 
						removeFaces = removeFaces + #{i} 
					)
				else (putPlyxel i UV) --else paint				   
			)				
			newFaces = newFaces - removeFaces
			print ( "filling faces " + ((newFaces as array).count as string) )			
			update theObj
			redrawViews()
			faces = newFaces
			paintLimit = paintLimit + 1
			
			) while ( ((faces as array).count > 0 ) and  (paintLimit < 1000 )  )
		)
		
		-- The main thing accours here ------------ PAINT STROKE -------------- ******************************
		function paintStroke = 
		( 			
			
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
		
		function endStroke = 
			( 
				--thePI.undoAccept()
				print ("faces undo data: " + faceMapUndo.count as string)
				lastTriFace = -1		
				if faceMapUndo.count>0 then btnUndo.enabled = true
			)
		function cancelStroke = ( 
				--thePI.undoCancel()
				lastTriFace = -1
			)
		function systemEndPaintSession = ( 
			paint3d.checked = false
			lastTriFace = -1
			
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
				lblInfo.visible = false
				paint3D.checked = true
				thePI.pointGatherEnable = false
				thePI.initializeNodes 0 # (theObj)
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
	
		
		-- EVENTS HANDLERS ***************************************
		
		on paint3D changed state do 
		( 
			if paint3D.checked == true then
			(
				local isOk = false
				theObj = $
				if (theObj==undefined) then 
				(
					messageBox "Object not Selected" title:"Warning" beep:true					
				) else
				(
					if ((isKindOf theObj Editable_poly) or (isKindOf theObj PolyMeshObject)) and (theObj.modifiers[#unwrap_UVW]!=undefined) then
					(
						if theObj.material != undefined then
						(
							if theObj.material.diffuseMap != undefined then
							( 								
								updateColorBitmap()
								updateCurrColor()
								startPainting3D() 
								isOk = true
								
							) else messageBox  "Need material applied with diffuseMap bitmap"
						) else messageBox "Need material applied with diffuseMap bitmap"
					) else 
					( 
						messageBox "Object need to be  Editable Poly object with Unwrap UVW applied." title:"Warning" beep:true						
					)
				)
				paint3D.checked = isOk
			) else
			(
				endPainting3D()				
			)
			btnFill.enabled = paint3D.checked
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
				endPainting3D()
		)
		
		on btnFullRepaint pressed do
		(
			if theObj != undefined then
			(
				if chkSelectedOnly.checked then
				(
					sp = theObj.unwrap_UVW.getSelectedPolygons()
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
			for i=faceMapUndo.count to 1 by -1 do
			(
				local faceUV = faceMapUndo[i]
				local faceMap = polyop.getMapFace theObj 1 faceUV[1] --get the vertex indices; may have changed				
				for j=1 to faceMap.count do
				(					
					theObj.Unwrap_UVW.setFaceVertex faceUV[2] faceUV[1] j false				
				)
			)
			update theObj
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
		
	)

	--// has to be with CreateDialog in order to get the lButtonDown event with mouse position
	createdialog roll_PolyPaint bmpSize (bmpSize + 200 )
	
)