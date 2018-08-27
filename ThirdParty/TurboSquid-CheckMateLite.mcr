macroScript CheckMateLite category:"TurboSquid"
(
	-----------------------------------------------------------------------
	--CHECKMATE 
	--Geometry Checker Tools for CheckMate Lite specification
	--v0.2.1 - 2011/02/04
	--Copyright 2010 - 2011 by TurboSquid, Inc.
	--Code by Borislav "Bobo" Petrov - bo_petrov@yahoo.de
	-----------------------------------------------------------------------
	-- 2011/05/15 modified by Jacob Bilyalov
	--v0.2.2 : 2011/05/17,  added deleteAllTurboSmooth() and deleteAllMeshSmooth() at the beginning of [UPDATE]
	--v0.2.3 : 2011/05/18, added summary report
	--v0.2.4 : 2011/05/19, made summary report look like maya one
	--v0.2.5 : 2011/05/19, added reference to detailed report, put ngons, quad, and tris on different lines
	-----------------------------------------------------------------------
	-- 2011/05/20 modified by James Capps
	--v0.2.6 : 2011/05/20, -- Removed Objects with Parents and Objects with Children from Summary 
	--v0.2.7 : 2011/05/20, -- Removed Groups readout and added it as a "No Script Output" readout and changed visual style/fonts
	--v0.2.8 : 2011/05/20, -- Cleaned up fonts
	-----------------------------------------------------------------------
	--v0.2.9 : 2011/05/25, JB, removed variables declaration that are no longer used
	--v0.2.10 : 2011/05/25, JB, added check for and delete spacewrap modifiers commands
	--v0.2.11 : 2011/05/26, JB, added setVRaySilentMode() before loadMaxFile
	--v0.2.12 : 2011/11/29, JB, added deleteAllTurboSmooth() and deleteAllMeshSmooth() in GeometryCheckerTools_Rollout.() to remove smoothing modifiers in batch mode in the same way as we do for single file in [UPDATE]
	--v0.2.13 : 2012/01/03, MG, changed XView to xView 
		
	--[ mod 2011/05/15
	-- needed more precision for xView Tolerance Settings spinners
	preferences.spinnerPrecision = 4
	--] end mod

	global GeometryCheckerTools_Functions
	global GeometryCheckerTools_Settings
	global GeometryCheckerTools_RCMenus
	global GeometryCheckerTools_mainmenu
	global GeometryCheckerTools_Rollout
	global GeometryCheckerTools_Totals
	
	local theSize = [1396, 900]
		
-----------------------------------------------------
--Global struct instance containing options
-----------------------------------------------------
	struct GeometryCheckerTools_SettingsStruct 
	(
		Version = "v0.2.13 : 2012/01/03 @1:50 pm",
		SynchronizeSelection = true,
		ListViewVisibility = #(true,true,true),
		ShowGeometry = true,
		ShowShapes = true,
		ShowHelpers = true,
		ShowLights = true,
		ShowCameras = true,
		ShowSpaceWarps = true,
		SortAlphabetically = false,
		SkipPassedObjects = false,
		IncludeViewportBitmaps = true,
		IncludeCameraBitmaps = true,
		RecursiveScanFolders = true,
		OverlappingFacesTolerance = 0.0001,
		OverlappingVertsTolerance = 0.0001,
		IncludeFaceOrientationScreenshots = false,
		FaceOrientationScreenshotsCount = 5
	)
	GeometryCheckerTools_Settings = GeometryCheckerTools_SettingsStruct()
	
	--Global struct instance containing the repair menus
	struct GeometryCheckerTools_RCMenusStruct
	(
		AssignMaterial,
		AcquireMaterial,
		NonQuadPoly,
		EnableOverlapVxViewChecker,
		EnableOverlapFxViewChecker,
		EnableOverlapUVFacesxViewChecker,
		EnableIsoVertsxViewChecker,
		EnableTVertsxViewChecker
	)
	GeometryCheckerTools_RCMenus = GeometryCheckerTools_RCMenusStruct()
	
	global setxViewTolerance_Dialog
	rollout setxViewTolerance_Dialog "xView Tolerance Settings"
	(
		spinner spn_xViewOverlapVertsTolerance "Overlapping Verts:" range:[0.0,10.0,GeometryCheckerTools_Settings.OverlappingVertsTolerance] scale:0.0001 fieldwidth:45
		spinner spn_xViewOverlapFacesTolerance "Overlapping Faces:" range:[0.0,10.0,GeometryCheckerTools_Settings.OverlappingFacesTolerance] scale:0.0001 fieldwidth:45
		
		on spn_xViewOverlapVertsTolerance  changed val do 
		(
			GeometryCheckerTools_Settings.OverlappingVertsTolerance = val
			setIniSetting (GetDir #plugcfg + "\\GeometryCheckerTools.ini") "xView" "OverlappingVertsTolerance" (val as string)
		)
		on spn_xViewOverlapFacesTolerance  changed val do 
		(
			GeometryCheckerTools_Settings.OverlappingFacesTolerance = val
			setIniSetting (GetDir #plugcfg + "\\GeometryCheckerTools.ini") "xView" "OverlappingFacesTolerance" (val as string)
		)
			
		button btn_close "CLOSE" width:200 height:30
		on btn_close pressed do destroyDialog setxViewTolerance_Dialog
	)
	
	
	rcmenu AssignMaterial
	(
		menuItem mnu_assignMaterialFromClipboard "Assign Material From Clipboard" enabled:(GeometryCheckerTools_Rollout.MaterialClipboard!=undefined)
		separator sep_10
		menuItem mnu_assignDefaultMaterial "Assign Default Standard Material"
		menuItem mnu_assignMaterialSlotOne "Assign Material From MatEditor Slot 1"
		
		on mnu_assignDefaultMaterial picked do 
		(
			try
			(
				local theObject = GeometryCheckerTools_Rollout.allObjects[GeometryCheckerTools_Rollout.theSelection+1]
				with undo "Assign Standard Material" on 
				(
					theObject.material = standard name:("MAT_"+theObject.name)
				)
				GeometryCheckerTools_Rollout.updateSpecificRecords #material
			)catch()
		)
		on mnu_assignMaterialSlotOne picked do
		(
			try
			(
				with undo "Assign Slot 1 Material" on 
				(
					GeometryCheckerTools_Rollout.allObjects[GeometryCheckerTools_Rollout.theSelection+1].material = meditMaterials[1]
				)
				GeometryCheckerTools_Rollout.updateSpecificRecords #material
			)catch()
		)
		on mnu_assignMaterialFromClipboard picked do
		(
			try
			(
				with undo "Assign Clipboard Material" on 
				(
					GeometryCheckerTools_Rollout.allObjects[GeometryCheckerTools_Rollout.theSelection+1].material = GeometryCheckerTools_Rollout.MaterialClipboard
				)
				GeometryCheckerTools_Rollout.updateSpecificRecords #material
			)catch()		
		)
	)
	GeometryCheckerTools_RCMenus.AssignMaterial = AssignMaterial

	rcmenu AcquireMaterial
	(
		menuItem mnu_getMaterialIntoClipboard "Store Material In Clipboard"
		separator sep_10
		menuItem mnu_getMaterialIntoMeditSlowOne "Put Material To MatEditor Slot 1"
		on mnu_getMaterialIntoClipboard picked do
		(
			local theObject = GeometryCheckerTools_Rollout.allObjects[GeometryCheckerTools_Rollout.theSelection+1]
			GeometryCheckerTools_Rollout.MaterialClipboard = theObject.material
		)
		on mnu_getMaterialIntoMeditSlowOne picked do
		(
			local theObject = GeometryCheckerTools_Rollout.allObjects[GeometryCheckerTools_Rollout.theSelection+1]
			meditMaterials[1] = theObject.material
		)
	)
	GeometryCheckerTools_RCMenus.AcquireMaterial = AcquireMaterial
	
	rcmenu NonQuadPoly 
	(
		fn isEPOly =
		(
			local theObject = GeometryCheckerTools_Rollout.allObjects[GeometryCheckerTools_Rollout.theSelection+1]
			classof theObject == Editable_Poly 
		)
		
		menuItem mnu_selectTriangles "Select Triangle Faces" filter:isEPOly 
		menuItem mnu_selectQuads "Select Quad Polygons" filter:isEPOly 
		menuItem mnu_selectNonQuads "Select Non-Quad Polygons (5+ Sides)" filter:isEPOly 
		
		separator sep_10 filter:isEPOly 
		menuItem mnu_addQuadifyModifier "Add [Quadify] Modifier"
		menuItem mnu_addTurnToPolyModifier "Add [Turn To Poly] Modifier"
		
		separator sep_20
		menuItem mnu_collapseToEPoly "Collapse To Editable Poly"

		on mnu_selectTriangles picked do
		(
			local theObject = GeometryCheckerTools_Rollout.allObjects[GeometryCheckerTools_Rollout.theSelection+1]
			if classof theObject == Editable_Poly then
			(
				theFaceBitarray = #{}
				for f = 1 to polyOp.GetNumFaces theObject where polyOp.getFaceDeg theObject f < 4 do theFaceBitarray[f] = true
				polyOp.setFaceSelection theObject theFaceBitarray
				max modify mode
				subObjectLevel=4
			)
		)	
		
		on mnu_selectQuads picked do
		(
			local theObject = GeometryCheckerTools_Rollout.allObjects[GeometryCheckerTools_Rollout.theSelection+1]
			if classof theObject == Editable_Poly then
			(
				theFaceBitarray = #{}
				for f = 1 to polyOp.GetNumFaces theObject where polyOp.getFaceDeg theObject f == 4 do theFaceBitarray[f] = true
				polyOp.setFaceSelection theObject theFaceBitarray
				max modify mode
				subObjectLevel=4
			)
		)		
		
		on mnu_selectNonQuads picked do
		(
			local theObject = GeometryCheckerTools_Rollout.allObjects[GeometryCheckerTools_Rollout.theSelection+1]
			if classof theObject == Editable_Poly then
			(
				theFaceBitarray = #{}
				for f = 1 to polyOp.GetNumFaces theObject where polyOp.getFaceDeg theObject f > 4 do theFaceBitarray[f] = true
				polyOp.setFaceSelection theObject theFaceBitarray
				max modify mode
				subObjectLevel=4
			)
		)

		on mnu_addQuadifyModifier picked do
		(
			local theObject = GeometryCheckerTools_Rollout.allObjects[GeometryCheckerTools_Rollout.theSelection+1]
			local theMod = Quadify_Mesh() 
			addModifier theObject theMod
			GeometryCheckerTools_Rollout.updateSpecificRecords #ngons
		)	
		on mnu_addTurnToPolyModifier picked do
		(
			local theObject = GeometryCheckerTools_Rollout.allObjects[GeometryCheckerTools_Rollout.theSelection+1]
			local theMod = Turn_To_Poly() 
			theMod.removeMidEdgeVertices = true
			theMod.limitPolySize = true
			theMod.maxPolySize = 4
			addModifier theObject theMod
			GeometryCheckerTools_Rollout.updateSpecificRecords #ngons
		)			
		on mnu_collapseToEPoly picked do
		(
			local theObject = GeometryCheckerTools_Rollout.allObjects[GeometryCheckerTools_Rollout.theSelection+1]
			convertTo theObject Editable_Poly
			GeometryCheckerTools_Rollout.updateSpecificRecords #ngons
		)
	)
	GeometryCheckerTools_RCMenus.NonQuadPoly =NonQuadPoly
	
	rcmenu EnableOverlapVxViewChecker 
	(
		menuItem mnu_enableChecker "Enable [Overlapping Vertices] xView Checker..."
		on mnu_enableChecker picked do 
		(
			GeometryCheckerTools_Functions.enablexViewChecker "Overlapping Vertices"
		)
	)
	GeometryCheckerTools_RCMenus.EnableOverlapVxViewChecker = EnableOverlapVxViewChecker
	
	rcmenu EnableOverlapFxViewChecker
	(
		menuItem mnu_enableChecker "Enable [Overlapping Faces] xView Checker..."
		on mnu_enableChecker picked do 
		(
			GeometryCheckerTools_Functions.enablexViewChecker "Overlapping Faces"
		)
	)
	GeometryCheckerTools_RCMenus.EnableOverlapFxViewChecker = EnableOverlapFxViewChecker
	
	rcmenu EnableOverlapUVFacesxViewChecker
	(
		menuItem mnu_enableChecker "Enable [UVW Faces] xView Checker..."
		on mnu_enableChecker picked do 
		(
			GeometryCheckerTools_Functions.enablexViewChecker "Overlapped UVW Faces"
		)		
	)
	GeometryCheckerTools_RCMenus.EnableOverlapUVFacesxViewChecker = EnableOverlapUVFacesxViewChecker
	
	rcmenu EnableIsoVertsxViewChecker
	(
		menuItem mnu_enableChecker "Enable [Isolated Vertices] xView Checker..."
		on mnu_enableChecker picked do 
		(
			GeometryCheckerTools_Functions.enablexViewChecker "Isolated Vertices"
		)			
	)
	GeometryCheckerTools_RCMenus.EnableIsoVertsxViewChecker = EnableIsoVertsxViewChecker
	
	rcmenu EnableTVertsxViewChecker
	(
		menuItem mnu_enableChecker "Enable [T-Vertices] xView Checker..."
		on mnu_enableChecker picked do 
		(
			GeometryCheckerTools_Functions.enablexViewChecker "T-Vertices"
		)			
	)
	GeometryCheckerTools_RCMenus.EnableTVertsxViewChecker = EnableTVertsxViewChecker
	
	--Global struct containing Geometry Checker functions
	struct GeometryCheckerTools_Functions 
	(
		fn detectNGons theObj=
		(
			local theNGonArray = #()
			local polyCount = 0
			local meshFaceCount = 0
			local polyVertCount = 0
			local meshVertCount = 0
			
			if classof theObj == Editable_Poly then
			(
				polyVertCount += polyop.getNumVerts theObj
				local thePolyCount = polyop.getNumFaces theObj
				polyCount += thePolyCount
				for f = 1 to thePolyCount do
				(
					theDegree = polyop.getFaceDeg theObj f
					if theDegree != undefined do
					(
						if theDegree > 0 do
						(
							if theNGonArray[theDegree] == undefined then 
								theNGonArray[theDegree] = 1
							else
								theNGonArray[theDegree] += 1
						)
					)
				)
				theNGonArray
			)
			else
			(
				if classof theObj == PolyMeshObject then
				(
					if theObj.modifiers.count > 0 and classof theObj.modifiers[1] == Edit_Poly then
					(
						local theEP = theObj.modifiers[1]
						select theObj
						local thePolyCount = theEP.GetNumFaces node:theObj
						polyCount += thePolyCount
						polyVertCount += theEP.GetNumVertices node:theObj
						for f = 1 to thePolyCount do
						(
							theDegree = theEP.GetFaceDegree f node:theObj
							if theDegree != undefined do
							(
								if theDegree > 0 do
								(
									if theNGonArray[theDegree] == undefined then 
										theNGonArray[theDegree] = 1
									else
										theNGonArray[theDegree] += 1
								)
							)
						)						
					)
					else
					(
						local theEP = Edit_Poly()
						addModifier theObj theEP
						select theObj
						--modPanel.setCurrentObject theEP
						local thePolyCount = theEP.GetNumFaces node:theObj
						polyCount += thePolyCount
						polyVertCount += theEP.GetNumVertices node:theObj
						for f = 1 to thePolyCount do
						(
							theDegree = theEP.GetFaceDegree f node:theObj
							if theDegree != undefined do
							(
								if theDegree > 0 do
								(
									if theNGonArray[theDegree] == undefined then 
										theNGonArray[theDegree] = 1
									else
										theNGonArray[theDegree] += 1
								)
							)
						)
						deleteModifier theObj theEP
					)
				)
				else
				(
					local theMeshCount = GetTriMeshFaceCount theObj
					theNGonArray[3] = (theMeshCount)[1]
					meshFaceCount += (theMeshCount)[1] 
					meshVertCount += (theMeshCount)[2] 
				)
			)
			#(theNGonArray, polyCount, meshFaceCount, polyVertCount, meshVertCount)
		),
		
		fn openAllGroups openThem:true =
		(
			for o in objects where isGroupHead o do setGroupOpen o openThem
		),
		
		fn runAllxViewChecks =
		(
			local totalCount = #(0,0,0,0,0)
			for o in objects where findItem GeometryClass.classes (classof o) > 0 and classof o != TargetObject do
			(
				local result = GeometryCheckerTools_Functions.detectIsolatedVertices o
				if result != false do totalCount[1] += result.count
				--local result = GeometryCheckerTools_Functions.detectTVertices o
				--if result != false do totalCount[2] += result.count
				local result = GeometryCheckerTools_Functions.detectOverlappingVertices o
				if result != false do totalCount[3] += result.count
				local result = GeometryCheckerTools_Functions.detectOverlappingFaces o
				if result != false do totalCount[4] += result.count
				local result = GeometryCheckerTools_Functions.detectOverlappingUVFaces o
				if result != false do totalCount[5] += result.count
			)
			totalCount
		),
		
		fn detectIsolatedVertices theObj =
		(
			-- mod 11/02/11 by jgardino, disabled for Lite
			false
		),
		
		fn detectTVertices theObj =
		(
			-- mod 11/02/11 by jgardino, disabled for Lite
			false	
		),
		
		fn detectOverlappingVertices theObj =
		(
			-- mod 11/02/11 by jgardino, disabled for Lite
			false	
		),
		
		fn detectOverlappingFaces theObj =
		(
			-- mod 11/02/11 by jgardino, disabled for Lite
			false	
		),
		
		fn detectOverlappingUVFaces theObj =
		(
			local theResults = #()
			local returnValue = try(OverlappedUVWFaces.Check currentTime theObj &theResults)catch(#Failed)
			if returnValue == #Failed then 
				false
			else
				theResults		
		),
		
		fn getSceneVertexAndFaceCount =
		(
			local polyCount = 0
			local meshFaceCount = 0
			local polyVertCount = 0
			local meshVertCount = 0
			for o in objects where findItem GeometryClass.classes (classof o) > 0 and classof o != TargetObject do
			(
				if classof o == Editable_Poly then
				(
					polyCount += polyop.getNumFaces o
					polyVertCount += polyop.getNumVerts o
				)
				else if classof o == PolyMeshObject then
				(
						if o.modifiers.count > 0 and classof o.modifiers[1] == Edit_Poly then
						(
							select o
							polyCount += o.modifiers[1].GetNumFaces node:o
							polyVertCount += o.modifiers[1].GetNumVertices node:o
						)	
						else
						(
							local theEP = Edit_Poly()
							addModifier o theEP
							select o
							polyCount += theEP.GetNumFaces node:o
							polyVertCount += theEP.GetNumVertices node:o
							deleteModifier o theEP
						)
				)
				else
				(
					theCount = GetTriMeshFaceCount o
					meshFaceCount += theCount[1]
					meshVertCount += theCount[2]
				)
			)
			#(polyCount,polyVertCount,meshFaceCount,meshVertCount)
		),
		
		fn getHiddenObjects =
		(
			--Need handling of all cases of hiding separately, including
			--*Node Hidden
			--*Layer Hidden
			--*Frozen and Hide Frozen checked
			for o in objects where o.isHiddenInVpt collect o
		),
		
		fn unhideAllObjects =
		(
			--Unhide all objects
			objects.ishidden = false
			--Unhide all layers
			for i = 1 to LayerManager.count do
			(
				local theLayer = LayerManager.getLayer (i-1)
				theLayer.on = true
				theLayer.ishidden = false
			)
			--Uncheck Hide Frozen
			maxOps.hideFrozenObjects = false
		),
		
		fn createViewportScreenshot theBasePath viewName:""=
		(
			local theCamera = viewport.getCamera()
			if isValidNode theCamera do viewName = theCamera.name
			local theBitmap1 = gw.getViewportDIB()
			theBitmap1.filename = getFilenamePath theBasePath + "CheckMate_"+ getFilenameFile maxFileName + "_"+ viewName +".png"
			save theBitmap1
			theBitmapTexture = bitmapTexture filename:theBitmap1.filename
			theBitmap2 = renderMap theBitmapTexture size:[240,160] filter:true
			theBitmap2.filename = getFilenamePath theBasePath + "CheckMate_"+ getFilenameFile maxFileName + "_"+ viewName +"_tn.png"
			save theBitmap2
			local filename1 = theBitmap1.filename
			local filename2 = theBitmap2.filename
			free theBitmap1 
			free theBitmap2
			theBitmap1 = undefined
			theBitmap2 = undefined
			#(filename1 , filename2)
		),
		
		fn detectDefaultNames =
		(
			local defaultNameObjects = #()
			local theClasses = GeometryClass.classes
			join theClasses (Helper.classes)
			join theClasses (Camera.classes)
			join theClasses (Light.classes)
			join theClasses (SpaceWarpModifier.classes)
			join theClasses (Shape.classes)
			
			local explicitListCheck = #(
				#(Omnilight, "Omni*"),
				#(TargetCamera, "Camera*"),
				#(FreeCamera, "Camera*"),
				#(TargetSpot, "Spot*"),
				#(FreeSpot, "FSpot*"),
				#(TargetDirectionalLight, "Direct*"),
				#(DirectionalLight, "FDirect*"),
				#(miAreaLightomni, "mr Area Omni*"),
				#(miAreaLight, "mr Area Spot*"),
				#(KrakatoaPRTLoader, "PRT Loader*"),
				#(PF_Source, "PF Source*"),
				#(PFEngine, "PF Engine*"),
				#(Particle_View, "Particle View*"),
				#(RenderParticles, "Render*"),
				#(ShapeLibrary, "Shape*"),
				#(TargetObject, "Camera*"),
				#(TargetObject, "Spot*"),
				#(TargetObject, "Direct*"),
				#(TargetObject, "Tape*")
			)
			
			for o in objects do 
			(
				local done = false
				local namesToCheck = #(o.name)
				if matchPattern o.name pattern:"*.Target" do append namesToCheck (substring o.name 1 (o.name.count-7))
				for aName in namesToCheck do
				(
					if matchPattern aName pattern:((classof o) as string + "*") do
					(
						append defaultNameObjects o
						done = true				
					)
					for p in explicitListCheck while not done do
					(
						if classof o ==p[1] and matchpattern aName pattern:p[2] do 
						(
							append defaultNameObjects o
							done = true
						)
					)
					for aClass in theClasses while not done do 
					(
						if matchPattern aName pattern:(aClass as string + "*") do 
						(
							append defaultNameObjects o
							done = true
						)
					)
				)
			)
			defaultNameObjects
		),
		
		fn getSceneBoundingBox theObjects =
		(
			local theMinX = 100000000
			local theMinY = 100000000
			local theMinZ = 100000000
			local theMaxX = -100000000
			local theMaxY = -100000000
			local theMaxZ = -100000000
			for o in theObjects do
			(
				if o.min.x < theMinX do theMinX = o.min.x
				if o.min.y < theMinY do theMinY = o.min.y
				if o.min.z < theMinZ do theMinZ = o.min.z
				if o.max.x > theMaxX do theMaxX = o.max.x
				if o.max.y > theMaxY do theMaxY = o.max.y
				if o.max.z > theMaxZ do theMaxZ = o.max.z
			)
			if theObjects.count == 0 then
				#([0,0,0], [0,0,0])
			else
				#([theMinX,theMinY,theMinZ], [theMaxX,theMaxY,theMaxZ])
		),
		
		fn collectMaps theName theArray =
		(
			append theArray theName
		),
		fn getBitmapFiles theMode theObject: =
		(
			local theFiles = #()
			if theObject == unsupplied then
			(
				if theMode == #all then 
					enumerateFiles GeometryCheckerTools_Functions.collectMaps theFiles 
				else 
					enumerateFiles GeometryCheckerTools_Functions.collectMaps theFiles theMode
			)
			else
			(
				if theMode == #all then 
					enumerateFiles theObject GeometryCheckerTools_Functions.collectMaps theFiles 
				else
					enumerateFiles theObject GeometryCheckerTools_Functions.collectMaps theFiles theMode
			)
			local uniqueFiles = #()
			for i in theFiles where findItem uniqueFiles i == 0 do append uniqueFiles i
			uniqueFiles
		),
		fn enablexViewChecker theName =
		(
			local count = xViewChecker.getNumCheckers()
			local theID = 0
			for i = 1 to count do
			(
				if xViewChecker.getCheckerName i == theName do
				(
					theID = xViewChecker.getCheckerID i
					xViewChecker.setActiveCheckerID theID 
					xViewChecker.on = true
					xViewChecker.activeIndex = i
				)
			)
		)
	)--end struct

	--Main Menu Definitions
	rcmenu GeometryCheckerTools_mainmenu
	(
		subMenu "File"
		(
			--[ mod 2011/05/15, added summary report
			menuItem mnu_viewLastHTMLSummary "View Last HTML Summary..."
			--] end mod
			menuItem mnu_viewLastHTML "View Last HTML..."
			menuItem mnu_viewLastXML "View Last XML..."
			separator sep_100
			--[ mod 2011/05/15, added summary report
			menuItem mnu_saveHTMLSummary "Save Last HTML Summary As..."
			--] end mod
			menuItem mnu_saveHTML "Save Last HTML Report As ..."
			menuItem mnu_saveXML "Save Last XML Report As..."
			separator sep_105
			subMenu "HTML Report Options"
			(
				menuItem mnu_IncludeViewportBitmaps "Include Viewport Thumbnails in HTML Report" checked:GeometryCheckerTools_Settings.IncludeViewportBitmaps
				menuItem mnu_IncludeCameraBitmaps "Include Camera Thumbnails in HTML Report" checked:GeometryCheckerTools_Settings.IncludeCameraBitmaps
			)
			separator sep_110
			menuItem mnu_batchProcessHTML "Batch-Process Folder - HTML Reports..." 
			menuItem mnu_batchProcessXML "Batch-Process Folder - XML Reports..." 
			menuItem mnu_batchProcessBoth "Batch-Process Folder - HTML and XML Reports..." 
			menuItem mnu_recursiveScanFolders "Scan Sub-Folders Recursively" checked:GeometryCheckerTools_Settings.RecursiveScanFolders
			separator sep_150
			menuItem mnu_quit "Quit"
		)
		on mnu_recursiveScanFolders picked do
		(
			GeometryCheckerTools_Settings.RecursiveScanFolders = not GeometryCheckerTools_Settings.RecursiveScanFolders
		)
		on mnu_IncludeViewportBitmaps picked do
		(
			GeometryCheckerTools_Settings.IncludeViewportBitmaps = not GeometryCheckerTools_Settings.IncludeViewportBitmaps
		)
		on mnu_IncludeCameraBitmaps picked do
		(
			GeometryCheckerTools_Settings.IncludeCameraBitmaps = not GeometryCheckerTools_Settings.IncludeCameraBitmaps
		)
		
		--[ mod 2011/05/15, added summary report
		on mnu_viewLastHTMLSummary  picked do
		(
			GeometryCheckerTools_Rollout.viewHTMLSummaryFile ()
		)
		--] end mod
		on mnu_viewLastHTML  picked do
		(
			GeometryCheckerTools_Rollout.viewHTMLFile()
		)
		on mnu_viewLastXML  picked do
		(
			GeometryCheckerTools_Rollout.viewXMLFile()
		)
		
		on mnu_batchProcessHTML picked do
		(
			GeometryCheckerTools_Rollout.batchCreateFiles html:true xml:false
		)
		on mnu_batchProcessXML picked do
		(
			GeometryCheckerTools_Rollout.batchCreateFiles html:false xml:true
		)
		on mnu_batchProcessBoth picked do
		(
			GeometryCheckerTools_Rollout.batchCreateFiles html:true xml:true
		)
		
		--[ mod 2011/05/15, added summary report
		on mnu_saveHTMLSummary picked do
		(
			GeometryCheckerTools_Rollout.createHTMLSummaryFile()
		)
		--] end mod
		on mnu_saveHTML picked do
		(
			GeometryCheckerTools_Rollout.createHTMLFile()
		)
		on mnu_saveXML picked do
		(
			GeometryCheckerTools_Rollout.createXMLFile()
		)		
		
		subMenu "Edit"
		(
			menuItem mnu_synchronizeSelection "Synchronize Selection To Scene" checked:GeometryCheckerTools_Settings.SynchronizeSelection
		)	
		subMenu "View"
		(
			menuItem mnu_ExpandSceneView "Expand Scene View" checked:GeometryCheckerTools_Settings.ListViewVisibility[1]
			menuItem mnu_ExpandObjectsView "Expand Objects View" checked:GeometryCheckerTools_Settings.ListViewVisibility[2]
			menuItem mnu_ExpandInfoView "Expand Problems View" checked:GeometryCheckerTools_Settings.ListViewVisibility[3]
			separator sep_300
			menuItem mnu_ShowGeometry "Show Geometry" checked:GeometryCheckerTools_Settings.ShowGeometry
			menuItem mnu_ShowShapes "Show Shapes" checked:GeometryCheckerTools_Settings.ShowShapes
			menuItem mnu_ShowHelpers "Show Helpers" checked:GeometryCheckerTools_Settings.ShowHelpers
			menuItem mnu_ShowLights "Show Lights" checked:GeometryCheckerTools_Settings.ShowLights
			menuItem mnu_ShowCameras "Show Cameras" checked:GeometryCheckerTools_Settings.ShowCameras
			menuItem mnu_ShowSpaceWarps "Show Space Warps" checked:GeometryCheckerTools_Settings.ShowSpaceWarps
			separator sep_310
			menuItem mnu_ShowNone "Show None" 
			menuItem mnu_ShowAll "Show All" 
			menuItem mnu_ShowInvert "Invert" 
			
			separator sep_320
			menuItem mnu_SortAlphabetically "Sort Alphabetically" checked:GeometryCheckerTools_Settings.SortAlphabetically
			
			separator sep_330
			menuItem mnu_SkipPassedObjects "Show Only Problem Objects" checked:GeometryCheckerTools_Settings.SkipPassedObjects
		)	
		subMenu "xView"
		(
			menuItem mnu_setxViewTolerance "Set xView Tolerance..."
			separator sep_400
			menuItem mnu_IncludeFaceOrientationScreenshots "Include Face Orientation xView Screenshots" checked:GeometryCheckerTools_Settings.IncludeFaceOrientationScreenshots
			subMenu "Number Of Screenshots Per Row..."
			(
				menuItem mnu_FaceOrientationScreenshotsCount4 "4 Per Row" checked:(GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount == 4)
				menuItem mnu_FaceOrientationScreenshotsCount5 "5 Per Row" checked:(GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount == 5)
				menuItem mnu_FaceOrientationScreenshotsCount6 "6 Per  Row" checked:(GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount == 6)
				menuItem mnu_FaceOrientationScreenshotsCount7 "7 Per  Row" checked:(GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount == 7)
				menuItem mnu_FaceOrientationScreenshotsCount8 "8 Per  Row" checked:(GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount == 8)
				menuItem mnu_FaceOrientationScreenshotsCount10 "10 Per  Row" checked:(GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount == 10)
			)
		)
		on mnu_FaceOrientationScreenshotsCount4 picked do GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount = 4
		on mnu_FaceOrientationScreenshotsCount5 picked do GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount = 5
		on mnu_FaceOrientationScreenshotsCount6 picked do GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount = 6
		on mnu_FaceOrientationScreenshotsCount7 picked do GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount = 7
		on mnu_FaceOrientationScreenshotsCount8 picked do GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount = 8
		on mnu_FaceOrientationScreenshotsCount10 picked do GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount = 10
			
		on mnu_IncludeFaceOrientationScreenshots  picked do GeometryCheckerTools_Settings.IncludeFaceOrientationScreenshots = not GeometryCheckerTools_Settings.IncludeFaceOrientationScreenshots
		on mnu_setxViewTolerance picked do
		(
			createDialog setxViewTolerance_Dialog 210 80 modal:true
		)
		subMenu "Help"
		(
			menuItem mnu_Help "Help..."
		)		
		menuItem mnu_update "[UPDATE]"
		subMenu "Tools"
		(
			menuItem mnu_Check4SpacewrapModifiers "Check for Spacewrap Modifiers"
			menuItem mnu_DeleteSpacewrapModifiers "Delete All Spacewrap Modifiers"
		)

		on mnu_SkipPassedObjects picked do
		(
			GeometryCheckerTools_Settings.SkipPassedObjects = not GeometryCheckerTools_Settings.SkipPassedObjects
			GeometryCheckerTools_Rollout.refresh()
		)
		on mnu_SortAlphabetically picked do
		(
			GeometryCheckerTools_Settings.SortAlphabetically = not GeometryCheckerTools_Settings.SortAlphabetically
			--GeometryCheckerTools_Rollout.refresh()
		)	
		on mnu_ShowGeometry picked do
		(
			GeometryCheckerTools_Settings.ShowGeometry = not GeometryCheckerTools_Settings.ShowGeometry
			--GeometryCheckerTools_Rollout.refresh()
		)
		on mnu_ShowShapes picked do
		(
			GeometryCheckerTools_Settings.ShowShapes = not GeometryCheckerTools_Settings.ShowShapes
			--GeometryCheckerTools_Rollout.refresh()
		)	
		on mnu_ShowHelpers picked do
		(
			GeometryCheckerTools_Settings.ShowHelpers = not GeometryCheckerTools_Settings.ShowHelpers
			--GeometryCheckerTools_Rollout.refresh()
		)	
		on mnu_ShowLights picked do
		(
			GeometryCheckerTools_Settings.ShowLights = not GeometryCheckerTools_Settings.ShowLights
			--GeometryCheckerTools_Rollout.refresh()
		)	
		on mnu_ShowCameras picked do
		(
			GeometryCheckerTools_Settings.ShowCameras = not GeometryCheckerTools_Settings.ShowCameras
			--GeometryCheckerTools_Rollout.refresh()
		)	
		on mnu_ShowSpaceWarps picked do
		(
			GeometryCheckerTools_Settings.ShowSpaceWarps = not GeometryCheckerTools_Settings.ShowSpaceWarps
			--GeometryCheckerTools_Rollout.refresh()
		)		
		on mnu_ShowNone picked do
		(
			GeometryCheckerTools_Settings.ShowGeometry = GeometryCheckerTools_Settings.ShowShapes = GeometryCheckerTools_Settings.ShowHelpers = GeometryCheckerTools_Settings.ShowLights =GeometryCheckerTools_Settings.ShowCameras =GeometryCheckerTools_Settings.ShowSpaceWarps = false
			--GeometryCheckerTools_Rollout.refresh()
		)
		on mnu_ShowAll picked do
		(
			GeometryCheckerTools_Settings.ShowGeometry = GeometryCheckerTools_Settings.ShowShapes = GeometryCheckerTools_Settings.ShowHelpers = GeometryCheckerTools_Settings.ShowLights =GeometryCheckerTools_Settings.ShowCameras =GeometryCheckerTools_Settings.ShowSpaceWarps = true
			--GeometryCheckerTools_Rollout.refresh()
		)
		on mnu_ShowInvert picked do
		(
			GeometryCheckerTools_Settings.ShowGeometry = not GeometryCheckerTools_Settings.ShowGeometry 
			GeometryCheckerTools_Settings.ShowShapes = not GeometryCheckerTools_Settings.ShowShapes 
			GeometryCheckerTools_Settings.ShowHelpers = not GeometryCheckerTools_Settings.ShowHelpers 
			GeometryCheckerTools_Settings.ShowLights = not GeometryCheckerTools_Settings.ShowLights 
			GeometryCheckerTools_Settings.ShowCameras = not GeometryCheckerTools_Settings.ShowCameras 
			GeometryCheckerTools_Settings.ShowSpaceWarps = not GeometryCheckerTools_Settings.ShowSpaceWarps 
			--GeometryCheckerTools_Rollout.refresh()
		)

		on mnu_synchronizeSelection  picked do 
		(
			GeometryCheckerTools_Settings.SynchronizeSelection = not GeometryCheckerTools_Settings.SynchronizeSelection
		)
		on mnu_update picked do
		(
			if GeometryCheckerTools_Rollout.check4SpacewrapModifiers() do
			(
				--[ added 2011/05/15
				GeometryCheckerTools_Rollout.deleteAllTurboSmooth()
				GeometryCheckerTools_Rollout.deleteAllMeshSmooth()
				--] end added
				GeometryCheckerTools_Rollout.refresh()
			)
		)
		on mnu_Check4SpacewrapModifiers picked do
		(
			GeometryCheckerTools_Rollout.check4SpacewrapModifiers()
		)		
		on mnu_DeleteSpacewrapModifiers picked do
		(
			GeometryCheckerTools_Rollout.deleteSpacewrapModifiers()
		)
		
		on mnu_quit picked do
		(
			destroyDialog 	GeometryCheckerTools_Rollout
		)
		
		on mnu_ExpandSceneView picked do 
		(
			GeometryCheckerTools_Settings.ListViewVisibility[1] = not GeometryCheckerTools_Settings.ListViewVisibility[1]
			if not GeometryCheckerTools_Settings.ListViewVisibility[1] and not GeometryCheckerTools_Settings.ListViewVisibility[2] and not GeometryCheckerTools_Settings.ListViewVisibility[3] do GeometryCheckerTools_Settings.ListViewVisibility[1] = true
			GeometryCheckerTools_Rollout.resizeDialog (GetDialogSize GeometryCheckerTools_Rollout)
		)
		on mnu_ExpandObjectsView picked do 
		(
			GeometryCheckerTools_Settings.ListViewVisibility[2] = not GeometryCheckerTools_Settings.ListViewVisibility[2]
			if not GeometryCheckerTools_Settings.ListViewVisibility[1] and not GeometryCheckerTools_Settings.ListViewVisibility[2] and not GeometryCheckerTools_Settings.ListViewVisibility[3] do GeometryCheckerTools_Settings.ListViewVisibility[2] = true
			GeometryCheckerTools_Rollout.resizeDialog (GetDialogSize GeometryCheckerTools_Rollout)
		)
		on mnu_ExpandInfoView picked do 
		(
			GeometryCheckerTools_Settings.ListViewVisibility[3] = not GeometryCheckerTools_Settings.ListViewVisibility[3]
			if not GeometryCheckerTools_Settings.ListViewVisibility[1] and not GeometryCheckerTools_Settings.ListViewVisibility[2] and not GeometryCheckerTools_Settings.ListViewVisibility[3] do GeometryCheckerTools_Settings.ListViewVisibility[3] = true
			GeometryCheckerTools_Rollout.resizeDialog (GetDialogSize GeometryCheckerTools_Rollout)
		)
	)

-------------------------------------------
--Global Dialog Rollout Definition
-------------------------------------------
	try(destroyDialog GeometryCheckerTools_Rollout)catch()
	rollout GeometryCheckerTools_Rollout "Check-Mate"
	(
		--Local variables stored in the dialog rollout 
		local resizeDialog, refresh
		local objectProblemInfo = #()
		local totalNGonCounts = #()
		local defaultNameObjects = #()
		local scaledObjects = #()
		--[ mod 2011/05/25, Commenting out the Position and Rotation catagories
		--local	translatedObjects = #()
		--local rotatedObjects = #()
		--] end mod

		local allObjects = #()
		local theObjectsToTest = #()
		local theSelection = 0
		local theInfoSelection = 0
		local MaterialClipboard = undefined
		local ListItem = undefined
		local SubItem = undefined
		local theRowIndex = 0
		
		--[ mod 2011/05/20 by James Capps, font and bold settings changed
		--Reference
		-- format "<html><title>3ds Max CheckMate Summary - %</title><body bgcolor=\"#ffffff\" text=\"#000000\" font=\"Trebuchet MS\"><font face=\"Trebuchet MS\">\n" maxFileName to:theHTMLSummaryOut 
		--local HTMLErrorColor = "<font color =\"#FF1111\"><b>"
		local HTMLErrorColor = "<font color =\"#ff0029\" font=\"Trebuchet MS\"><font face=\"Trebuchet MS\"><b>"
		--local HTMLPassedColor = "<font color =\"#11FF11\">"
		local HTMLPassedColor = "<font color =\"#008000\" font=\"Trebuchet MS\"><font face=\"Trebuchet MS\"><b>"
		-- variable added
		--local HTMLOtherColor = "<font color =\"#FF7711\" font=\"Trebuchet MS\"><font face=\"Trebuchet MS\"><b>"
		--local HTMLStandInColor = "<font color =\"#******\">"
		local HTMLStandInColor = "<font color =\"#******\" font=\"Trebuchet MS\"><font face=\"Trebuchet MS\">"
		--local HTMLNoteColor = "<font color =\"#FF7711\">"
		local HTMLNoteColor = "<font color =\"#FF7711\" font=\"Trebuchet MS\"><font face=\"Trebuchet MS\">"
		--local HTMLCellBGColor = "<td bgcolor=\"#222222\">"
		local HTMLCellBGColor = "<td bgcolor=\"#ffffff\" font=\"Trebuchet MS\"><font face=\"Trebuchet MS\">"
		--local HTMLSpan3CellBGColor = "<td align=\"center\" colspan=\"3\" bgcolor=\"#222222\">"
		local HTMLSpan3CellBGColor = "<td align=\"center\" colspan=\"3\" bgcolor=\"#ffffff\" font=\"Trebuchet MS\"><font face=\"Trebuchet MS\">"
		--] end mod
		local theHTMLFile = ""
		local theHTMLout
		local theHTMLoutScene
		local theHTMLoutObjects
		--[ mod 2011/05/15, added summary report
		local theHTMLSummaryFile
		local theHTMLSummaryOut
		local theHTMLSummaryOutScene
		--] end mod
		
		local theXMLFile = ""
		local theXMLout
		local theXMLoutScene
		local theXMLoutObjects
		
		local defaultNamesTOTAL = 0
		
		local nonQuadTOTAL = 0
		
		local isolatedVerticesTOTAL = 0
		local isolatedVerticesCountTOTAL = 0
		
		local tVerticesTOTAL  = 0
		local tVerticesCountTOTAL  = 0
		
		local overlappingVerticesTOTAL = 0
		local overlappingVerticesCountTOTAL = 0
		
		local overlappingFacesTOTAL = 0
		local overlappingFacesCountTOTAL = 0
		
		local overlappingUVFacesTOTAL = 0
		local overlappingUVFacesCountTOTAL = 0
		
		local NoMaterialTOTAL = 0
		local MissingMapsTOTAL = 0
		local MissingMapsCountTOTAL = 0
		
		local polyCount = 0
		local meshFaceCount = 0
		local polyVertCount = 0
		local meshVertCount = 0		
		
		local IniFile = (GetDir #plugcfg + "\\GeometryCheckerTools.ini")

		

		local errorColor = (dotNetClass "System.Drawing.Color").fromARGB 200 0 0
		local okColor = (dotNetClass "System.Drawing.Color").fromARGB 0 100 0
		
		progressbar prg_progress height:5 color:red width:theSize.x align:#center offset:[0,-4] 

		--DotNet ListView controls for scene stats, object display and problem/solution info
		dotNetControl dnc_scene "ListView" width:1396 height:300 align:#center offset:[0,-4] 
		dotNetControl dnc_objects "ListView" width:1396 height:300 align:#center offset:[0,-4] 
		dotNetControl dnc_info "ListView" width:1396 height:300 align:#center offset:[0,-4] 
		--Functions
		
		--[ added 2011/05/15
		-- delete all turbosmooth modifiers
		fn deleteAllTurboSmooth =
		(
			local AllObjs = $* as array
			for obj in AllObjs where superclassof obj == GeometryClass and classof obj != Targetobject and classof obj != BoneGeometry and classof obj != Biped_Object and obj.name != "TurboMasterBox" do
			(
				while (try(obj.turbosmooth)catch(undefined)) != undefined do
				(
					deleteModifier obj obj.turbosmooth
				)
			)
		)
		fn deleteAllMeshSmooth = 
		(
			local AllObjs = $* as array
			for obj in AllObjs where superclassof obj == GeometryClass and classof obj != Targetobject and classof obj != BoneGeometry and classof obj != Biped_Object do
			(
				while (try(obj.modifiers[#meshsmooth])catch(undefined)) != undefined do
				(
					deleteModifier obj (obj.modifiers[#MeshSmooth])
				)
			)
		)
		fn check4SpacewrapModifiers = 
		(
			local AllObjs = objects as array
			for obj in AllObjs where superclassof obj == GeometryClass and classof obj != Targetobject and classof obj != BoneGeometry and classof obj != Biped_Object do
			(
				for i = 1 to obj.modifiers.count do 
				( 
					if superclassof obj.modifiers[i] == SpacewarpModifier  do (MessageBox ("Spacewrap modifier found in " + obj.name); return false)
				)
			)
			return true;
		)
		fn deleteSpacewrapModifiers = 
		(
			local AllObjs = objects as array
			local count = 0
			local output
			for obj in AllObjs where superclassof obj == GeometryClass and classof obj != Targetobject and classof obj != BoneGeometry and classof obj != Biped_Object do
			(
				local isSpacewrap
				do
				(
					--count += 1
					--output = "count=" + count as string
					--print output
					isSpacewrap = false
					for i = 1 to obj.modifiers.count do ( if superclassof obj.modifiers[i] == SpacewarpModifier  do (deleteModifier obj i; isSpacewrap = true) )
				)
				while isSpacewrap
			)
		)
		--] end added
		
		fn initObjectListView =
		(
			local lv = dnc_objects
			--[ mod  2011/05/20, removed Position and Rotation columns 
			--local infolayout_def = #(#("Object",150),#("Name",60),#("Class",100),#("Position",100),#("Rotation",100),#("Scale",70),#("NGons",100), #("Iso.Verts",70),   #("V.Overlap",70),#("F.Overlap",70), #("UV.Overlap",70), #("Material",120), #("Missing Maps",70) )  --#("T-Verts",70), 
			local infolayout_def = #(#("Object",150),#("Name",60),#("Class",100),#("Scale",70),#("NGons",100), #("Iso.Verts",70),   #("V.Overlap",70),#("F.Overlap",70), #("UV.Overlap",70), #("Material",120), #("Missing Maps",70) )  --#("T-Verts",70), 
			--] end mod
			lv.Clear()
			lv.backColor = (dotNetClass "System.Drawing.Color").fromARGB 221 221  225
			lv.View = (dotNetClass "System.Windows.Forms.View").Details
			lv.gridLines = true
			lv.fullRowSelect = true 
			lv.checkboxes = false
			lv.hideSelection = false		
			lv.multiSelect = false
			for i in infolayout_def do
				lv.Columns.add i[1] i[2]
		) 		
		fn initInfoListView =
		(
			local lv = dnc_info
			local infolayout_def = #(#("Potential Problem",700),#("Suggested Solution",500)) 
			lv.Clear()
			lv.backColor = (dotNetClass "System.Drawing.Color").fromARGB 221 225 221  
			lv.View = (dotNetClass "System.Windows.Forms.View").Details
			lv.gridLines = true
			lv.fullRowSelect = true 
			lv.checkboxes = false
			lv.hideSelection = false		
			lv.multiSelect = false
			for i in infolayout_def do
				lv.Columns.add i[1] i[2]
		) 		
		fn initSceneListView =
		(
			local lv = dnc_scene
			local infolayout_def = #(#("Scene Property",500),#("Value",700)) 
			lv.Clear()
			lv.backColor = (dotNetClass "System.Drawing.Color").fromARGB  221 225 221  
			lv.View = (dotNetClass "System.Windows.Forms.View").Details
			lv.gridLines = true
			lv.fullRowSelect = true 
			lv.checkboxes = false
			lv.hideSelection = false		
			lv.multiSelect = false			
			for i in infolayout_def do
				lv.Columns.add i[1] i[2]
		) 	
		
		fn updateInfoList theObjectIndex=
		(
			initInfoListView()
			local lv = dnc_info
			local theInfo = objectProblemInfo[theObjectIndex]
			local theRange = #()
			local cnt = 1
			local color1 = (dotNetClass "System.Drawing.Color").fromARGB 225 221 221  
			local color2 = (dotNetClass "System.Drawing.Color").fromARGB 235 230 230  		
			if theInfo != undefined do
			(
				for i in theInfo do
				(
					local li = dotNetObject "System.Windows.Forms.ListViewItem" i[2]
					cnt = 1-cnt
					li.backcolor = #(color1,color2)[cnt+1]
					subLi = li.SubItems.add i[3]
					append theRange li
				)
				if theInfo.count == 0 then 
					lv.backcolor =  (dotNetClass "System.Drawing.Color").fromARGB 221 225 221  
				else 
					lv.backcolor =  (dotNetClass "System.Drawing.Color").fromARGB 225 221  221  
			)
			
			lv.Items.AddRange theRange 
		)	
		
		fn updateSceneList theObjectIndex=
		(
			local lv = dnc_info
			theInfo = objectProblemInfo[theObjectIndex]
			initInfoListView()
			theRange = #()
			for i in theInfo do
			(
				local li = dotNetObject "System.Windows.Forms.ListViewItem" i[2]
				subLi = li.SubItems.add i[3]
				append theRange li
			)
			lv.Items.AddRange theRange 
		)	
		
		fn sortFN v1 v2=
		(
			if v1.name > v2.name then 1 else -1
		)
		
		fn updateSpecificRecords SubItemType=
		(
			--defaultNameObjects = GeometryCheckerTools_Functions.detectDefaultNames()
			if ListItem != undefined and SubItem != undefined and theRowIndex > 0 do
			(
				local theObject = allObjects[theRowIndex]
				case SubItemType of
				(
					#material:
					(
						SubItem.text = if theObject.material != undefined then 
							(theObject.material as string)	
						else
							"NO MATERIAL"
					)
					#ngons:
					(
						local result = (GeometryCheckerTools_Functions.detectNGons theObject)[1]
						local txt = ""
						for i = 3 to result.count where result[i] != undefined do 
						(
							if totalNGonCounts[i] == undefined do totalNGonCounts[i] = 0
							totalNGonCounts[i] += result[i]
							txt+= "["+ i as string+"]:"+result[i] as string + " "
						)						
						SubItem.text = txt	
						ListItem.SubItems.item[2].text = (classof theObject) as string
					)
				)
				for i = objectProblemInfo[theRowIndex].count to 1 by -1 do
					if objectProblemInfo[theRowIndex][i][1] == SubItemType do deleteItem objectProblemInfo[theRowIndex] i
				updateInfoList theRowIndex
				
				if objectProblemInfo[theRowIndex].count == 0 do ListItem.forecolor = (dotNetClass "System.Drawing.Color").fromARGB 0 100 0
				dnc_objects.Refresh()
			)
		)
		
		
		fn updateList toHTML:false toXML:false=
		(
			initObjectListView()
			initInfoListView()
			
			local lv = dnc_objects
			local theRange = #()
			lv.Update()
			
			local color1 = (dotNetClass "System.Drawing.Color").fromARGB 221 221 225 
			local color2 = (dotNetClass "System.Drawing.Color").fromARGB 230 230 235 
			
			--Collect all objects with default names:
			defaultNameObjects = GeometryCheckerTools_Functions.detectDefaultNames()
			
			
			theObjectsToTest = objects as array
			if not GeometryCheckerTools_Settings.ShowGeometry do theObjectsToTest  = for o in theObjectsToTest  where findItem GeometryClass.classes (classof o) == 0 collect o
			if not GeometryCheckerTools_Settings.ShowShapes do theObjectsToTest  = for o in theObjectsToTest  where findItem Shape.classes (classof o) == 0 collect o
			if not GeometryCheckerTools_Settings.ShowHelpers do theObjectsToTest  = for o in theObjectsToTest  where findItem Helper.classes (classof o) == 0 collect o
			if not GeometryCheckerTools_Settings.ShowLights do theObjectsToTest  = for o in theObjectsToTest  where findItem Light.classes (classof o) == 0 collect o
			if not GeometryCheckerTools_Settings.ShowCameras do theObjectsToTest  = for o in theObjectsToTest  where findItem Camera.classes (classof o) == 0 collect o
			if not GeometryCheckerTools_Settings.ShowSpaceWarps do theObjectsToTest  = for o in theObjectsToTest  where findItem SpacewarpObject.classes (classof o) == 0 collect o
			
			if GeometryCheckerTools_Settings.SortAlphabetically do
			(
				qsort theObjectsToTest sortFN  
			)
			
			allObjects = #()
			objectProblemInfo = #()
			totalNGonCounts = #()
			scaledObjects = #()
			--[ mod 2011/05/25, Commenting out the Position and Rotation catagories
			--translatedObjects = #()
			--rotatedObjects = #()			
			--] end mod
			
			local cnt = 1
			if toHTML do 
			(
				format "<table width=\"100\%\">\n" to:theHTMLoutObjects
				--[ mod 2011/05/20, Commenting out the Position and Rotation catagories - James Capps 2011/05/20
				--format "<tr><td bgcolor=#333333>Object</td><td bgcolor=#333333>Name</td><td bgcolor=#333333>Class</td><td bgcolor=#333333>Pos.</td><td bgcolor=#333333>Rot.</td><td bgcolor=#333333>Scale</td><td bgcolor=#333333>NGons</td><td bgcolor=#333333>Iso.V.</td><td bgcolor=#333333>V.Over</td><td bgcolor=#333333>F.Over</td><td bgcolor=#ffffff>UV.Over</td><td bgcolor=#ffffff>Material</td><td bgcolor=#ffffff>Missing Maps</td></tr>\n" to:theHTMLoutObjects --<td bgcolor=#ffffff>T-Verts</td>
				format "<tr><td bgcolor=#ffffff>Object</td><td bgcolor=#ffffff>Name</td><td bgcolor=#ffffff>Class</td><td bgcolor=#ffffff>Scale</td><td bgcolor=#ffffff>NGons</td><td bgcolor=#ffffff>Iso.V.</td><td bgcolor=#ffffff>V.Over</td><td bgcolor=#ffffff>F.Over</td><td bgcolor=#ffffff>UV.Over</td><td bgcolor=#ffffff>Material</td><td bgcolor=#ffffff>Missing Maps</td></tr>\n" to:theHTMLoutObjects --<td bgcolor=#ffffff>T-Verts</td>
				--] end mod
			)
			if toXML do
			(
				format "\t\t<ObjectTests>\n" to:theXMLoutObjects
			)
			
			OverlappingFaces.tolerance = GeometryCheckerTools_Settings.OverlappingFacesTolerance
			OverlappingVertices.tolerance = GeometryCheckerTools_Settings.OverlappingVertsTolerance

			prg_progress.color = red
			local cnt1 = 0
			--LOOP THROUGH ALL COLLECTED OBJECTS
			for o in theObjectsToTest do  
			(
				cnt1 +=1
				prg_progress.value = 100.0*cnt1/theObjectsToTest.count
				if toHTML do htmltxt = "<tr>"
				if toXML do
				(
					format "\t\t\t<Object>\n" to:theXMLoutObjects
					format "\t\t\t\t<Name>%</Name>\n" o.name to:theXMLoutObjects
				)

				append objectProblemInfo #()
				append allObjects o
				
				local li = dotNetObject "System.Windows.Forms.ListViewItem" o.name
				cnt = 1-cnt
				li.backcolor = #(color1,color2)[cnt+1]
				li.name = "object"
				if toHTML do htmltxt += HTMLCellBGColor+HTMLStandInColor+o.name+"</td>" 

				--if findItem defaultNameObjects o > 0 then
				--(
				--	subLi = li.SubItems.add "DEFAULT"
				--	subLi.name = "name"
				--	append objectProblemInfo[objectProblemInfo.count] #(#name,"Object appears to have been named automatically.","Rename the object manually.")
				--	if toHTML do htmltxt+= HTMLCellBGColor+HTMLErrorColor+"DEFAULT</b></td>"
				--	if toXML do format "\t\t\t\t<CustomName>false</CustomName>\n" o.name to:theXMLoutObjects
				--	defaultNamesTOTAL += 1
				--)
				--else
				--(
					subLi = li.SubItems.add "custom"
					subLi.name = "name"
					if toHTML do htmltxt += HTMLCellBGColor+HTMLPassedColor+"custom</td>" 
					if toXML do format "\t\t\t\t<CustomName>true</CustomName>\n" o.name to:theXMLoutObjects
				--)
							
				local theVal  = ((classof o) as string)
				subLi = li.SubItems.add theVal 
				subLi.name = "class"
				if toHTML do htmltxt += HTMLCellBGColor+theVal +"</td>" 
				if toXML do format "\t\t\t\t<Class>%</Class>\n" (classof o) to:theXMLoutObjects
					
				--[ mod 2011/05/20, Commenting out the Position and Rotation catagories - James Capps 2011/05/20
				/*
				local theVal = ((o.transform.translationpart) as string)			
				subLi = li.SubItems.add theVal 
				subLi.name = "translation"
				if toXML do format "\t\t\t\t<Translation>%</Translation>\n" theVal to:theXMLoutObjects
					
				if theVal != "[0,0,0]"  then
				(
					append objectProblemInfo[objectProblemInfo.count] #(#position,"Object has Position different from World Origin.","Move object to World Origin.")
					append translatedObjects o
					if toHTML do htmltxt += HTMLCellBGColor+HTMLErrorColor+theVal +"</b></td>" 
					if toXML do format "\t\t\t\t<TranslationAtOrigin>false</TranslationAtOrigin>\n" theVal to:theXMLoutObjects
				)			
				else
				(
					if toHTML do htmltxt += HTMLCellBGColor+HTMLPassedColor+theVal +"</td>"
					if toXML do format "\t\t\t\t<TranslationAtOrigin>true</TranslationAtOrigin>\n" theVal to:theXMLoutObjects
				)			
				
				local theVal = (substituteString ((o.transform.rotationpart as eulerangles) as string) "eulerAngles " "")			
				subLi = li.SubItems.add theVal
				subLi.name = "rotation"
				if toXML do format "\t\t\t\t<Rotation>%</Rotation>\n" theVal to:theXMLoutObjects
					
				if theVal != "(0 0 0)"  then
				(
					append objectProblemInfo[objectProblemInfo.count] #(#rotation,"Object has non-zero Rotations applied to one or more axes.","Select and Reset XForm to zero-out Rotations.")
					append rotatedObjects o
					if toHTML do htmltxt += HTMLCellBGColor+HTMLErrorColor+theVal +"</b></td>" 
					if toXML do format "\t\t\t\t<ZeroRotation>false</ZeroRotation>\n" theVal to:theXMLoutObjects
				)			
				else
				(
					if toHTML do htmltxt += HTMLCellBGColor+HTMLPassedColor+theVal +"</td>"
					if toXML do format "\t\t\t\t<ZeroRotation>true</ZeroRotation>\n" theVal to:theXMLoutObjects
				)					
				*/
				--] end mod
					
				local theVal = "--"		
				subLi = li.SubItems.add theVal
				subLi.name = "scale"
				if toXML do format "\t\t\t\t<Scale>%</Scale>\n" theVal to:theXMLoutObjects
				
				--if theVal != "[1,1,1]"  then
				--(
					--append objectProblemInfo[objectProblemInfo.count] #(#scale,"Object has Scale applied at Object Transform Level.","Select and Reset XForm to set Scale to 100%.")
					--append scaledObjects o
					--if toHTML do htmltxt += HTMLCellBGColor+HTMLErrorColor+theVal +"</b></td>" 
					--if toXML do format "\t\t\t\t<Scaled100Percent>false</Scaled100Percent>\n" theVal to:theXMLoutObjects
				--)			
				--else
				--(
					if toHTML do htmltxt += HTMLCellBGColor+HTMLPassedColor+theVal +"</td>"
					if toXML do format "\t\t\t\t<Scaled100Percent>true</Scaled100Percent>\n" theVal to:theXMLoutObjects
				--)

				local tabuClasses = #(TargetObject, ParticleGroup, PFEngine, PF_Source )
				if findItem GeometryClass.classes (classof o) > 0 and findItem tabuClasses (classof o) == 0 then
				(
					local result1 = GeometryCheckerTools_Functions.detectNGons o
					local result = result1[1]
					polyCount += result1[2]
					meshFaceCount += result1[3]
					polyVertCount += result1[4]
					meshVertCount += result1[5]
					
					local txt = ""
					local alreadyAdded = false
					for i = 3 to result.count where result[i] != undefined do 
					(
						if totalNGonCounts[i] == undefined do totalNGonCounts[i] = 0
						totalNGonCounts[i] += result[i]
						txt+= "["+ i as string+"]:"+result[i] as string + " "
						if i > 4 and not alreadyAdded do 
						(
							append objectProblemInfo[objectProblemInfo.count] #(#ngons,"Object has Non-Quad Polygons.",if classof o == Editable_Poly then "Try to Quadify manually." else "Try applying a Quadify Modifier and/or collapsing to Editable Poly.", GeometryCheckerTools_RCMenus.NonQuadPoly)
							alreadyAdded = true
						)
					)
					subLi = li.SubItems.add txt
					subLi.name = "ngons"
					if toXML do format "\t\t\t\t<NGons>false</NGons>\n" txt to:theXMLoutObjects
					if alreadyAdded then 
					(
						nonQuadTOTAL +=1
						if toHTML do htmltxt += HTMLCellBGColor+HTMLErrorColor+txt +"</b></td>" 
						if toXML do format "\t\t\t\t<QuadsOnly>false</QuadsOnly>\n" txt to:theXMLoutObjects
					)
					else
					(
						if toHTML do htmltxt += HTMLCellBGColor+HTMLPassedColor+txt +"</td>" 						
						if toXML do format "\t\t\t\t<QuadsOnly>true</QuadsOnly>\n" txt to:theXMLoutObjects
					)	
	
					
					local result = GeometryCheckerTools_Functions.detectIsolatedVertices o
					if result == false then
					(
						subLi = li.SubItems.add ("--")		
						if toHTML do htmltxt += HTMLCellBGColor+"--</td>" 		
						if toXML do format "\t\t\t\t<IsolatedVertices>NA</IsolatedVertices>\n" txt to:theXMLoutObjects	
					)
					else
					(
						if result.count > 0 do 
						(
							append objectProblemInfo[objectProblemInfo.count] #(#isoverts,"Object has Isolated Vertices.","Delete Isolated Vertices",GeometryCheckerTools_RCMenus.EnableIsoVertsxViewChecker)
							isolatedVerticesTOTAL += 1
							isolatedVerticesCountTOTAL += result.count
						)
						subLi = li.SubItems.add (result.count as string)
						if toHTML do 
							if result.count == 0 then
								htmltxt += HTMLCellBGColor+HTMLPassedColor+(result.count as string)+"</td>" 		
							else
								htmltxt += HTMLCellBGColor+HTMLErrorColor+ (result.count as string)+"</b></td>" 		
						if toXML do format "\t\t\t\t<IsolatedVertices>%</IsolatedVertices>\n" result.count to:theXMLoutObjects	
					)
					subLi.name = "isoverts"
					
					--[ mod 2011/05/20, Commenting out the Position and Rotation catagories - James Capps 2011/05/20
					/*
					local result = GeometryCheckerTools_Functions.detectTVertices o
					if result == false then
					(
						subLi = li.SubItems.add ("--")	
						if toHTML do htmltxt += HTMLCellBGColor+"--</td>" 	
						if toXML do format "\t\t\t\t<TVertices>NA</TVertices>\n" txt to:theXMLoutObjects	
					)
					else
					(
						if result.count > 0 do 
						(
							append objectProblemInfo[objectProblemInfo.count] #(#tverts,"Object has T-Vertices.","Tweak Topology to remove T-Vertices or add TurnToPoly modifier - right-click for options.",GeometryCheckerTools_RCMenus.EnableTVertsxViewChecker)
							tVerticesTOTAL += 1
							tVerticesCountTOTAL +=result.count 
						)
						subLi = li.SubItems.add (result.count as string)		
						if toHTML do 
							if result.count == 0 then
								htmltxt += HTMLCellBGColor+HTMLPassedColor+(result.count as string)+"</td>" 		
							else
								htmltxt += HTMLCellBGColor+HTMLErrorColor+ (result.count as string)+"</b></td>" 		
						if toXML do format "\t\t\t\t<TVertices>%</TVertices>\n" result.count to:theXMLoutObjects								
					)
					subLi.name = "tverts"
					*/
					--] end mod
					local result = GeometryCheckerTools_Functions.detectOverlappingVertices o
					if result == false then
					(
						subLi = li.SubItems.add ("--")	
						if toHTML do htmltxt += HTMLCellBGColor+"--</td>" 
						if toXML do format "\t\t\t\t<OverlappingVertices>NA</OverlappingVertices>\n" txt to:theXMLoutObjects								
					)
					else
					(
						if result.count > 0 do 
						(
							append objectProblemInfo[objectProblemInfo.count] #(#oververts,"Object has Overlapping Vertices.","Tweak Topology to remove Overlapping Vertices.", GeometryCheckerTools_RCMenus.EnableOverlapVxViewChecker)
							overlappingVerticesTOTAL += 1
							overlappingVerticesCountTOTAL += result.count
						)
						subLi = li.SubItems.add (result.count as string)
						if toHTML do 
							if result.count == 0 then
								htmltxt += HTMLCellBGColor+HTMLPassedColor+(result.count as string)+"</td>" 		
							else
								htmltxt += HTMLCellBGColor+HTMLErrorColor+ (result.count as string)+"</b></td>" 		
						if toXML do format "\t\t\t\t<OverlappingVertices>%</OverlappingVertices>\n" result.count to:theXMLoutObjects								
							
					)
					subLi.name = "oververts"
					
					local result = GeometryCheckerTools_Functions.detectOverlappingFaces o
					if result == false then
					(
						subLi = li.SubItems.add ("--")	
						if toHTML do htmltxt += HTMLCellBGColor+"--</td>" 
						if toXML do format "\t\t\t\t<OverlappingFaces>NA</OverlappingFaces>\n" txt to:theXMLoutObjects								
					)
					else
					(
						if result.count > 0 do 
						(
							append objectProblemInfo[objectProblemInfo.count] #(#overfaces,"Object has Overlapping Faces.","Tweak Topology to remove Overlapping Faces.", GeometryCheckerTools_RCMenus.EnableOverlapFxViewChecker )
							overlappingFacesTOTAL += 1
							overlappingFacesCountTOTAL += result.count
						)
						subLi = li.SubItems.add (result.count as string)
						if toHTML do 
							if result.count == 0 then
								htmltxt += HTMLCellBGColor+ HTMLPassedColor+(result.count as string)+"</td>" 		
							else
								htmltxt += HTMLCellBGColor+HTMLErrorColor+ (result.count as string)+"</b></td>" 		
						if toXML do format "\t\t\t\t<OverlappingFaces>%</OverlappingFaces>\n" result.count to:theXMLoutObjects									
					)
					subLi.name = "overfaces"
					
					local result = GeometryCheckerTools_Functions.detectOverlappingUVFaces o
					if result == false then
					(
						subLi = li.SubItems.add ("--")	
						if toHTML do htmltxt += HTMLCellBGColor+"--</td>" 	
						if toXML do format "\t\t\t\t<OverlappingUVFaces>NA</OverlappingUVFaces>\n" txt to:theXMLoutObjects									
					)
					else
					(
						if result.count > 0 do 
						(
							append objectProblemInfo[objectProblemInfo.count] #(#overuvwfaces,"Object has Overlapping UVW Faces.","Tweak Topology to remove Overlapping UVW Faces.",GeometryCheckerTools_RCMenus.EnableOverlapUVFacesxViewChecker)
							overlappingUVFacesTOTAL += 1
							overlappingUVFacesCountTOTAL += result.count
						)
						subLi = li.SubItems.add (result.count as string)
						if toHTML do 
							if result.count == 0 then
								htmltxt += HTMLCellBGColor+ HTMLPassedColor+(result.count as string)+"</td>" 		
							else
								htmltxt += HTMLCellBGColor+HTMLErrorColor+ (result.count as string)+"</b></td>" 		
						if toXML do format "\t\t\t\t<OverlappingUVFaces>%</OverlappingUVFaces>\n" result.count to:theXMLoutObjects		
					)
					subLi.name = "overuvwfaces"
					
					if o.material != undefined then 
					(
						subLi = li.SubItems.add (o.material as string)	
						if toHTML do htmltxt += HTMLCellBGColor+HTMLPassedColor+(o.material as string)+"</td>" 		
						if toXML do 
						(
							format "\t\t\t\t<Material>true</Material>\n" to:theXMLoutObjects	
							format "\t\t\t\t<MaterialName>%</MaterialName>\n" o.material.name to:theXMLoutObjects							
							format "\t\t\t\t<MaterialClass>%</MaterialClass>\n" (classof o.material) to:theXMLoutObjects							
						)
					)
					else
					(
						subLi = li.SubItems.add ("NO MATERIAL")
						if toHTML do htmltxt += HTMLCellBGColor+HTMLErrorColor+"NO MATERIAL</b></td>" 	
						if toXML do 
						(
							format "\t\t\t\t<Material>false</Material>\n" to:theXMLoutObjects							
							format "\t\t\t\t<MaterialName></MaterialName>\n" to:theXMLoutObjects							
							format "\t\t\t\t<MaterialClass></MaterialClass>\n" to:theXMLoutObjects							
						)
						append objectProblemInfo[objectProblemInfo.count] #(#material,"The Object has no Material assigned.","Assign a material - right-click here for options...", GeometryCheckerTools_RCMenus.AssignMaterial)
						NoMaterialTOTAL += 1
					)
					subLi.name = "material"
					
					local result = GeometryCheckerTools_Functions.getBitmapFiles #missing theObject:o
					if result.count > 0 do 
					(
						for i in result do
							append objectProblemInfo[objectProblemInfo.count] #(#missingmaps, "Missing Map ["+ i +"]","Edit the Bitmap Path.")
						MissingMapsTOTAL +=1
						MissingMapsCountTOTAL  += result.count
					)
					subLi = li.SubItems.add (result.count as string)				
					subLi.name = "missingmaps"
					if toHTML do 
						if result.count == 0 then
							htmltxt += HTMLCellBGColor+HTMLPassedColor+(result.count as string)+"</td>" 		
						else
							htmltxt += HTMLCellBGColor+HTMLErrorColor+ (result.count as string)+"</b></td>" 						
					if toXML do format "\t\t\t\t<MissingMaps>%</MissingMaps>\n" result.count to:theXMLoutObjects								
				)
				else
				(
					for j = 1 to 8 do
					(
						subLi = li.SubItems.add "--"
						if toHTML do htmltxt += HTMLCellBGColor+"--</td>" 	
					)
				)
				
				li.forecolor = if objectProblemInfo[objectProblemInfo.count].count > 0 then ErrorColor else okColor
				if not GeometryCheckerTools_Settings.SkipPassedObjects or objectProblemInfo[objectProblemInfo.count].count > 0 do
				(
					append theRange li		
					
					if toHTML do 
					(
						htmltxt += "</tr>\n"
						if objectProblemInfo[objectProblemInfo.count].count > 0 then 
							htmltxt = substitutestring htmltxt HTMLStandInColor HTMLErrorColor
						else
							htmltxt = substitutestring htmltxt HTMLStandInColor HTMLPassedColor
						format "%" htmltxt to:theHTMLoutObjects				
					)
				)
				if toXML do
				(
					format "\t\t\t</Object>\n" to:theXMLoutObjects
				)				
			)--end loop
			prg_progress.value = 0.0
			if toHTML do 
			(
				format "</table>\n" to:theHTMLoutObjects
			)
			if toXML do
			(
				format "\t\t</ObjectTests>\n" to:theXMLoutObjects
			)
			
				
			lv.Items.AddRange theRange 
			--updateInfoList 1
		)
		
		fn createxViewNormalsScreenshots =
		(
			if not GeometryCheckerTools_Settings.ShowGeometry do return false
			local oldHiddenState = for o in objects collect #(o,o.isHidden)
			hide objects	
			for i = 1 to xViewChecker.getNumCheckers() do 
			(
				if xViewChecker.getCheckerName i == "Faces Orientation" do 
					xViewChecker.setActiveCheckerID (xViewChecker.getCheckerID i)
			)
			local oldCamera = viewport.getCamera()
			local oldViewportTM = viewport.getTM()
			local oldViewportType = viewport.getType()
			local oldRenderLevel = viewport.GetRenderLevel()
			viewport.setType #view_front
			max views redraw
			viewport.setType #view_persp_user
			viewport.SetRenderLevel #smoothhighlights
			
			xViewChecker.on = true
			theObjectsToTest = for o in objects where findItem GeometryClass.classes (classof o)  > 0 and classof o != TargetObject collect o
			if GeometryCheckerTools_Settings.SortAlphabetically do
			(
				qsort theObjectsToTest sortFN  
			)
			format "<p>\n<table>\n" to:theHTMLoutObjects --width=\"100\%\"
			local cnt = 0
			local txt = "<tr>"
			for o in theObjectsToTest do  
			(			
				cnt+=1
				if cnt > GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount do 
				(
					cnt = 1
					txt +="</tr>\n<tr>"
				)
				unhide o
				select o
				max zoomext sel
				max views redraw
				local pureName = ""
				for i in filterString o.name ".,;:'\"@!? " do pureName += i + "_"
				local thePaths = GeometryCheckerTools_Functions.createViewportScreenshot theHTMLFile viewName:(pureName)
				txt+="<td><a href=\""+(fileNameFromPath thePaths[1])+"\"><img src=\""+(fileNameFromPath thePaths[2])+"\"></a><br>"+o.name+"</td>" 
				hide o
			)
			format "%\n" txt to:theHTMLoutObjects
			format "</table>\n" to:theHTMLoutObjects
			for o in oldHiddenState do o[1].isHidden = o[2]
			xViewChecker.on = false
			try(viewport.setCamera oldCamera)catch()
			try(viewport.setType oldViewportType)catch()
			viewport.setTM oldViewportTM 
			viewport.SetRenderLevel oldRenderLevel
			max tool zoomextents all
		)
		
		-- mod 2011/05/15, added 3rd param
		-- mod 11/02/11 by jgardino, disabling checks unneeded for lite
		fn updateSceneInfo toHTML:false toXML:false toHTMLSummary:false=
		(
			initSceneListView()
			
			local st = timestamp()
			
			totalPolygons = polyCount + meshFaceCount
			totalVertices = polyVertCount + meshVertCount
			
			local lv = dnc_scene
			local theRange = #()
			lv.Update()
			
			local color1 = (dotNetClass "System.Drawing.Color").fromARGB 221 225 221  
			local color2 = (dotNetClass "System.Drawing.Color").fromARGB 230 235 230
			
			local geomObjCount = (for o in objects where findItem GeometryClass.classes (classof o) > 0 and classof o != TargetObject collect o)
			local thePropertiesToCheck = #(
				#("Scene Objects Count", (objects.count as string) ),
				#("Tested Objects Count", (theObjectsToTest.count as string + " of " + objects.count as string + " ("+ (if objects.count == 0 then 0 else (100.0*theObjectsToTest.count/objects.count)) as string + "%)"  ) ),
				#("Geometry Objects Count", (geomObjCount.count as string + " of " + objects.count as string + " ("+ (if objects.count == 0 then 0 else (100.0*geomObjCount.count/objects.count)) as string + "%)"  ) ),
				#("Total Polygons in Scene incl. N-Gons and Triangle Faces", (totalPolygons as string) ),
				#("Total Scene Vertex Count", (totalVertices as string)),
				#("Editable Poly Only - Polygons Count", (polyCount as string + " of " + totalPolygons as string + " ("+ (if totalPolygons == 0 then 0 else (100.0*polyCount/totalPolygons)) as string+"%)"   )),
				#("Editable Poly Only - Vertex Count", (polyVertCount as string+ " of " + totalVertices as string + " (" + (if totalVertices == 0 then 0 else (100.0*polyVertCount/totalVertices)) as string+"%)"  ))
			)

			local triangleCount = 0; local quadCount = 0;
			for i = 3 to totalNGonCounts.count where totalNGonCounts[i] != undefined do
			(
				append thePropertiesToCheck #( ("All Geometry - Polygons With "+i as string + " Sides"), (totalNGonCounts[i] as string + " of " + totalPolygons as string + " ("+ (if totalPolygons == 0 then 0 else (100.0*totalNGonCounts[i]/totalPolygons)) as string+"%)"  ), i > 4 and totalNGonCounts[i] > 0 )
				--[ mod 2011/05/15, these counts will be used in summary report 
				if i == 3 then triangleCount += totalNGonCounts[i]
				else if i == 4 then quadCount += totalNGonCounts[i]
				--] end mod 
			)
			
			local moreThanQuadsCount = 0		
			for i = 5 to totalNGonCounts.count where totalNGonCounts[i] != undefined do moreThanQuadsCount+=totalNGonCounts[i]
			append thePropertiesToCheck #( ("All Geometry - Polygons With More than 4 Sides"), (moreThanQuadsCount as string + " of " + totalPolygons as string + " ("+ (if totalPolygons == 0 then 0 else (100.0*moreThanQuadsCount/totalPolygons)) as string+"%)"  ), moreThanQuadsCount > 0 )
			
			append thePropertiesToCheck #("Non-EPoly TriMesh Face Count incl. Primitives, EMeshes etc.", (meshFaceCount as string + " of " + totalPolygons as string + " ("+ (if totalPolygons ==0 then 0 else (100.0*meshFaceCount/totalPolygons)) as string+"%)"  ), false )
			append thePropertiesToCheck #("Non-EPoly TriMesh Vertex Count incl. Primitives, EMeshes etc.", (meshVertCount as string + " of " + totalVertices as string + " ("+ (if totalVertices == 0 then 0 else (100.0*meshVertCount/totalVertices)) as string+"%)" ), false )
				
			--append thePropertiesToCheck #("Objects With Isolated Vertices", (isolatedVerticesTOTAL as string + " of " + objects.count as string + " ("+ (if objects.count == 0 then 0 else (100.0*isolatedVerticesTOTAL/objects.count)) as string+"%)" ), isolatedVerticesTOTAL>0 )
			--append thePropertiesToCheck #("Total Isolated Vertices", (isolatedVerticesCountTOTAL as string + " of " + totalVertices as string + " ("+ (if totalVertices == 0 then 0 else (100.0*isolatedVerticesCountTOTAL/totalVertices)) as string+"%)" ), isolatedVerticesCountTOTAL>0 )

			--append thePropertiesToCheck #("Objects With T-Vertices", (tVerticesTOTAL as string + " of " + objects.count as string + " ("+ (if objects.count == 0 then 0 else (100.0*tVerticesTOTAL/objects.count)) as string+"%)" ), tVerticesTOTAL>0 )
			--append thePropertiesToCheck #("Total T-Vertices", (tVerticesCountTOTAL as string + " of " + totalVertices as string + " ("+ (if totalVertices == 0 then 0 else (100.0*tVerticesCountTOTAL/totalVertices)) as string+"%)" ), tVerticesCountTOTAL>0 )

			--append thePropertiesToCheck #("Objects With Overlapping Vertices", (overlappingVerticesTOTAL as string + " of " + objects.count as string + " ("+ (if objects.count == 0 then 0 else (100.0*overlappingVerticesTOTAL/objects.count)) as string+"%)" ), overlappingVerticesTOTAL>0 )
			--append thePropertiesToCheck #("Total Overlapping Vertices (Tolerance:"+OverlappingVertices.tolerance as string+")", (overlappingVerticesCountTOTAL as string + " of " + totalVertices as string + " ("+ (if totalVertices == 0 then 0 else (100.0*overlappingVerticesCountTOTAL/totalVertices)) as string+"%)" ), overlappingVerticesCountTOTAL>0 )
				
			--append thePropertiesToCheck #("Objects With Overlapping Faces", (overlappingFacesTOTAL as string + " of " + objects.count as string + " ("+ (if objects.count == 0 then 0 else (100.0*overlappingFacesTOTAL/objects.count)) as string+"%)" ), overlappingFacesTOTAL>0 )
			--append thePropertiesToCheck #("Total Overlapping Faces (Tolerance:"+OverlappingFaces.tolerance as string+")" , (overlappingFacesCountTOTAL as string + " of " + totalPolygons as string + " ("+ (if totalPolygons == 0 then 0 else (100.0*overlappingFacesCountTOTAL/totalPolygons)) as string+"%)" ), overlappingFacesCountTOTAL>0 )

			--append thePropertiesToCheck #("Objects With Overlapping UV Faces", (overlappingUVFacesTOTAL as string + " of " + objects.count as string + " ("+ (if objects.count == 0 then 0 else (100.0*overlappingUVFacesTOTAL/objects.count)) as string+"%)" ), overlappingUVFacesTOTAL>0 )
			--append thePropertiesToCheck #("Total Overlapping UVFaces", (overlappingUVFacesCountTOTAL as string + " of " + totalPolygons as string + " ("+ (if totalPolygons == 0 then 0 else (100.0*overlappingUVFacesCountTOTAL/totalPolygons)) as string+"%)" ), overlappingUVFacesCountTOTAL>0 )

			--local st = timestamp()
			--local hiddenObjects = GeometryCheckerTools_Functions.getHiddenObjects()
			--format "getHiddenObjects: % ms\n" (timestamp()-st)	
				
			--append thePropertiesToCheck #("Hidden Objects", hiddenObjects.count as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*hiddenObjects.count/objects.count)) as string+"%)",  hiddenObjects.count > 0  )
				
			--append thePropertiesToCheck #("Total Objects With Default Names", (defaultNameObjects.count as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*defaultNameObjects.count/objects.count)) as string+"%)"  ), defaultNameObjects.count > 0)
			--append thePropertiesToCheck #("Tested Objects With Default Names", (defaultNamesTOTAL as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*defaultNamesTOTAL/objects.count)) as string+"%)"  ), defaultNamesTOTAL > 0)


			--[ mod 2011/05/20, Commenting out the Position and Rotation catagories - James Capps 2011/05/20
			--append thePropertiesToCheck #("Objects With Non-Zero Position", (translatedObjects.count as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*translatedObjects.count/objects.count)) as string+"%)"  ), translatedObjects.count > 0)
			--append thePropertiesToCheck #("Objects With Non-Zero Rotation", (rotatedObjects.count as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*rotatedObjects.count/objects.count)) as string+"%)"  ), rotatedObjects.count > 0)
			--] end mod
			--append thePropertiesToCheck #("Objects With Non-100% Scale", (scaledObjects.count as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*scaledObjects.count/objects.count)) as string+"%)"  ), scaledObjects.count > 0)

			append thePropertiesToCheck #("Objects With No Material", (NoMaterialTOTAL as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*NoMaterialTOTAL/objects.count)) as string+"%)"  ), NoMaterialTOTAL > 0)

			local groupHeads = (for o in objects where isGrouphead o collect o).count
			append thePropertiesToCheck #("Groups", (groupHeads as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*groupHeads/objects.count)) as string+"%)"  ), groupHeads == 0)
				
			local objectsWithParents = (for o in objects where o.parent != undefined collect o).count
			append thePropertiesToCheck #("Objects With Parents", (objectsWithParents as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*objectsWithParents/objects.count)) as string+"%)"  ), objectsWithParents == 0)

			local objectsWithChildren = (for o in objects where o.children.count > 0 collect o).count
			append thePropertiesToCheck #("Objects With Children", (objectsWithChildren as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*objectsWithChildren/objects.count)) as string+"%)"  ), objectsWithChildren == 0)
				
			local st = timestamp()	
			local allBitmapFiles = GeometryCheckerTools_Functions.getBitmapFiles #all
			local missingBitmapFiles = GeometryCheckerTools_Functions.getBitmapFiles #missing
			format "getBitmapFiles: % ms\n" (timestamp()-st)		
				
			append thePropertiesToCheck #("All Bitmaps", (allBitmapFiles.count + missingBitmapFiles.count) as string)
			append thePropertiesToCheck #("Missing Bitmaps", missingBitmapFiles.count as string + " of " + (allBitmapFiles.count + missingBitmapFiles.count) as string + " (" + (if (allBitmapFiles.count + missingBitmapFiles.count) == 0 then 0 else (100.0*missingBitmapFiles.count/(allBitmapFiles.count + missingBitmapFiles.count))) as string + "%)", missingBitmapFiles.count > 0 )
			append thePropertiesToCheck #("Objects With Missing Bitmaps", MissingMapsTOTAL as string + " of " + objects.count as string + " (" + (if objects.count == 0 then 0 else (100.0*MissingMapsTOTAL/objects.count)) as string + "%)", MissingMapsTOTAL > 0 )
				
			--local st = timestamp()	
			--local result = GeometryCheckerTools_Functions.getSceneBoundingBox geometry
			--append thePropertiesToCheck #("Geometry Objects Only - World-Aligned Bounding Box in User Units",  ("Min:["+ units.formatValue result[1].x+ ","+ units.formatValue result[1].y +"," + units.formatValue result[1].z +"]  Max:["+ units.formatValue result[2].x +","+ units.formatValue result[2].y +"," + units.formatValue result[2].z +"] - W:" + units.formatValue (result[2].x-result[1].x)+ " L:"+ units.formatValue (result[2].y-result[1].y)+ " H:"+ units.formatValue (result[2].z-result[1].z)  ) )
			--append thePropertiesToCheck #("Geometry Objects Only - World-Aligned Bounding Box in Generic Units",  ("Min:["+ result[1].x as string + ","+ result[1].y as string +"," + result[1].z as string +"]  Max:["+ result[2].x as string +","+ result[2].y as string +"," + result[2].z as string +"] - W:" + (result[2].x-result[1].x) as string + " L:"+ (result[2].y-result[1].y) as string + " H:"+ (result[2].z-result[1].z) as string  ) )
			--format "getSceneBoundingBox geometry: % ms\n" (timestamp()-st)	

			--local st = timestamp()	
			--local result = GeometryCheckerTools_Functions.getSceneBoundingBox objects
			--append thePropertiesToCheck #("All Scene Objects - World-Aligned Bounding Box in User Units", ("Min:["+ units.formatValue result[1].x+ ","+ units.formatValue result[1].y +"," + units.formatValue result[1].z +"]  Max:["+ units.formatValue result[2].x +","+ units.formatValue result[2].y +"," + units.formatValue result[2].z +"] - W:" + units.formatValue (result[2].x-result[1].x)+ " L:"+ units.formatValue (result[2].y-result[1].y)+ " H:"+ units.formatValue (result[2].z-result[1].z)  ) )
			--append thePropertiesToCheck #("All Scene Objects - World-Aligned Bounding Box in Generic Units", ("Min:["+ result[1].x as string + ","+ result[1].y as string +"," + result[1].z as string +"]  Max:["+ result[2].x as string +","+ result[2].y as string +"," + result[2].z as string +"] - W:" + (result[2].x-result[1].x) as string + " L:"+ (result[2].y-result[1].y) as string + " H:"+ (result[2].z-result[1].z) as string  ) )
			--format "getSceneBoundingBox objects: % ms\n" (timestamp()-st)	
				
			--local theCenter = (result[2] - result[1])/2
			--append thePropertiesToCheck #("All Scene Objects - Bounding Box Center", ("["+units.formatValue theCenter.x+ ","+ units.formatValue theCenter.y +"," + units.formatValue theCenter.z +"]   (" + theCenter as string + " Generic Units)"))
			--append thePropertiesToCheck #("All Scene Objects - Bounding Box Center Distance From World Origin", (units.formatValue (length theCenter) ) + "  ("+ (length theCenter) as string+ " Generic Units)" )

			--[ mod 2011/05/15, added this list of properties for summary report
			local theSummaryPropertiesToCheck = #(
				#("No Personal Contact Info in readme", "No Script Output" ),
				#("No Errors on Opening", "No Script Output" ),
				#("Polycount", (totalPolygons as string), totalPolygons == 0 ),
				--#("Number of Objects With Non-100% Scale", (scaledObjects.count as string + " of " + objects.count as string), scaledObjects.count > 0),
				#("Number of Ngons in Scene", (moreThanQuadsCount as string + " of " + totalPolygons as string), moreThanQuadsCount > 0 ),
				#("Number of Quads in Scene", (quadCount as string + " of " + totalPolygons as string), false ),
				#("Number of Triangles in Scene", (triangleCount as string + " of " + totalPolygons as string ), false ),
				--#("Z-Fighting/Artifacting", "No Script Output" ),
				--#("Number of Zero Area faces", "No Script Output" ),
				--#("Number of Reversed Faces", "No Script Output" ),
				--#("Number of Isolated Vertices", (isolatedVerticesCountTOTAL as string + " of " + totalVertices as string + " ("+ (if totalVertices == 0 then 0 else (100.0*isolatedVerticesCountTOTAL/totalVertices)) as string+"%)" ), isolatedVerticesCountTOTAL>0 ),
				--#("Number of Overlapping Vertices", (overlappingVerticesCountTOTAL as string + " of " + totalVertices as string + " ("+ (if totalVertices == 0 then 0 else (100.0*overlappingVerticesCountTOTAL/totalVertices)) as string+"%)" ), overlappingVerticesCountTOTAL>0 ),
				--#("Number of Overlapping Faces" , (overlappingFacesCountTOTAL as string + " of " + totalPolygons as string + " ("+ (if totalPolygons == 0 then 0 else (100.0*overlappingFacesCountTOTAL/totalPolygons)) as string+"%)" ), overlappingFacesCountTOTAL>0 ),
				--#("Naming/Organization - Non-descriptive names and no hierarchy", "See Detailed Report" ),
				--#("History Cleared", "No Script Output" ),
				--#("No Extra Elements Present in Renders", "No Script Output" ),
				--#("Number of Objects with Default Names", (defaultNameObjects.count as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*defaultNameObjects.count/objects.count)) as string+"%)"  ), defaultNameObjects.count > 0),
				#("Number of Objects with No Materials", (NoMaterialTOTAL as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*NoMaterialTOTAL/objects.count)) as string+"%)"  ), NoMaterialTOTAL > 0),
				#("Number of Missing Textures", missingBitmapFiles.count as string + " of " + (allBitmapFiles.count + missingBitmapFiles.count) as string + " (" + (if (allBitmapFiles.count + missingBitmapFiles.count) == 0 then 0 else (100.0*missingBitmapFiles.count/(allBitmapFiles.count + missingBitmapFiles.count))) as string + "%)", missingBitmapFiles.count > 0 ),
				#("Textures Zipped with Model", "No Script Output" ),
				--#("Textures Named Descriptively", "No Script Output" ),
				--#("Materials Named Descriptively", "See Detailed Report" ),
				#("UV Quality - Number of Overlapping UVs (N/A for non-human and non-animals)", (overlappingUVFacesCountTOTAL as string + " of " + totalPolygons as string + " ("+ (if totalPolygons == 0 then 0 else (100.0*overlappingUVFacesCountTOTAL/totalPolygons)) as string+"%)" ), overlappingUVFacesCountTOTAL>0 ),
				--#("Number of Hidden Objects", hiddenObjects.count as string + " of " + objects.count as string + " ("+(if objects.count == 0 then 0 else (100.0*hiddenObjects.count/objects.count)) as string+"%)",  hiddenObjects.count > 0  ),
				#("Number of Groups", "See Detailed Report")
			--] end mod
			)
			
			--] end mod
						
			if toHTML do
			(
				format "<table width=\"100\%\">\n" to:theHTMLoutScene
				format "<tr><td bgcolor=#ffffff>Scene Property</td><td  bgcolor=#ffffff>Value</td></tr>\n" to:theHTMLoutScene
			)
			
			if toXML do
			(
				format "\t\t<SceneStats>\n" to:theXMLoutScene
			)
				
			--[ mod 2011/05/15, added for summary report
			if toHTMLSummary do
			(
				format "<table width=\"100\%\">\n" to:theHTMLSummaryOutScene
				format "<tr><td bgcolor=#ffffff>&nbsp;</td><td bgcolor=#ffffff>Scene Property</td><td  bgcolor=#ffffff>Value</td></tr>\n" to:theHTMLSummaryOutScene
			)
			--] end mod
			
			local cnt = 1
			for p in thePropertiesToCheck do
			(
				cnt = 1-cnt
				local li = dotNetObject "System.Windows.Forms.ListViewItem" p[1]
				local subLi = li.SubItems.add p[2]
				li.backcolor = #(color1,color2)[cnt+1]
				if p[3] == true then li.forecolor = errorColor else if p[3] == false do li.forecolor = okColor
				append theRange li
				
				if toHTML do
				(
					local theColor = if p[3] == true then HTMLErrorColor else if p[3] == false then HTMLPassedColor else ""
					format "<tr>%%%</td>%%%</td></tr>\n" HTMLCellBGColor theColor p[1] HTMLCellBGColor theColor p[2] to:theHTMLoutScene
				)
				if toXML do
				(
					local theFS = filterString p[1] " -,.%():"
					theHeader = ""
					for i in theFS do theHeader += i
					format "\t\t\t<%>%</%>\n" theHeader p[2] theHeader to:theXMLoutScene
				)				
			)
			--[ mod 2011/05/15, output scene info to summary report
			if toHTMLSummary do 
			(
				cnt = 1
				for p in theSummaryPropertiesToCheck do
				(
					cnt = 1-cnt
					local passOrFail = "&nbsp;&nbsp;&nbsp;-"; local theColor = HTMLPassedColor
					if p[3] == true then (theColor = HTMLErrorColor; passOrFail = "FAIL" )
					else if p[3] == false then ( theColor = HTMLPassedColor; passOrFail = "PASS" )
					format "<tr>%%%</td>%%%</td>%%%</td></tr>\n" HTMLCellBGColor theColor passOrFail HTMLCellBGColor "" p[1] HTMLCellBGColor "" p[2] to:theHTMLSummaryOutScene
				)
			) -- if toHTMLSummary
			
			if toHTMLSummary do 
			(
				format "<tr>%%%</td></tr></table>\n" HTMLSpan3CellBGColor HTMLNoteColor "See the details report for exact info on what failed" to:theHTMLSummaryOutScene
			)			
			--] end mod
			
			if toHTML do 
			(
				format "</table>\n" to:theHTMLoutScene
			)			
			if toXML do
			(
				format "\t\t</SceneStats>\n" to:theXMLoutScene
			)
			
			lv.Items.AddRange theRange 
		)
		

		
		fn runAllTests =
		(
			local st = timestamp()
			max modify mode
			GeometryCheckerTools_Functions.openAllGroups openThem:true
			
			--PREPARE XML FILE
			local theTempPath  = ((GetDir #temp) + "\\CheckMate\\")
			makeDir (theTempPath+"HTML" ) all:true
			makeDir (theTempPath+"XML" ) all:true
			
			local allFiles = getFiles (theTempPath + "\\HTML\\*.*")
			for f in allFiles do deleteFile f
				
			theXMLFile =  (theTempPath+"XML\\_CheckMateReport_.xml")
			theXMLout = createFile theXMLFile
			theXMLoutScene = stringStream ""
			theXMLoutObjects = stringStream ""
			
			format "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" to:theXMLout
			format "\t<Report>\n" to:theXMLout
			format "\t\t<Header>\n" to:theXMLout
			format "\t\t\t<SceneFile>%%</SceneFile>\n" maxFilePath maxFileName to:theXMLout
			format "\t\t\t<UserName>%@%</UserName>\n"  sysInfo.username sysInfo.computername to:theXMLout
			format "\t\t\t<CreationDate>%</CreationDate>\n" localtime to:theXMLout
			format "\t\t\t<ScannerVersion>%</ScannerVersion>\n" GeometryCheckerTools_Settings.Version to:theXMLout
			format "\t\t</Header>\n" to:theXMLout
			
			--[ mod 2011/05/15, added summary output
			--PREPARE HTML SUMMARY FILE
			
			theHTMLSummaryFile = (theTempPath+"HTML\\_CheckMateSummary_.htm")
			theHTMLSummaryOut = createFile theHTMLSummaryFile
			theHTMLSummaryOutScene = stringStream ""
				
			format "<html><title>3ds Max CheckMate Summary - %</title><body bgcolor=\"#ffffff\" text=\"#000000\" font=\"Trebuchet MS\"><font face=\"Trebuchet MS\">\n" maxFileName to:theHTMLSummaryOut 
			
			format "<h2>3ds Max CheckMate Summary</h2>\n" to:theHTMLSummaryOut

			format "<table width=\"100\%\">\n" to:theHTMLSummaryOut
			format "<tr>%Max File Name</td>%%</td></tr>\n" HTMLCellBGColor HTMLCellBGColor maxFileName to:theHTMLSummaryOut
			format "<tr>%Created on</td>%%</td></tr>\n" HTMLCellBGColor HTMLCellBGColor localtime to:theHTMLSummaryOut
			format "</table>\n" to:theHTMLSummaryOut
			format "<p> <p>\n" to:theHTMLSummaryOut 
			--] end mod
			
			--PREPARE HTML FILE
			
			theHTMLFile = (theTempPath+"HTML\\_CheckMateReport_.htm")
			theHTMLout = createFile theHTMLFile
			theHTMLoutScene = stringStream ""
			theHTMLoutObjects = stringStream ""
				
			format "<html><title>3ds Max CheckMate Report - %</title><body bgcolor=\"#ffffff\" text=\"#111111\" font=\"Trebuchet MS\"><font face=\"Trebuchet MS\">\n" maxFileName to:theHTMLout 
			
			format "<h2>3ds Max CheckMate Report</h2>\n" to:theHTMLout

			format "<table width=\"100\%\">\n" to:theHTMLout
			format "<tr>%Max File Name</td>%%</td></tr>\n" HTMLCellBGColor HTMLCellBGColor maxFileName to:theHTMLout
			format "<tr>%Max File Path</td>%%</td></tr>\n" HTMLCellBGColor HTMLCellBGColor maxFilePath  to:theHTMLout
			format "<tr>%Created by</td>%%@%</td></tr>\n" HTMLCellBGColor HTMLCellBGColor sysInfo.username sysInfo.computername to:theHTMLout
			format "<tr>%Created on</td>%%</td></tr>\n" HTMLCellBGColor HTMLCellBGColor localtime to:theHTMLout
			format "<tr>%Scanner Version</td>%%</td></tr>\n" HTMLCellBGColor HTMLCellBGColor GeometryCheckerTools_Settings.Version to:theHTMLout
			format "</table>\n" to:theHTMLout
			format "<p> <p>\n" to:theHTMLout 
			
			local oldView = viewport.activeViewport 
			local oldType = viewport.getType index:oldView
			if oldType == #view_camera do oldCamera = viewport.getCamera()
			local oldTM = viewport.getTM()
			format "<table>\n" to:theHTMLout
			if GeometryCheckerTools_Settings.IncludeViewportBitmaps do
			(
				local txt1 = "<tr>"
				local txt2 = "<tr>"
				max views redraw
				for i = 1 to viewport.numViews do
				(
					viewport.activeViewport = i
					local thePaths = GeometryCheckerTools_Functions.createViewportScreenshot theHTMLFile viewName:(i as string)
					txt1 += HTMLCellBGColor + (viewport.getType index:i) as string + "</td>"
					txt2 += "<td><a href=\""+(fileNameFromPath thePaths[1])+"\"><img src=\""+(fileNameFromPath thePaths[2])+"\"></a></td>" 
				)
				format "%</tr>\n%</tr>\n" txt1 txt2 to:theHTMLout 
			)
			
			if cameras.count > 0 and GeometryCheckerTools_Settings.IncludeCameraBitmaps then
			(
				local txt1 = "<tr>"
				local txt2 = "<tr>"
				
				for c in objects where findItem Camera.classes (classof c) > 0 do
				(
					viewport.setCamera c
					max views redraw
					local thePaths = GeometryCheckerTools_Functions.createViewportScreenshot theHTMLFile
					txt1 += HTMLCellBGColor + c.name + "</td>"
					txt2 += "<td><a href=\""+(fileNameFromPath thePaths[1])+"\"><img src=\""+(fileNameFromPath thePaths[2])+"\"></a></td>" 
				)
				format "%</tr>\n%</tr>\n" txt1 txt2 to:theHTMLout 
			)
			format "</table>\n" to:theHTMLout				
			viewport.activeViewport = oldView
			if oldType == #view_camera then 
				viewport.setCamera oldCamera 
			else
				viewport.setType oldType
			viewport.setTM oldTM
			
			defaultNamesTOTAL = 0
			nonQuadTOTAL = 0
			isolatedVerticesTOTAL = 0
			isolatedVerticesCountTOTAL = 0
			tVerticesTOTAL  = 0
			tVerticesCountTOTAL  = 0
			overlappingVerticesTOTAL = 0
			overlappingVerticesCountTOTAL = 0
			overlappingFacesTOTAL = 0
			overlappingFacesCountTOTAL = 0
			overlappingUVFacesTOTAL = 0
			overlappingUVFacesCountTOTAL = 0
			NoMaterialTOTAL = 0
			MissingMapsTOTAL = 0
			MissingMapsCountTOTAL = 0
			polyCount = 0
			meshFaceCount = 0
			polyVertCount = 0
			meshVertCount = 0				
			
			--UPDATE THE DETAILED LIST AND SCENE INFO
			updateList toHTML:true toXML:true 
			if GeometryCheckerTools_Settings.IncludeFaceOrientationScreenshots do createxViewNormalsScreenshots()
			--[ mod 2011/05/15, added 3rd param
			--updateSceneInfo toHTML:true toXML:true
			updateSceneInfo toHTML:true toXML:true toHTMLSummary:true
			--] end mod 
			
			--FINALIZE XML
			format "%" (theXMLoutScene as string) to:theXMLout
			format "%" (theXMLoutObjects as string) to:theXMLout

			format "\t</Report>\n" to:theXMLout
			close theXMLout
			--
			
			--[ mod 2011/05/15
			--FINALIZE SUMMARY HTML
			format "<p> <p>\n" to:theHTMLSummaryOut 
			format "%" (theHTMLSummaryOutScene as string) to:theHTMLSummaryOut
			
			format "</body></html>\n" to:theHTMLSummaryOut 
			
			close theHTMLSummaryOut
			--] end mod 
			
			
			--FINALIZE HTML
			format "<p> <p>\n" to:theHTMLout 
			format "%" (theHTMLoutScene as string) to:theHTMLout
			format "%" (theHTMLoutObjects as string) to:theHTMLout				
			
			format "</body></html>\n" to:theHTMLout 
			
			close theHTMLout
			--if not autoName do shellLaunch theHTMLFile ""
			
			GeometryCheckerTools_Functions.openAllGroups openThem:false			
			
			format "CheckMate Update: % seconds\n" ((timestamp()-st)/1000.0)
		)

		fn refresh =
		(
			local st = timestamp()
			initSceneListView()
			runAllTests()
			--updateList()
			--updateSceneInfo()
			resizeDialog (GetDialogSize GeometryCheckerTools_Rollout)
			format "% ms\n" (timestamp()-st)		
		)			
		
		fn createHTMLFile autoName:false =
		(
			local st = timestamp()
			theHTMLFile  = ((GetDir #temp) + "\\CheckMate\\HTML\\_CheckMateReport_.htm")
			if doesFileExist theHTMLFile then
			(
				theTargetHTMLFile = if maxFilePath == "" then
					((GetDir #temp) + "\\CheckMateReport_"+ getFileNameFile maxFileName+ ".htm")
				else if not autoName then
						(maxFilePath + "CheckMateReport_"+ getFileNameFile maxFileName + ".htm")
					else
						(maxFilePath + "CheckMateReport_"+ getFileNameFile maxFileName + "\\CheckMateReport_"+ getFileNameFile maxFileName+ ".htm")

				if not autoName then				
					theTargetHTMLFile = getSaveFileName filename:theTargetHTMLFile types:"HTML File (*.htm)|*.htm|All Files (*.*)|*.*" caption:"Save HTML Report"
				else
					makeDir (getFileNamePath theTargetHTMLFile) all:true
				
				if theTargetHTMLFile != undefined do
				(
					local imageFiles = getFiles ((GetDir #temp) + "\\CheckMate\\HTML\\*.png")
					for f in imageFiles do 
					(
						targetImageFile = (getFileNamePath theTargetHTMLFile + fileNameFromPath f)
						deleteFile targetImageFile
						copyFile f targetImageFile
					)
					deleteFile theTargetHTMLFile
					result = copyFile theHTMLFile theTargetHTMLFile
					if not autoName and result do shellLaunch theTargetHTMLFile ""	
				)
			)
			else
				messagebox "No HTML Report Files Found!" title:"CheckMate Error:"
		)
		
		--[ mod 2011/05/15
		fn createHTMLSummaryFile autoName:false =
		(
			local st = timestamp()
			theHTMLSummaryFile  = ((GetDir #temp) + "\\CheckMate\\HTML\\_CheckMateSummary_.htm")
			if doesFileExist theHTMLSummaryFile then
			(
				theTargetHTMLSummaryFile = if maxFilePath == "" then
					((GetDir #temp) + "\\CheckMateSummary_"+ getFileNameFile maxFileName+ ".htm")
				else if not autoName then
						(maxFilePath + "CheckMateSummary_"+ getFileNameFile maxFileName + ".htm")
					else
						(maxFilePath + "CheckMateSummary_"+ getFileNameFile maxFileName + "\\CheckMateSummary_"+ getFileNameFile maxFileName+ ".htm")

				if not autoName then				
					theTargetHTMLSummaryFile = getSaveFileName filename:theTargetHTMLSummaryFile types:"HTML File (*.htm)|*.htm|All Files (*.*)|*.*" caption:"Save HTML Report"
				else
					makeDir (getFileNamePath theTargetHTMLSummaryFile) all:true
				
				if theTargetHTMLSummaryFile != undefined do
				(
					deleteFile theTargetHTMLSummaryFile
					result = copyFile theHTMLSummaryFile theTargetHTMLSummaryFile
					if not autoName and result do shellLaunch theTargetHTMLSummaryFile ""	
				)
			)
			else
				messagebox "No HTML Summary Files Found!" title:"CheckMate Error:"
		)
		--] end mod
		
		fn createXMLFile autoName:false =
		(
			theXMLFile =  ((GetDir #temp) + "\\CheckMate\\XML\\_CheckMateReport_.xml")
			if doesFileExist theXMLFile then
			(
				theTargetXMLFile = if maxFilePath == "" then
					((GetDir #temp) + "\\CheckMateReport_"+ getFileNameFile maxFileName+ ".xml")
				else if not autoName then
						(maxFilePath + "CheckMateReport_"+ getFileNameFile maxFileName + ".xml")
					else
						(maxFilePath + "CheckMateReport_"+ getFileNameFile maxFileName + "\\CheckMateReport_"+ getFileNameFile maxFileName+ ".xml")
					
				if not autoName then
					theTargetXMLFile = getSaveFileName filename:theTargetXMLFile types:"XML File (*.xml)|*.xml|All Files (*.*)|*.*" caption:"Save XML Report"
				else
					makeDir (getFileNamePath theTargetXMLFile) all:true
				
				if theTargetXMLFile != undefined do 
				(
					deleteFile theTargetXMLFile
					result = copyFile theXMLFile theTargetXMLFile
					if not autoName and result do shellLaunch theTargetXMLFile ""			
				)
			)
			else
				messagebox "No XML Report File Found!" title:"CheckMate Error:"
		)
		fn viewHTMLFile =
		(
			theHTMLFile  = ((GetDir #temp) + "\\CheckMate\\HTML\\_CheckMateReport_.htm")
			if doesFileExist theHTMLFile then
			(
				shellLaunch theHTMLFile ""	
			)
			else
				messagebox "No HTML Report Files Found!" title:"CheckMate Error:"
		)
		--[ mod 2011/05/15
		fn viewHTMLSummaryFile =
		(
			theHTMLSummaryFile  = ((GetDir #temp) + "\\CheckMate\\HTML\\_CheckMateSummary_.htm")
			if doesFileExist theHTMLSummaryFile then
			(
				shellLaunch theHTMLSummaryFile ""	
			)
			else
				messagebox "No HTML Summary Files Found!" title:"CheckMate Error:"
		)
		--] end mod
		fn viewXMLFile =
		(
			theXMLFile  = ((GetDir #temp) + "\\CheckMate\\XML\\_CheckMateReport_.xml")
			if doesFileExist theXMLFile then
			(
				shellLaunch theXMLFile ""	
			)
			else
				messagebox "No XML Report File Found!" title:"CheckMate Error:"
		)			
		
		
		local collectRecursive = #()
		
		fn getFoldersRecursive theRoot =
		(
			append collectRecursive theRoot
			for d in getDirectories (theRoot + "*") do getFoldersRecursive d
		)
		
		fn getFilesRecursive theRoot =
		(
			local theMaxFiles = #()
			collectRecursive = #()
			getFoldersRecursive theRoot
			for d in collectRecursive do join theMaxFiles (getFiles (d + "*.max"))
			theMaxFiles
		)
		
		fn batchCreateFiles html:false xml:false =
		(
			local theFolder = getSavePath()
			if theFolder != undefined do
			(
				--local recursive = querybox "Do you want to scan all sub-folders for scene files recursively?\n\nClick [Yes] to collect scenes from all sub-folders.\nClick [No] to collect scenes only from the selected folder." caption:"Recursive Scan?"
				local theScenes = if GeometryCheckerTools_Settings.RecursiveScanFolders then 
					getFilesRecursive theFolder
				else
					getFiles (theFolder + "\\*.max")
					
				for aFile in theScenes do
				(
					--[ mod 2011/05/26
					setVRaySilentMode()
					--] end mod
					loadMaxFile aFile quiet:true
					--[ added 2011/11/29
					if check4SpacewrapModifiers() do
					(
						deleteAllTurboSmooth()
						deleteAllMeshSmooth()
					)
					--] end added
					refresh()
					if html do createHTMLFile autoName:true
					if xml do createXMLFile autoName:true
				)
				--resetMaxFile #noprompt
				--refresh()
			)
		)		
		
		fn resizeDialog val =
		(
			--showEvents dnc_scene
			dnc_scene.pos = [2,7]
			dnc_scene.width = val.x-4
			dnc_objects.width = val.x-4
			dnc_info.width = val.x-4
			
			if GeometryCheckerTools_Settings.ListViewVisibility[1] and not GeometryCheckerTools_Settings.ListViewVisibility[2] and not GeometryCheckerTools_Settings.ListViewVisibility[3] then 
			(
				dnc_scene.height = val.y-100
				dnc_objects.pos = [2,val.y-97]
				dnc_objects.height = 48
				dnc_info.pos = [2,val.y-48]
				dnc_info.height = 48
			)
			
			if GeometryCheckerTools_Settings.ListViewVisibility[1] and GeometryCheckerTools_Settings.ListViewVisibility[2] and not GeometryCheckerTools_Settings.ListViewVisibility[3] then 
			(
				dnc_scene.height = val.y/2.0-25
				dnc_objects.pos = [2,val.y/2.0-23]
				dnc_objects.height = val.y/2.0-25
				dnc_info.pos = [2,val.y-48]
				dnc_info.height = 48
			)		
			
			if not GeometryCheckerTools_Settings.ListViewVisibility[1] and GeometryCheckerTools_Settings.ListViewVisibility[2] and GeometryCheckerTools_Settings.ListViewVisibility[3] then 
			(
				dnc_scene.height = 48
				dnc_objects.pos = [2,50]
				dnc_objects.height = val.y/2.0-25
				dnc_info.pos = [2,val.y/2+25]
				dnc_info.height = val.y/2.0-25
			)	

			if not GeometryCheckerTools_Settings.ListViewVisibility[1] and GeometryCheckerTools_Settings.ListViewVisibility[2] and not GeometryCheckerTools_Settings.ListViewVisibility[3] then 
			(
				dnc_scene.height = 48
				dnc_objects.pos = [2,50]
				dnc_objects.height = val.y-100
				dnc_info.pos = [2,val.y-48]
				dnc_info.height = 48
			)		
			
			if GeometryCheckerTools_Settings.ListViewVisibility[1] and GeometryCheckerTools_Settings.ListViewVisibility[2] and GeometryCheckerTools_Settings.ListViewVisibility[3] then 
			(
				dnc_scene.height = val.y/3.0-5
				dnc_objects.pos = [2,val.y/3.0]
				dnc_objects.height = val.y/3.0
				dnc_info.pos = [2,(val.y/3.0)*2]
				dnc_info.height = val.y/3.0
			)
			
			if not GeometryCheckerTools_Settings.ListViewVisibility[1] and not GeometryCheckerTools_Settings.ListViewVisibility[2] and GeometryCheckerTools_Settings.ListViewVisibility[3] then 
			(
				dnc_scene.height = 48
				dnc_objects.pos = [2,50]
				dnc_objects.height = 48
				dnc_info.pos = [2,100]
				dnc_info.height = val.y-100
			)		
			
			if GeometryCheckerTools_Settings.ListViewVisibility[1] and not GeometryCheckerTools_Settings.ListViewVisibility[2] and GeometryCheckerTools_Settings.ListViewVisibility[3] then 
			(
				dnc_scene.height = val.y/2.0-25
				dnc_objects.pos = [2,val.y/2.0-23]
				dnc_objects.height = 48
				dnc_info.pos = [2,val.y/2.0+25]
				dnc_info.height = val.y/2.0-25
			)			
		)	
		
	
		
	--------------------------
	--EVENT HANDLERS
	--------------------------	
		on dnc_objects ItemSelectionChanged args do
		(
			theSelection = args.item.index
			updateInfoList (theSelection+1)
			if GeometryCheckerTools_Settings.SynchronizeSelection then
			(
				try(select allObjects[theSelection+1])catch(max select none)
				if keyboard.shiftPressed do 
					if keyboard.controlPressed then
						max zoomext sel all
					else
						max zoomext sel 
			)
		)	
		
		on dnc_objects MouseDown args do
		(
			--showMethods dnc_objects
			if args.Button == args.Button.Right do
			(
				ListItem = dnc_objects.GetItemAt args.Location.x args.Location.y
				if ListItem != undefined do
				(
					SubItem = ListItem.GetSubItemAt args.Location.x args.Location.y
					theRowIndex = (ListItem.Index+1)
					
					case SubItem.name of
					(
						"material": 
						(
							if SubItem.text == "NO MATERIAL" then
								try(popupMenu GeometryCheckerTools_RCMenus.AssignMaterial pos:mouse.screenpos)catch()
							else
								try(popupMenu GeometryCheckerTools_RCMenus.AcquireMaterial pos:mouse.screenpos)catch()
						)
						"ngons":
						(
							try(popupMenu GeometryCheckerTools_RCMenus.NonQuadPoly pos:mouse.screenpos)catch()
						)
						"oververts":
						(
							try(popupMenu GeometryCheckerTools_RCMenus.EnableOverlapVxViewChecker pos:mouse.screenpos)catch()
						)
						"overfaces":
						(
							try(popupMenu GeometryCheckerTools_RCMenus.EnableOverlapFxViewChecker pos:mouse.screenpos)catch()
						)
						"overuvwfaces":
						(
							try(popupMenu GeometryCheckerTools_RCMenus.EnableOverlapUVFacesxViewChecker pos:mouse.screenpos)catch()
						)
						"isoverts":
						(
							try(popupMenu GeometryCheckerTools_RCMenus.EnableIsoVertsxViewChecker pos:mouse.screenpos)catch()
						)
						"tverts":
						(
							try(popupMenu GeometryCheckerTools_RCMenus.EnableTVertsxViewChecker pos:mouse.screenpos)catch()
						)
						
					)
				)
			)
		)
		
		on dnc_info ItemSelectionChanged args do
		(
			theInfoSelection = args.item.index
		)
		
		on dnc_info MouseDown args do
		(
			if args.Button == args.Button.Right do
			(
				try
				(
					if objectProblemInfo[theSelection+1][theInfoSelection+1][4] != undefined do 
						popupMenu objectProblemInfo[theSelection+1][theInfoSelection+1][4] pos:mouse.screenpos
				)catch()
			)
		)		

		on dnc_scene ColumnClick args do
		(
			if keyboard.controlPressed then
				GeometryCheckerTools_Settings.ListViewVisibility	= #(true,true,true)
			else
			(
				if keyboard.shiftPressed then
				(
					GeometryCheckerTools_Settings.ListViewVisibility	= #(true,false,false)
				)
				else
				(
					GeometryCheckerTools_Settings.ListViewVisibility[1] = not GeometryCheckerTools_Settings.ListViewVisibility[1]
					if not GeometryCheckerTools_Settings.ListViewVisibility[1] and not GeometryCheckerTools_Settings.ListViewVisibility[2] and not GeometryCheckerTools_Settings.ListViewVisibility[3] do GeometryCheckerTools_Settings.ListViewVisibility[1] = true
				)
			)
			resizeDialog (GetDialogSize GeometryCheckerTools_Rollout)		
		)	
		on dnc_objects ColumnClick args do
		(
			if keyboard.controlPressed then
				GeometryCheckerTools_Settings.ListViewVisibility	= #(true,true,true)
			else
			(
				if keyboard.shiftPressed then
				(
					GeometryCheckerTools_Settings.ListViewVisibility	= #(false,true,false)
				)
				else
				(
					GeometryCheckerTools_Settings.ListViewVisibility[2] = not GeometryCheckerTools_Settings.ListViewVisibility[2]
					if not GeometryCheckerTools_Settings.ListViewVisibility[1] and not GeometryCheckerTools_Settings.ListViewVisibility[2] and not GeometryCheckerTools_Settings.ListViewVisibility[3] do GeometryCheckerTools_Settings.ListViewVisibility[2] = true
				)
			)
			resizeDialog (GetDialogSize GeometryCheckerTools_Rollout)		
		)
		on dnc_info ColumnClick args do
		(
			if keyboard.controlPressed then
				GeometryCheckerTools_Settings.ListViewVisibility	= #(true,true,true)
			else
			(
				if keyboard.shiftPressed then
				(
					GeometryCheckerTools_Settings.ListViewVisibility	= #(false,false,true)
				)
				else
				(
					GeometryCheckerTools_Settings.ListViewVisibility[3] = not GeometryCheckerTools_Settings.ListViewVisibility[3]
					if not GeometryCheckerTools_Settings.ListViewVisibility[1] and not GeometryCheckerTools_Settings.ListViewVisibility[2] and not GeometryCheckerTools_Settings.ListViewVisibility[3] do GeometryCheckerTools_Settings.ListViewVisibility[3] = true
				)
			)
			resizeDialog (GetDialogSize GeometryCheckerTools_Rollout)		
		)
		
		on GeometryCheckerTools_Rollout resized val do
		(
			resizeDialog val
			setIniSetting (GetDir #plugcfg + "\\GeometryCheckerTools.ini") "Dialog" "Size" (val as string)
		)
		
		on GeometryCheckerTools_Rollout open do
		(
			local val = execute (getIniSetting  IniFile "xView" "OverlappingVertsTolerance")
			if val == OK do val = 0.0001
			GeometryCheckerTools_Settings.OverlappingVertsTolerance = val

			val = execute (getIniSetting IniFile "xView" "OverlappingFacesTolerance" )
			if val == OK do val = 0.0001
			GeometryCheckerTools_Settings.OverlappingFacesTolerance = val
			
			val = execute (getIniSetting IniFile "xView" "FaceOrientationScreenshotsCount" )
			if val == OK do val = 5
			GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount = val

		
			initSceneListView()
			initObjectListView()
			initInfoListView()
			--refresh()
		)
		
		on GeometryCheckerTools_Rollout close do
		(
			setIniSetting IniFile "xView" "FaceOrientationScreenshotsCount" (GeometryCheckerTools_Settings.FaceOrientationScreenshotsCount as string)
		)
	)--end rollout
	

	if (maxVersion())[1] / 1000 > 11 then
	(
		local thePos = execute (getIniSetting (GetDir #plugcfg + "\\GeometryCheckerTools.ini") "Dialog" "Position")
		if thePos == OK do thePos = [10,10]
		if thePos.x > sysinfo.DesktopSize.x-200 do thePos.x = sysinfo.DesktopSize.x-200
		if thePos.y > sysinfo.DesktopSize.y-200 do thePos.y = sysinfo.DesktopSize.y-200
		if thePos.x < 0 do thePos.x = 10
		if thePos.y < 0 do thePos.y = 10
			
		theSize = execute (getIniSetting (GetDir #plugcfg + "\\GeometryCheckerTools.ini") "Dialog" "Size")
		if theSize == OK do theSize = [1240,900]
		if theSize.x < 400 do theSize.x = 400
		if theSize.y < 300 do theSize.y = 300
		try(destroyDialog GeometryCheckerTools_Rollout )catch()
		createDialog GeometryCheckerTools_Rollout theSize.x theSize.y thePos.x thePos.y menu:GeometryCheckerTools_mainmenu style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox, #style_resizing, #style_maximizebox  )
		GeometryCheckerTools_Rollout.title = "Check-Mate : "+GeometryCheckerTools_Settings.Version
		GeometryCheckerTools_Rollout.resized theSize
	)
	else messagebox "This script requires 3ds Max 2010 or higher." title:"Geometry Checker Tools"
	
)--end script 