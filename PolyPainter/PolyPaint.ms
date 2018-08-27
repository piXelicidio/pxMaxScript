-- Poly  Paint, a tool to paint polygos with a flat color from texture, setting all vertices of a UV face to a single point in texture, giving always a flat color
-- By Denys Almaral - 2018

-- Updates

-- Added Mirror functionality
-- Full repaint the whole object with selected color 
-- 2018-08-25 v1.0 basic functionality 

(


	local bary = [0,0,0]
	local faceIndex = 1
	local lastTriFace = -1
	local theObj = undefined
	local bmpSize = 360
	local curr_UV = [0,0,0]
	local thePI = thePainterInterface
	local rmIntersect = RayMeshGridIntersect()
	 
	local tempBitmap = bitmap bmpSize bmpSize color:white
	local colorBitmap = bitmap 50 50 
	
	rollout roll_polyPaint "Poly Paint" 
	(
		imgTag bmpColorPal bitmap:tempBitmap pos:[0,0] style:#bmp_stretch
		checkButton paint3D "Start Paint Tool" pos:[18, bmpSize + 10 ] width:126 height:55		
		button btnFullRepaint "Full Repaint" pos:[28,bmpSize + 20 + 55]  width:100 height:40
		checkbox chkSelectedOnly "Selected faces only" pos:[145, bmpSize + 30 + 55] checked:false
		imgTag imgCurrColor bitmap:colorBitmap pos:[150, bmpSize + 10] width:50 height:50
		label lbl3dPickColor "Alt = 3D color picker" pos:[210, bmpSize + 10] 
		checkbox chkMirror "Mirror Paint" pos:[210,bmpSize + 30] checked:true
		
		function updateColorBitmap = 
		(
			--copy $.material.diffuseMap.bitmap tempBitmap
			bmpColorPal.bitmap = theObj.material.diffuseMap.bitmap --tempBitmap
		)
		
		function updateCurrColor =
		(
			local w = bmpColorPal.bitmap.width
			local h = bmpColorPal.bitmap.height
			local p = getPixels bmpColorPal.bitmap [ curr_UV.x * w ,  (1-curr_UV.y) * h ] 1 			
			p = p[1]
			print p
			if p != undefined then
			(
				free colorBitmap
				colorBitmap = bitmap 50 50 color:p 
				imgCurrColor.bitmap = colorBitmap
			)
		)
		
		function startStroke = ( thePI.undoStart() )
		
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
		
		function putPlyxel poly UV =
		(
			local vnum = (polyop.getMapFace theObj 1 poly).count
			for i=1 to vnum do
			(
				theObj.Unwrap_UVW.setFaceVertex [ UV.x, UV.y,0] poly i false
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
			local result = rmIntersect.intersectSegment p1 p2 true
			print "mirror"			
			if result>0 then
			(
				local Poly = getPolyFaceByTri theObj (rmIntersect.getHitFace 1) 
				putPlyxel Poly curr_UV
			)
			
			
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
				print PolyIndex
				--print bary	
				local shift=false , ctrl=false, alt=false, pressure=0
				thePI.getHitPressureData  &shift &ctrl &alt &pressure 0
				
				if alt then -- PICKING COLOR 
				(
				   curr_UV = getPlyxel polyIndex
				   updateCurrColor()
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
		
		function endStroke = ( 
			thePI.undoAccept()
			lastTriFace = -1
			print "endStroke"
			)
		function cancelStroke = ( 
			thePI.undoCancel()
			lastTriFace = -1
			)
		function systemEndPaintSession = ( 
			paint3d.checked = false
			lastTriFace = -1
			print "paint end"
			)
		
		function startPainting3D =
		(
			if  thePI.InPaintMode() or theObj == undefined then 
			(
				thePI.endPaintSession()
				paint3D.checked = false
			) else
			(
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
								print "adelante"
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
		)
		
		on bmpColorPal lbuttondown pos flags do
		(
			if (pos.y <= bmpSize) then
			(
			   --	get the position of mouse clicks over the window and convert it to UV coordinates.
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
		
	)

	--// has to be with CreateDialog in order to get the lButtonDown event with mouse position
	createdialog roll_PolyPaint bmpSize (bmpSize + 150 )
	
)