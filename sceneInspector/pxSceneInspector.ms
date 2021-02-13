macroScript SceneInspector category:"pX Tools" 
(
--=====================================================================
/*
	- pX Scene Inspector 1.01 ---------------------------------------------------------------------------- 
	- Run several tests for scene objects, analysing its mesh topology and node properties
	- Tested with Max 9.0
	- Author: Denys Almaral Rodríguez, 
	- TurboSquid member name: Denys Almaral - email- pxtracer@gmail.com		
	- Installation: 
			Run this script and Max will automatically generate a Macro file in user macro directory.
			(OR - copy this .mcr file to User macros directory and restart Max.)
	          - After that: go to Customize user interface -> Menus -> Category find "pX Tools"
	          - Grab and drop SceneInspector to any menu or tool bar you want.
     - The script support batch processing of multiple MAX files.
	- Report Output formats: HTML, XML, CSV  -> 
	- The user choose the output folder and names for reports output of single scene - When processing multiple scenes the files are automatically named.
	
	- Read more information at: "Scene Inspector README.doc"
	
---------------------------------------------
	VERSION HISTORY	
	-  2012-dec-2 (Compatibility with Win 64bits, .Net listviews )
---------------------------------------------

-- - - - - -------------- pxSceneInspector CONTENT INDEX  ------------------------ - - ---- - - -

--structs:
struct TArray( arr = #() ) 			--to store an array in ListView Tag
struct TSceneTotals					--Scene total values, summary
struct ListViewClass				--Class to handle ListView controls
	function Int		
	function Refresh
struct TSceneInfoCopy				--store all scene info and save to file
	function SaveToXML
	function SaveToCSV
	function SaveToHTML

--functions:
function IsIgnoreModifier m 				--Test for subdivition modifiers like turboSmooth
function PrepareObject o					--Prepares and object for future inspection
function PrepareSceneObjects				--Prepares all scene objects
funciton RestoreObjectModifiers o			--Restore modifications did by PrepareObject
function RestoreModifiers					--Restore all scene objects
function Update_ObjectsInfo				--Getting basic info, Objects Info listView
function Build_SummaryInfo				--Getting summary info data
function Start_MeshAnalysis				--Mesh Analysis: overlapping faces, flipped, etc.
function GetCleanKeyName KeyStr			--handling user properties key names
function START_UPDATE_PROCESS   	--Main procedure, processing scene
function SelectionChanged 					--CallBack function
funciton MainInit							--Main initializaiton code.
function CleanUserProps Obj 				--Remove SceneInspector user properties
function MarkCleanObjects					--find clean object on listviews data
function GetCapturesAndRender                --viewport captures and render

function ScanMaxFiles IniDir 	               -- get all max files in Dir and subdirectories recursivelly
function START_BATCH_PROCESS          -- inspecting max files in batch mode	
function lvDataToXML 						--get ListView internal data structure and write it to xml class
function lvDataToCSV 					     --get ListView internal data structure and write it to CSV file
function lvDataToHTML						--get ListView internal data structure and write it to HTML file

--Rollouts:
rollout SubObjSelect 			--Sub-Object Face/Verts selector dialog	
rollout ShowFilesList               -- show missing files list 
rollout InspectorReports		--Main InspectorReports rollout
rollout BatchProcessing			--Batch Processing max scenes
rollout DesignerTools			--By object Designer tools
rollout DefOptions	
------ - - - - --------------------- pxSceneInspector CONTENT INDEX END--------------------------------- -- - - - - - -- - -
*/	

			
	local  rf_MainWin	
	local ObjectsInfoListView,  SummaryInfoListView,  MeshAnalysisListView   --ListViewClass
	local ResultsBySceneListView
	local roll_InspectorReports 
	local roll_SubObjSelect
	local roll_BatchProcessing         --Rollout references
	local roll_Options                   
	
	local TheObjects = #()           --Objects to be inspected
	
	-- "listview data" is a matrix of data rows to show in listview
	--  array of array of #(value, Color,  isBold, instanceObject*,,, )
    -- instanceObject* appers at first column only with object name	
	
	local ObjectsInfo = #()			--listview data
	local SummaryInfo = #()  		--listview data
	local MeshAnalysisInfo = #() 	--listview data
	local MissingFiles = #()  			-- strings
	local ResultsByScene = #() 		--listview data
	local InfoCopyByScene = #()   --Array of TSceneInfoCopy
	local ObjectsInfoColumns = #( #("ObjName",80), #("Class",40), #("Verts",40),  #("Polys",40), #("Tris",55), #("NGons", 55), #("Scale",55 ), #("Parent",55 ), #("Material",55 ), #("HiddenVP",60),#("DefName",50)  )  
	local SummaryColumns = #( #("Desc",180), #("Value",40), #("Perc",40), #("Objs",40) )
	local MeshAnalysisColumns = #( #("ObjName",80), #("IsoVerts",55), #("OvVerts",55), #("OvFaces",55), #("OvUVFaces",55),  #("FlippedFaces",55) )
	local ResultsBySceneColumns = #(#("File_name",200), #("Objects",50), #("Problems",55),#("Time_Secs",70))
	local VPcaptures = #()	
	local IgnoreModifiers = #(TurboSmooth, MeshSmooth, SpacewarpModifier)	
	local TEMPMOD = "TEMPMOD_"
	local TEMPDISABLED = "TEMPDISABLED_"
	--listview colors
	local COLOR_RED = color 0 0 245,  
			COLOR_GRAY = color 80 100 120, 
			COLOR_GREEN = color 0 100 0
	local up_DefaultName = "siup_DefaultName"
	local up_NumErrors = "siup_NumErrors"
	local up_TriSel = "siup_fSel_Triangles"
	local up_NGonsSel = "siup_fSel_NGons"
	local up_IsoVertsSel = "siup_vSel_Isolated_Verts"
	local up_OvVertsSel = "siup_vSel_Overlapping_Verts"
	local up_OvFacesSel = "siup_fSel_Overlapping_Faces"
	local up_OvUVFacesSel = "siup_mSel_Overlapping_UV_Faces"
	local up_FlippedFacesSel = "siup_fSel_Flipped_Faces"
	local UserProp_SelKeys = #( up_TriSel, up_NGonsSel, up_IsoVertsSel, up_OvVertsSel, up_OvFacesSel, up_FlippedFacesSel ) 
	local key_SelTypePos = 6 --position in Selkeys strings that define type: f - face  v - vertices  u - UV faces
	local sirep_prefix = "siRep_"
	
    local mainProgressBar = undefined
    global SelectionChanged_func	
	local EnabledEvents = true
    local BatchMode = false	
	
	local BatchMaxFiles = #()			--
	
	--some checkmate rules
	local cm_TRIS_LIMIT = 10  --percent % 
	
	
    --START including units--
	/*--================ -  pX Check Object Unit =======================
 - Author: Denys Almaral 
 -last modified 2012-march-22 
 - Checking object mesh for correct topology and properties

CONTENT INDEX

struct TFaceData
struct TNonQuadsInfo 
function FindNonQuads EPolyObj	-> TNonQuadsInfo                  
function FindIsoVerts EPolyObj	-> BitArray                        -- Find isolated vertices
function FindOverlappingVerts EPolyObj   -> BitArray               -- Overlaping Vertices 
	function GetFaceData EPolyObj Fidx	-> TFaceData
	function TestBBoxCollision bbMax1 bbMin1 bbMax2 bbMin2 	->  Boolean         --Collision of bounding boxes
	function TestCollisionPolyPoly arrVerts1 arrVerts2	->  Boolean                   --Collision of 2D polygons
	function TestOverlapFaces f1 f2	->   boolean                                           
function FindOverlappingFaces EPolyObj  -> bitArray									-- Find overlapping faces
function FindOverlappingMapFaces GeomObj MapChannel:1  -> bitArray  			--Find Overlapping UV Map faces (uses Unwarp UVW function)
	function BuildFaceGraph EPolyObj  -> Array o fTFlipFaceInfo					-- builds face interconections graph
	function BitArrayXOR a b = (a*(-b)) + ((-a)*b)  -> bitArray						--  bitArrays XOR
function FindFlippedFaces EPolyObj  -> bitArray									    	-- find flipped faces
function IsMaterialDefaultName														-- Detect material default name
*/

--Returning structure info by function FindNonQuads
struct TNonQuadsInfo 
(
	PolyCount = 0,
	TriCount = 0,
	VertCount = 0,
	NgonsCount = 0,
	TriPolys = #{},
	NgonsPolys = #{}
)

struct TFaceData
(
	FaceIdx, 	    --integer
	VertsIdx = #(),
	Verts = #(),
	bbMin ,  		--point3
	bbMax,			--point3
	Normal 	        --point3
)

struct TFlipFaceInfo
(
	Verts = #(),   --array of Integer
	Links = #(),   --array of Integer Neiborhood faces		
	FlippedLink = #{}, --array of Boolean		
	SegmNLinked = #{}
)

--config values

local OvVerts_Tolerance = 0.0001
local OvFaces_Tolerance = 0.0001

--frequently used functinos stored in user variables to faster access
 polyop_getVert = polyop.getVert
 polyop_getFaceVerts = polyop.getFaceVerts
 polyop_getFaceNormal = polyop.getFaceNormal
 polyop_getFacesUsingVert = polyop.getFacesUsingVert


-- FindNonQuads ---------------------------------------------------------------
-- Scan EPoly faces finding triangles and Ngons 
-- RETURNS: Results as TNonQuadsInfo structure
function FindNonQuads EPolyObj =
(
	Result = TNOnQuadsInfo()
	Result.PolyCount = polyop.getNumFaces EPolyObj
	Result.VertCount = polyop.getNumVerts EPolyObj
	for i=1 to Result.PolyCount do
	(
		Deg = polyop.getFaceDeg EPolyObj i
		if Deg !=4 then 
		(
			if Deg > 4 then 
			(
				Result.NgonsCount += 1 
				Result.NgonsPolys[i] = true
			) else
			( 
				Result.TriCount += 1 
				Result.TriPolys[i] = true
			)
		)

	)
	Result
)

-- FindIsoVerts --------------------------------------------------------------------
-- Get Isolated vertices using getVertsUsingFace function
-- Creates a list of secuential numbers using internal functions is always faster than scripted loop
-- created a BitArray then convert it to array of integer to have a list of all faces and call getVertsUsingFace
-- RETURNS: A BitArray with isolated vertices set.
function FindIsoVerts EPolyObj =
(	 
	bList = #{}
	bList.count = Polyop.GetNumFaces EPolyObj	 
	fList = (-bList) as array
	---TODO: todo lo de arriba se puede cambiar por: bList = #{1..(Polyop.GetNumFaces EPolyObj)}
	Result = -( polyop.getVertsUsingFace EPolyObj fList )
)

-- FindOverlappingVertsOld ---- SLOW --
-- Using a simple approach, testing vertex by vertex
-- iteration grow exponential: (n*(n-1)/2
function FindOverlappingVertsOld EPolyObj  = 
(
	N = polyop.getNumVerts EPolyObj 
	Result = #{}
	Result.count = N
	for i=1 to N-1 do
	(
		for j=(i+1) to N do
		(
			v1 = polyop.getVert EPolyObj i
			v2 = polyop.getVert EPolyObj j
			d = (distance v1 v2)
			--d = (abs v1[1]-v2[1]) + (abs v1[2]-v2[2]) + (abs v1[3]-v2[3]) 
			if d<=OvVerts_Tolerance then
			(
				Result[i] = true
				Result[j] = true
			)	
		)
	)
	Result
)

-- FindOverlappingVerts ------- FASTER  ----------------------------
-- using space partitioning, trying to group vertexes in blocks
-- delay is not exponential, it increase lineal
-- 10 times faster 2000verts /  50 times faster 10000 verts
function FindOverlappingVerts EPolyObj =
(
	local bb = 5.0 --Desired vertex count by block (keep low, in practice could be 10 times more)
	local N = polyop.getNumVerts EPolyObj
	local val = N / bb 								-- numblocks					
	val = pow val (1.0/3) 					-- cube root
	local dim = (int val) + 1  						-- space partition dimesion dim^3
	
	local addborder = [1,1,1]*(OvVerts_Tolerance*dim)
	local Minbbox = EPolyObj.min - addborder
	local Maxbbox = EPolyObj.max + addborder
	
	local bxSize = (Maxbbox.x - Minbbox.x) / dim
	local bySize = (Maxbbox.y - Minbbox.y) / dim
	local bzSize = (Maxbbox.z - Minbbox.z) / dim
	
	-- Space partitions multidimensional array - 3D spa[x,y,z] of integer
	local spa = #()
	spa.count = dim		
	for xi = 1 to dim do
	(
		spa[xi] = #()
		spa[xi].count = dim		
		for yi = 1 to dim do 
		(
			spa[xi][yi] = #()
			spa[xi][yi].count = dim			
			for zi = 1 to dim do
			(
				spa[xi][yi][zi] = #()
			)
		)
	)
	-- for each vertex get its apropiate position in partitioned space
	for i = 1 to N do
	(
		local v = polyop_getVert EPolyObj i
		local dv = v - Minbbox
		local posx = int (dv.x / bxSize) + 1
		local posx2 = int ((dv.x + OvVerts_Tolerance*2)/ bxSize) + 1
		local posy = int (dv.y / bySize) +1
		local posy2 = int((dv.y + OvVerts_Tolerance*2)/ bySize) + 1
		local posz =int (dv.z / bzSize) + 1
		local posz2 = int ((dv.z + OvVerts_Tolerance*2)/bzSize) + 1
		
		if posx>dim then posx=dim else if posx<0 then posx=0
		if posy>dim then posy=dim else if posy<0 then posy=0
		if posz>dim then posz=dim else if posz<0 then posz=0
				
		append spa[posx][posy][posz]  #(i,v)
		
		if posx2>dim then posx2=dim else if posx2<0 then posx2=0
		if posy2>dim then posy2=dim else if posy2<0 then posy2=0
		if posz2>dim then posz2=dim else if posz2<0 then posz2=0
		
		if ((posx!=posx2) or (posy!=posy2) or (posz!=posz2)) then
		(
			append spa[posx2][posy2][posz2] #(i,v)
		)
	)
	
	--finding coicident vertices by blocks
	local Result = #{}
	
	for xi = 1 to dim do
		for yi = 1 to dim do 
			for zi = 1 to dim do
			(
				local  vlist = spa[xi][yi][zi]
				local  vcount = vlist.count 
				
				for i=1 to vcount-1 do
					for j=i+1 to vcount do
						if (distance vlist[i][2] vlist[j][2]) <= OvVerts_Tolerance then
						(
							Result[vlist[i][1]] = true
							Result[vlist[j][1]] = true
						)	
					
				
			)
		
	Result
)

-- Returns TFaceData structure
function GetFaceData EPolyObj Fidx =
(
	R = TFaceData()
	R.FaceIdx = Fidx
	R.VertsIdx = polyop_getFaceVerts EPolyObj Fidx
    R.Verts.count = R.VertsIdx.count
	for i=1 to R.VertsIdx.count do
	(
		v = polyop_getVert EPolyObj R.VertsIdx[i]
		R.Verts[i]  = v
		if i==1 then
		(
			R.bbMin =copy v
			R.bbMax =copy v
		) 		
		
		if v.x > R.bbMax.x then R.bbMax.x = v.x
		if v.y > R.bbMax.y then R.bbMax.y = v.y
		if v.z > R.bbMax.z then R.bbMax.z = v.z
		if v.x < R.bbMin.x  then R.bbMin.x = v.x
		if v.y < R.bbMin.y then R.bbMin.y = v.y
		if v.z < R.bbMin.z then R.bbMin.z = v.z
		
	)		
	R.Normal = normalize (polyop_getFaceNormal EPolyObj Fidx)
	Result = R
)

--TestBBoxCollision---------------------------------------
-- all parameters point3 - test if bounding box 1 intersects with boundin box 2
-- RETURNS: boolenan
function TestBBoxCollision bbMax1 bbMin1 bbMax2 bbMin2 =
(
	--intersection X
	ibbMax = copy bbMax1
	if bbMax2.x < bbMax1.x then ibbMax.x = bbMax2.x
	if bbMax2.y < bbMax1.y then ibbMax.y = bbMax2.y
	if bbMax2.z < bbMax1.z then ibbMax.z = bbMax2.z
	ibbMin = copy bbMin1
	if bbMin2.x > bbMin1.x then ibbMin.x = bbMin2.x
	if bbMin2.y > bbMin1.y then ibbMin.y = bbMin2.y
	if bbMin2.z > bbMin1.z then ibbMin.z = bbMin2.z
	Result = ( (ibbMin.x <= ibbMax.x ) and (ibbMin.y <= ibbMax.y) and (ibbMin.z <= ibbMax.z) )
)

--TestCollisionPolyPoly ----------------------------------
--Poly1 Poly2 : array of Point3
--RETURNS: BOOLEAN
function TestCollisionPolyPoly arrVerts1 arrVerts2 =
(
	-- assuming they collide: try to prove the opposite
	Result = true
	for SwapPolys=1 to 2 while Result do
	(
		if SwapPolys==2 then
		(
			TempArr = arrVerts1
			arrVerts1 = arrVerts2
			arrVerts2 = TempArr
		)
		for i=1 to arrVerts1.count while Result do
		(
			if i<arrVerts1.count then i2 = i+1 else i2=1
			--  a segment vector from Poly1	
			vect_A = arrVerts1[i2] - arrVerts1[i]
			RightSideCount = 0
			j = 1
			--Testing if all vertexes from poly2 are at Right Side of vect_A segment
			do
			(			
				-- a segment vector from segment base of poly1 to poly2 vertex
				vect_B = arrVerts2[j] - arrVerts1[i]
				R = cross vect_B vect_A				
				if ((R.z+0.001) >= 0) then RightSideCount += 1
				j += 1
			) while ((( R.z+0.001 )>=0  ) and ( j<=arrVerts2.count ) )
			
			if RightSideCount == arrVerts2.count then Result = false
		)
	)
	Result
)

--TestOverlapFaces------------------------------------------------
-- f1, f2 : TDataFace
--RETURNS: boolean
function TestOverlapFaces f1 f2 =
(
	Result = false
	--Testing Normals similarity 
	d = distance f1.normal f2.normal 
	if d<=OvFaces_Tolerance then
	(
		-- Testing Faces bounding box collision
		if TestBBoxCollision f1.bbMax f1.bbMin f2.bbMax f2.bbMin then
		(
			-- Projecting Face 1 and 2 into Face 1 plane 2D
			projectMat =inverse (matrixFromNormal f1.normal)
			poly1 = #()
			poly2 = #()
			poly1.count = f1.verts.count
			poly2.count = f2.verts.count
			
			poly1[1] = f1.verts[1] * projectMat
			anyZ = poly1[1].z
			poly1[1].z = 0
			for i=2 to f1.verts.count do 
			(
				poly1[i] = f1.verts[i] * projectMat							
				poly1[i].z = 0
			)
			
			poly2[1] = f2.verts[1] * projectMat
			maxdZ = abs( poly2[1].z - anyZ )
			for i=2 to f2.verts.count do
			(
				poly2[i] = f2.verts[i] * projectMat						
				poly2[i].z = 0
			)		
						
			-- Testing for distance between surfaces
			if maxdZ <= OvFaces_Tolerance then
			(
				--Testing 2D polygons colision
				Result = TestCollisionPolyPoly Poly1 Poly2	
			)
		)
	) 
	Result
)

-- FindOverlappingFacesOld ---- SLOW --
-- Using a simple approach, testing every face by face
-- iteration grow exponential: (n*(n-1)/2
function FindOverlappingFacesOld EPolyObj  = 
(
	N = polyop.getNumFaces EPolyObj 
	Result = #{}
	Result.count = N
	for i=1 to N-1 do
	(
		for j=(i+1) to N do
		(
			f1 = GetFaceData EPolyObj i
			f2 = GetFaceData EPolyObj j
			if (TestOverlapFaces f1 f2 OvFaces_Tolerance) then
			(
				Result[i] = true
				Result[j] = true
			)	
		)
	)
	Result
)

-- FindOverlappingFacesOld ---- FASTER --
-- partitioning by normal vector orientation
function FindOverlappingFaces EPolyObj  = 
(
	bb = 5.0 -- Desired faces by list
	N = polyop.getNumFaces EPolyObj 
	Result = #{}
	Result.count = N
	val = (N/8.0) / bb
	--dimension of 2D array of lists
	dim = (int (sqrt val)) + 1
	psize = (1 + OvFaces_Tolerance*3) / dim    --adding Tolerance*3 ensure Posx/y never greater than dim
    --print dim
	--print psize
	
	-- subdivition by 8 octants first 
	spa = #()
	spa.count = 8
	--buiding matrix of 8 octants of [dim, dim] of FaceData List
	for i=1 to spa.count do
	(
		spa[i] = #()
		spa[i].count = dim
		for x = 1 to dim do
		(
			spa[i][x] = #()
			spa[i][x].count = dim
			for y  = 1 to dim do spa[i][x][y] = #()
		)
	)
	
	--distribution of faces 
	for i=1 to N do
	(
		fd = GetFaceData EPolyObj i
		n1 = fd.Normal
		n2 = fd.Normal + OvFaces_Tolerance*2 --ovoid bounding limits problem
		if n1.x > 0 then xbit = 1 else xbit = 0
		if n1.y > 0 then ybit = 2 else ybit = 0
		if n1.z > 0 then zbit = 4 else zbit = 0
		Octant1 = ( bit.or (bit.or xbit ybit) zbit ) +1	
		
		if n2.x > 0 then xbit = 1 else xbit = 0
		if n2.y > 0 then ybit = 2 else ybit = 0
		if n2.z > 0 then zbit = 4 else zbit = 0
		Octant2 = ( bit.or (bit.or xbit ybit) zbit ) +1	
		
		
		posx1 = int((abs n1.x) / psize ) + 1
		posy1 = int((abs n1.y) / psize ) + 1
		posx2 = int((abs n2.x) / psize ) + 1
		posy2 = int((abs n2.y) / psize ) + 1
		
		if (posx1>dim) or (posy1>dim) then print "bad thing posx1"
		if (posx2>dim) or (posy2>dim) then print "bad thing posx2"
		
		--if i>=4 then break()
		
		append spa[Octant1][posx1][posy1] fd
		
		if (Octant2 != Octant1) then 
		( 
			append spa[Octant2][posx1][posy1] fd
			---print "Octant2 != Octant1"
		)
				
		if (posx2 != posx1) or (posy2 != posy1) then
		(			
			append spa[octant1][posx2][posy2] fd
			--print "pos2 != pos1"
			if Octant2 !=Octant1 then
			(
				append spa[octant2][posx2][posy2] fd
				--print "pos2 != pos1 and Octan2 != Octant1 "
			)
		)		
	)
	
	Result = #{}
	maxcount  = 0
	for oct = 1 to 8 do
		for x=1 to dim do
			for y=1 to dim do
			(
				fList = spa[oct][x][y]
				for i=1 to fList.count-1 do
						for j=i+1 to flist.count do
						(
							if flist.count>maxcount then 
							(
								maxcount = flist.count
								--print maxcount
							)
							if (TestOverlapFaces fList[i] fList[j] ) then
						    --if false then
							(
								Result[fList[i].FaceIdx] = true
								Result[fList[j].FaceIdx] = true
							)								
						)
						
			)
			
	Result
)

-- 
function FindOverlappingMapFaces GeomObj MapChannel:1 = 
(
	 max modify mode
	 select GeomObj
	local m = unwrap_uvw()
	addModifier GeomObj m
	m.setMapChannel MapChannel
	m.setTVSubObjectMode 3
	m.selectOverlappedFaces()
	Result = m.getSelectedPolygons()	
	deleteModifier GeomObj m
	Result
)

	

-- BuildFaceGraph ---------------------
-- build a graph finding links between near faces and mark them as flipped or not
-- this function could be useful for navigation mesh algorithms ;)
-- RETURNS: Array of TFlipFaceInfo
function BuildFaceGraph EPolyObj =
(
	local VertFaces=#()     ---array of bitarray    -- used faces by vertex
	local FaceGraph = #()  ---array of TFlipFaceInfo
	local FlippedLinkCount = 0
	
	-- Storing faces used by  vertex
	VertFaces.count = polyop.getNumVerts EPolyObj 
	for i=1 to VertFaces.count do
	(
		VertFaces[i] = polyop_getFacesUsingVert EPolyObj #(i)
	)
	
	FaceGraph.count =  polyop.getNumFaces EPolyObj
	for i=1 to FaceGraph.count do
	(
		FaceGraph[i] = TFlipFaceInfo()
		FaceGraph[i].Verts = polyop_getFaceVerts EPolyObj i
	)		
	
	local kverts --neightboor face verts
	local v1, v2, j2 
	local v1neibor_Idx, v2neibor_Idx			
						
	--Building the Graph!
	-- finding faces connections and detecting flipped neiboor faces
	for i=1 to  FaceGraph.count do
	(			
		local verts = FaceGraph[i].verts

		--format "\nFace #: % conected with: " i			
		
		for j1=1 to verts.count do
		(
			j2 = j1 + 1
			if j2 > verts.count then j2 = 1
			v1 = verts[j1]
			v2 = verts[j2]				
			LinkFound = false
			-- Lets find neibor face sharing Edge v1 --> v2
			for k in VertFaces[v1] while not FaceGraph[i].SegmNLinked[j1] do
			(
				
				--K is the neibor faces that share vetex v1 with current face
				-- we are looking a segment shared with v1->v2 segment of current face
				
				if k!=i then  --if not the same face
				(						
					kverts = FaceGraph[k].verts
					--find where is located v1  in this neibor face
					v1neibor_idx = findItem kverts v1						
					v2neibor_idx = v1neibor_Idx - 1
					--first vertex conect with last one
					if v2neibor_Idx == 0  then v2neibor_Idx = kverts.count
											
					--if vertices are in reverse order they are linked and not flipped
					if kverts[v2neibor_idx] == v2 then
					(							
						append FaceGraph[i].Links k	
						FaceGraph[i].SegmNLinked[j1] = true
						linkFound = true
						--link the other face also *new
						append FaceGraph[k].Links i
						FaceGraph[k].SegmNLinked[v1neibor_idx] = true
						--format "->% " k
					) else (
							v2neibor_idx = v1neibor_Idx + 1 
							if v2neibor_Idx > kverts.count  then v2neibor_Idx = 1
							
							--if vertices are in the same order they are linked and Flipped!
							if Kverts[v2neibor_idx] == v2 then
							(								
								append FaceGraph[i].Links k	
								FaceGraph[i].SegmNLinked[j1] = true
								linkFound = true
								FaceGraph[i].FlippedLink[FaceGraph[i].Links.count] = true
								FlippedLinkCount += 1
								--link the other face also *new
								append FaceGraph[k].Links i
								FaceGraph[k].SegmNLinked[v1neibor_idx] = true
								FaceGraph[k].FlippedLink[FaceGraph[k].Links.count] = true
								--format "->%* " k
							)
						)
											
				)
			)				
		)
		
	)
	--format "\n"
	
	-- patch to force abort if there is not flipped link 
	if FlippedLinkCount==0 then FaceGraph = #()
		
	Result = FaceGraph		
)

--  BitArray XOR  missed in Maxscript
-- if a.count !=  b.count then Result will be erroneous..
function BitArrayXOR a b = (a*(-b)) + ((-a)*b)

--  FindFlippedFaces EPolyObj  
function FindFlippedFaces EPolyObj = 
(
	Local FaceGraph = #()		
	Local Face
	FaceGraph = BuildFaceGraph EPolyObj
	
	
	--debug: prints link info
	/*
	for i=1 to FaceGraph.count do
	(
		face = FaceGraph[i]
		Format "Face#: % - Links:" i
		for j = 1 to face.Links.count do
		(
			format " %" face.links[j] 
			if face.FlippedLink[j] then format "*"
		)
		format "\n"
	)	*/
	
	Local CurrList = #{1}
	Local NextList = #{}		
	Local Visited = #{1}		
	Local Flipped = #{}
	Local VisitedChunk = #{1}		
	Local NotVisited = #()
	Visited.count = FaceGraph.count 
	Flipped.count = FaceGraph.count
	VisitedChunk.count = FaceGraph.count		
	
			
	if (FaceGraph.count>1)  then
	(
		do 
		(
			while ((not CurrList.isEmpty) and ( not keyboard.escPressed )) do
			(
				For FaceIdx in CurrList do
				(			
					--debug
					--redrawViews()
					--sleep 0.1
					For i = 1 to FaceGraph[FaceIdx].links.count do
					(
						LinkFace = FaceGraph[FaceIdx].links[i]
						if not Visited[LinkFace] then
						(
							Visited[LinkFace] = true
							VisitedChunk[LinkFace] = true
							--if  flipped faces link then mark LinkFace face as oppsite Flipped value
							if FaceGraph[FaceIdx].FlippedLink[i] then 
							(
								Flipped[LinkFace] = not Flipped[FaceIdx]								
							) else (
								Flipped[LinkFace] = Flipped[FaceIdx]
							)								
							--store in nextList bitArray
							NextList[LinkFace] = true
						)
					)
				)				
				--The swap
				
				CurrList = NextList
				NextList = #{}									
			)--while 
			
			-- if flipped faces are greater than not flipped then invert bits doing XOR 
			if (Flipped * VisitedChunk).numberSet > (VisitedChunk.numberSet / 2) 
			then Flipped = bitArrayXOR Flipped VisitedChunk
			
			-- not visited faces? there is more unconnected chunks?
			NotVisited = ((-Visited) as array)
			
			if NotVisited.count>0 then 
			(
				-- get the first not visited face
				CurrList[ NotVisited[1] ] = true
				Visited[ NotVisited[1] ] = true
				VisitedChunk = #{}
				VisitedChunk.count = Visited.count
				VisitedChunk [ NotVisited[1] ] = true
				NextList = #{}
				
			)
				
		) while (not Keyboard.escPressed) and (NotVisited.count>0)
	) 
			
	Result = Flipped
)

-- IsMaterialDefaultName 
-- Obj: Node
function IsMaterialDefaultName NodeObj =
(	
	if NodeObj.material != undefined then
	(
		Result = (matchPattern NodeObj.material.name pattern:"?? - Default*") or (matchPattern NodeObj.material.name pattern:"Standard_*")
	)  Else Result = true
	Result
)	
--END ================ -  pX Check Object Unit END ======================= END

	/* =======================  pX Check Scene Unit ====================
  
  - Author: Denys Almaral
  -last modified 2012-march-22
  
  CONTENT INDEX

function detectDefaultNames 	-- DetectDefaultNames ( from TurboSquid GCT )
function GetMissingFiles 		-- enumerate missing escene files
function GetViewPortBmp 
function GetRenderBmp  			--do render camera 1 or perspective if not cameras present

*/


-- DetectDefaultNames -----
-- from TurboSquid GCT
-- RETURNS: Array of objects
function detectDefaultNames =
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
)

-- enumerate missing escene files
function GetMissingFiles =
(
	local result = #()
	function AddFileFunc aStr &arr =
	(
		local idx = finditem arr aStr
		if idx == 0  then append arr aStr
	)
	enumerateFiles AddFileFunc result #missing
	result
)

--==== function GetViewPortBmp vpType =======------------
-- RETURNS (bitmap instnce)
/* viwport Types examples
#view_top -- Top
#view_left -- Left
#view_front -- Front
#view_persp_user -- Perspective
#view_camera -- Camera
...
( full list Help: GetType() - viewport )
--RendLevel types see: viewport.SetRenderLevel 
*/
function GetViewPortBmp vpType:undefined ZoomGeom:true RendLevel:#smoothhighlights =
(
	if vpType!=undefined then viewport.SetType vpType
	viewport.SetRenderLevel RendLevel	
	if ZoomGeom then
	(
		ClearSelection()
		select Geometry
		max zoomext sel		
		deselect geometry
	)
	redrawViews()
	Result = gw.getViewportDib()	
)

--do render camera 1 or perspective if not cameras present
--RETURNS: bitmap instance
function GetRenderBmp = 
(
	local cam = cameras[1]  
	local res=undefined
	if cam != undefined then
	(
		res = Render camera:cam   quiet:true 
	) else
	(
		viewport.SetType #view_persp_user
		select Geometry
		max zoomext sel
		deselect Geometry		
		res = Render  quiet:true 
	)
	close res
	res
)
--END===================  pX Check Scene Unit END ====================END
	--
-- ============================= XML Writer class ======== (Supports HTML too) ============--
-- XMLWriter class  - 
--  Can write XML or XHTML
-- Author: Denys Almaral - 
-- las modified v1.2 - 20/march/2012  -- added HTML support with x.WriteHtmlText
/*
	Using it:
	
	1) Create instance: 	x = XMLWriter FileName:"Datos.xml"
	2) Start xml Node:  	x.OpenNode "NodeName"
	3) Write an attribute: 	x.WriteValue "Count" "27"
	4) Close Last Node:		x.CloseNode "NodeName"  --For each OpenNode a corresponding CloseNode
	.....
	Finally) Close file:	x.CloseFile()   --- auto-close left open nodes
*/

struct XMLWriter 
(
	NodeStack = #(), 		--Private
	FileName,		 		    --Initialize this when creating struct --ReadOnly			
	EndOfValues = TRUE,
	HtmlText = FALSE,
	TextNodeIdx = -1,
	
	function OnCreate =	(      --Don't call OnCreate, it's called automatically
			local ffss = CreateFile FileName 					
			ffss
		),
	FS = OnCreate(),	 		-- fileStream
	
	function WriteXMLHeader =
	(
		Format "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"  to:FS
	),
		
	Function OpenNode NodeName =       --Open a new XML Node
		(
			if not EndOfValues then
			(
				Format ">" to:FS
				if not HtmlText then Format "\n" to:FS
			)			
			if not HtmlText then 
			(
				for i=1 to NodeStack.count do Format "  " to:FS  --Tabulation
			)
			Append NodeStack NodeName
			Format "<%" NodeName to:FS
			EndOfValues = FALSE
		), 
		
	Function WriteValue Name Value =         --Writes values to current node
		(
			if not EndOfValues then Format " %=\"%\"" Name Value	to:FS		
		),
		
	Function CloseNode NodeName=                     --Close corrent opened node, or last node from Stack 
		(
			-- The NodeName parameter is redundant, but if Good to Catch Errorrs			
			s = NodeStack[NodeStack.count]
			if NodeName!=s then
		    (
			  messageBox ("Closing wrong node: \""+NodeName+"\" Expected: \""+s+"\""   ) title:"XML Error"	
			  return 0
			)				
			
			if EndOfValues==FALSE then
			(
				Format "/>" to:FS												
			)else
			(				
				if not HtmlText then 
				(
					for i=2 to NodeStack.count do Format "  " to:FS  --Tabulation					
				)				
				Format "</%>" s to:FS				
			)			
			if NodeStack.count == TextNodeIdx then 
			(
				TextNodeIdx=-1
				HtmlText = false
			)
			if not HtmlText then Format "\n" to:FS
			EndOfValues = TRUE
			NodeStack.count = NodeStack.count - 1				
		),	
		
	Function CloseFile =    --Call CloseFile at the end	
	(
	  -- auto closing left open nodes
	  while (NodeStack.count>0) do
	  (
	  	CloseNode NodeStack[ NodeStack.count ]
	  )
	  Close FS;	  
	),
	
	function WriteHtmlText aText =
	(
		if EndOfValues==FALSe then
		(
				Format ">" to:FS
				EndOfValues=true
		)
		Format "%" aText to:FS	
		if not  HtmlText then
		(
			HtmlText = true
			TextNodeIdx = NodeStack.count
		)
	)
)
--END ============================= XML Writer class ======== (Supports HTML too) ============ END--
	--END including units--
	
--==============================main script program==========================================================

	--== Structss---
	struct TConfigOptions
	(
		chkIsoVerts = true,
        chkOvVerts = true,		
		spnOvVertsTole = 0.0001, 
		chkOvFaces = true,
		spnOvFacesTole = 0.0001,
		chkOvUVFaces = true,
		chkFlippedFaces = true,
		chkSaveImages = true,
		chkDoRender = true		
	)
	
	Global g_ConfigOptions
	
	struct TArray( arr = #() ) --to store an array in ListView Tag
	
	struct TSceneTotals 
	(
		ObjsCount=0,
		VertCount=0,
		PolyCount=0,		
		TriCount=0,
		TriObjs=#(),		
		NgonsCount=0,
		NgonsObjs=#(),		
		WrongScaleObjs=#(),		
		NoParentsObjs=#(),		
		NoMaterialObjs=#(),		
		DefNamesObjs=#(),	
		HiddenObjs=#(),		
		IsoVertCount=0,			
		OvVertCount=0,
		OvFaceCount=0,
		OvUVFaceCount=0,
		FlippedFaceCount=0,		
		IsoVertObjs=#(),			
		OvVertObjs=#(),
		OvFaceObjs=#(),
		OvUVFaceObjs=#(),
		FlippedFaceObjs=#(),		
		NumErrors=0,
		ProcessingTime=0
	)
	
	Local SceneTotals = TSceneTotals()
	
	

	
	struct ListViewClass
	(
		lvControl,  								--ListView control
		layout_def = #(),  			--Array of #("Colum label", width)
		data = #(),                    --ObjectsInfo  compatible structure
		function Init =
		(
			--lvControl.MousePointer = #ccArrow
			lvControl.GridLines = true
			lvControl.AllowColumnReorder = true
			--lvControl.Appearance = #ccFlat
			lvControl.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
			lvControl.view = (dotNetClass "System.Windows.Forms.View").Details				
			--lvControl.FlatScrollBar = false
			lvControl.FullRowSelect = true
			lvControl.MultiSelect = false
			lvControl.LabelEdit = false
			for i in layout_def do
			(
				lvControl.Columns.add i[1] i[2]				
			)	
			lvControl.Update()
		),
		function Refresh = 
		(
			lvControl.Items.Clear()
			local theRange = #()
			for j=1 to data.count do
			(
				--first colum ListItem type
				local li = dotNetObject "System.Windows.Forms.ListViewItem" 
				li.UseItemStyleForSubItems = false
				if data[j][1][1]!=undefined then li.Text = data[j][1][1] as string
				if (classof data[j][1][2])==Color then
						(
							li.ForeColor = li.ForeColor.FromArgb data[j][1][2].b data[j][1][2].g data[j][1][2].r
						)
				--if data[j][1][3] == true then li.Bold = true
				li.tag = dotNetMXSValue data[j][1][4]
				
			
				--ListSubItem columns
				for i=2 to data[j].count do
				(
					local si = li.SubItems.add ""					
					if data[j][i]!= undefined then
					(						
						if data[j][i][1]!=undefined  then  si.Text = data[j][i][1] as string
						if (classof data[j][i][2])==Color then 
									(
										if data[j][1][2] != undefined then
										(
											si.ForeColor =  si.ForeColor.FromArgb data[j][1][2].b data[j][1][2].g data[j][1][2].r										
										)
									)
						--if data[j][i][3] == true then si.Bold = true					
					) 
				)
				append theRange li
			)
			lvControl.Items.AddRange theRange
			
			--UpdateWindow lvControl
		)
	)
	
	
		--function lvDataToXML xml(XMLWriter) lvColumns lvData nodeName(strings) 
	function lvDataToXML xml lvColumns lvData nodeName =
	(
		local val=""
		xml.OpenNode nodeName
		xml.WriteValue "count" LvData.count
		for row=1 to lvData.count do
		(
			xml.OpenNode "item"
			for col=1 to lvColumns.count do
			(
				val = lvData[row][col] 
				if val==undefined then val = "" else 
					( 
						val =  lvData[row][col][1]
						if val==undefined then val = ""
					)
				xml.WriteValue lvColumns[col][1] val 
			)
			xml.CloseNode "item"
		)
		xml.CloseNode nodeName
	)
	
	--
	function replaceChar &str charOld charNew =
	(
		local idx = findString str charOld
		if idx!=undefined then
		(
			for i=idx to str.count do 
			(
				if str[i]==charOld then str[i]=charNew
			)
		)
	)
	
	--lvDataToCSV fs(fileStream) lvColumns lvData nodeName(strings) 
	function lvDataToCSV fs lvColumns lvData nodeName =
	(
		local val=""
		format "%, %\n" nodeName LvData.count to:fs
		for col=1 to lvColumns.count do
		(
			format "%, " lvColumns[col][1] to:fs
		)
		format "\n" to:fs		
		for row=1 to lvData.count do
		(			
			for col=1 to lvColumns.count do
			(
				val = lvData[row][col] 
				if val==undefined then val = "" else 
					( 
						val =  lvData[row][col][1]
						if val==undefined then val = ""
						if (classof val!=integer) and (classof val!=float) then
							(
								val = val as string
								replaceChar &Val "," "|"
							)
							
						
					)
				format "%, " val to:fs
			)
			format "\n" to:fs
		)
		format "\n" to:fs
	)
	
	--function ColorToHtmlHex cc --> Color R G B
	--returns html hex: example: #FF002E
	function WinColorToHtmlHex cc =
	(
		local r = cc.b as integer
		r = bit.shift r 8
		r = bit.or r (cc.g as integer) 
		r = bit.shift r 8
		r = bit.or r (cc.r as integer)
		--string
		r = bit.IntAsHex r
		local res = "#000000"
		for i=r.count to 1 by -1 do
		(
			res[i + (res.count-r.count) ] = r[i]
		)			
		res
	)
	
	function lvDataToHTML xml lvColumns lvData TableName =
	(
		local val=""		
		xml.OpenNode "table"
		xml.WriteValue "border" 1; 	xml.WriteValue "cellpadding" 1; xml.WriteValue "cellspacing" 0
		xml.WriteValue "bordercolor" "#CCCCCC"; 
		xml.OpenNode "caption"
		xml.WriteHtmlText TableName
		xml.CloseNode "caption"
		--colum headers
		xml.OpenNode "tr"
			xml.WriteValue "bgcolor" "#F7F7F7"
			for i=1 to lvColumns.count do
			(
				xml.OpenNode "th"			
				xml.WriteHtmlText lvColumns[i][1]
				xml.CloseNode "th"
			)
		xml.CloseNode "tr"
		for row=1 to lvData.count do
		(
			xml.OpenNode "tr"
			for col=1 to lvColumns.count do
			(
				local cc=undefined
				local isbold = undefined
				val = lvData[row][col] 
				if val==undefined then val = "&nbsp;" else 
					( 
						val =  lvData[row][col][1]
						if val==undefined then val = "&nbsp;"
						cc = lvData[row][col][2]
						isbold = lvData[row][col][3]
					)					
				xml.OpenNode "td"
					if cc!=undefined then 
					(
						xml.OpenNode "font"
						xml.WriteValue "color" (WinColorToHtmlHex cc)
					)
					if isbold==true then xml.OpenNode "b" 
					xml.WriteHtmlText val 
					if isbold==true then xml.CloseNode "b"
					if cc!=undefined then xml.CloseNode "font"					
				xml.CloseNode "td"
			)
			xml.CloseNode "tr"
		)
		xml.CloseNode "table"
		xml.OpenNode "p"; xml.CloseNode "p"
	)
	
	struct TSceneInfoCopy
	(
		MaxFile = "", 
		NameOnly = "",		
		ObjectsInfo = #(),			--listview data
		SummaryInfo = #(),  		--listview data
		MeshAnalysisInfo = #(), 	--listview data
		MissingExtFiles = #(),		--strings list
		MissingDLLs = #(),			--strings list
		MissingXRefs = #(), 		--strings list
		VPcaptures = #(), 			--array of images		
		
		function SaveImages aFileName =   --save image files: Return filenames array
		( 			
			local arr=#()
			if Roll_Options.chkSaveImages.checked then
			(
				arr.count = VPCaptures.count
				for i=1 to VPCaptures.count do
				(
					local bm = VPCaptures[i]
					if (classof bm)==BitMap then
					(
						local newfilename = aFileName + "_cap_" + (i as string) + ".jpg"
						bm.filename = newfilename
						arr[i] = fileNameFromPath newfilename
						save bm
						close bm
					)
				)
			)
			arr
		),
		function SaveToXML aFileName =
		(
			local x = XMLWriter FileName:aFileName
			x.WriteXMLHeader()
			x.OpenNode "SceneInspection"
			
				x.WriteValue "MaxVersion" (maxVersion())[1]
				x.WriteValue "FileName" NameOnly
				x.WriteValue "UserName" sysInfo.username
				--x.WriteValue "ComputerName" sysInfo.computername
				x.WriteValue "LocalTime" localTime
					
				LvDataToXML x SummaryColumns SummaryInfo "Table_SummaryInfo"
				LvDataToXML x ObjectsInfoColumns ObjectsInfo "Table_ObjectsInfo"					
				LvDataToXML x MeshAnalysisColumns MeshAnalysisInfo "Table_MeshAnalysisInfo"	
					
				x.OpenNode "Missing_references"
					x.WriteValue "Count" (MissingExtFiles.count + MissingDLLs.count + MissingXRefs.count)
					for i=1 to MissingExtFiles.count do 
					( x.OpenNode "File"; x.WriteValue "f" MissingExtFiles[i];	x.CloseNode "File"	)
					for i=1 to MissingDLLs.count do 
					( x.OpenNode "File"; x.WriteValue "f" MissingDLLs[i];	x.CloseNode "File"	)
					for i=1 to MissingXRefs.count do 
					( x.OpenNode "File"; x.WriteValue "f" MissingXRefs[i];	x.CloseNode "File"	)
				x.CloseNode "Missing_references"
					
			x.CloseNode "SceneInspection"
			x.closeFile()
			SaveImages aFileName
		),
		
		function SaveToCSV aFileName =
		(
			local ff = CreateFile aFileName 
			format "SceneInspection\n" to:ff
			format "Var, Value\n"  to:ff
			format "MaxVersion, %\n" (maxVersion())[1] to:ff
			format "FileName, %\n" NameOnly to:ff
			format "UserName, %\n" sysInfo.username to:ff
			--format "ComputerName, %\n" sysInfo.computerName to:ff
			format "LocalTime, %\n\n" localTime to:ff
			
			LvDataToCSV ff SummaryColumns SummaryInfo "Table_SummaryInfo"	
			LvDataToCSV ff ObjectsInfoColumns ObjectsInfo "Table_ObjectsInfo"					
			LvDataToCSV ff MeshAnalysisColumns MeshAnalysisInfo "Table_ObjectsInfo"	
			
			format "MissingReferences, %\n" (MissingExtFiles.count + MissingDLLs.count + MissingXRefs.count) to:ff
			format "FileName\n"	to:ff
			for i=1 to MissingExtFiles.count do format "%\n" MissingExtFiles[i]	to:ff 
			for i=1 to MissingDLLs.count do format "%\n" MissingDLLs[i] to:ff
			for i=1 to MissingXRefs.count do format "%\n" MissingXRefs[i]	 to:ff
			format "\n"	to:ff
			close ff
			SaveImages aFileName
		),
		
		function SaveToHTML aFileName = 
		(
			local x = XMLWriter FileName:aFileName
			x.OpenNode "html"
			x.OpenNode "body"
			    x.OpenNode "h2"
				x.WriteHtmlText ("File Name: " + NameOnly)
			    x.CloseNode "h2"
				x.OpenNode "p"					
					x.WriteHtmlText ("Max version: "+(maxVersion())[1] as string)
					x.OpenNode "br"; x.CloseNode "br"
					x.WriteHtmlText ("User name: "+sysInfo.userName)
					x.OpenNode "br"; x.CloseNode "br"
					--x.WriteHtmlText ("Computer name: "+sysInfo.computername)
					--x.OpenNode "br"; x.CloseNode "br"	
					x.WriteHtmlText ("Local time: "+LocalTime)
				x.CloseNode "p"						
				lvDataToHTML x SummaryColumns SummaryInfo "Summary Info"
				LvDataToHTML x ObjectsInfoColumns ObjectsInfo "Objects Info"	
				LvDataToHTML x MeshAnalysisColumns MeshAnalysisInfo "Mesh Analysis Info"	
				x.OpenNode "p"
					x.WriteHtmlText "Missing references"
				x.CloseNode "p"
				x.OpenNode "ul"
					for i=1 to MissingExtFiles.count do 
					( x.OpenNode "li"; x.WriteHtmlText MissingExtFiles[i];	x.CloseNode "li"	)
					for i=1 to MissingDLLs.count do 
					( x.OpenNode "li"; x.WriteHtmlText MissingDLLs[i];	x.CloseNode "li"	)		
					for i=1 to MissingXRefs.count do 
					( x.OpenNode "li"; x.WriteHtmlText MissingXRefs[i];	x.CloseNode "li"	)		
				x.CloseNode "ul"				
				local imgs = SaveImages aFileName
				x.OpenNode "p"
					x.WriteHtmlText "Renders & Screen Captures:"
				x.CloseNode "p"
				for i=1 to imgs.count do
				(
					x.OpenNode "img"
						x.writeValue "src" imgs[i]					    
					x.CloseNode "img"
					x.OpenNode "p"; x.CloseNode "p"
				)
			x.closeFile()
			
		)
		
	)
	
	
	function IsIgnoreModifier m =
	(
		local ignore = false
		for i = 1 to IgnoreModifiers.count while not ignore do
		(
			ignore = ignore or (isKindof  m  IgnoreModifiers[i] )
		)
		ignore
	)
	
	function CleanUserProps Obj =
	(
		local Buff = getUserPropBuffer Obj
		local arr = filterString Buff "\r\n"		
		local newBuff = ""
		for i=1 to arr.count do
		(
			if not (matchpattern arr[i] pattern:"siup_*" ) then append	newBuff (arr[i]+"\r\n")		
		)
		setUserPropBuffer Obj newBuff
	)

	
	-- prepare any node for inspection
	function PrepareObject o =
	(
		CleanUserProps o
		setUserProp o up_NumErrors 0
		--groups? open it
		if isGroupHead o then
		(
			setGroupOpen o true
		)
		--geometries...
		if (classof o) != Editable_Poly then
		(
			if (IsKindOf o GeometryClass) and (not (isKindOf o Biped_object)) and (not (isKindOf o BoneGeometry)) then
			(
				-- ignore and disable subdivition modifiers
				--print o.name
				local j = 1 											
				while isIgnoreModifier o.modifiers[j] do
				(				
					if o.modifiers[j].enabled == true then
					(
						if not (matchPattern o.modifiers[j].name pattern:(TEMPDISABLED+"*")) then
							(
								o.modifiers[j].name =   TEMPDISABLED + o.modifiers[j].name
							)
						o.modifiers[j].enabled = false	
					)
					j  += 1						
				)
				-- add Edit_Poly bellow subdivition
				if o.modifiers[ TEMPMOD + "edit_poly" ]==undefined  then
				(
					local epMod = Edit_poly()
					epMod.name = TEMPMOD + "edit_poly"  --mark added modifier to restore later
					if validModifier o epMod then addModifier o epMod before:(j-1)
				)
			)
		)
	)	
	
	-- PrepareSceneObjects -------------------------
	-- prepare all scene objects for inspection
	function PrepareSceneObjects =
	(		
		for i = 1 to  TheObjects.count do
		(			
			PrepareObject TheObjects[i]	
			mainProgressBar.value = (i*50)/TheObjects.count	
		)
	)
	
	-- 
	function RestoreObjectModifiers o =
	(
		local delMods = #()
		for i=1 to o.modifiers.count do
		(
			local m = o.modifiers[i]
			if matchPattern m.name pattern:(TEMPDISABLED+"*") then
			(
				m.enabled = true
				m.name = replace m.name 1 TEMPDISABLED.count ""
			)
			if matchPattern m.name pattern:(TEMPMOD+"*") then
			(
				append delMods m
			)
		)
		for delme in delMods do
		(
			deleteModifier o delme
		)		
		if isGroupHead o then
		(
			setGroupOpen o false
		)
		CleanUserProps o
	)
	
	-- 
	function RestoreModifiers =  
	(
		for o in Objects do RestoreObjectModifiers o
	)
	

	-- GetObjectsInfo-------------------------------------------------------
	---------------------------------------------------------------------------
	function Update_ObjectsInfo =
	(		
		--name checking
		local dnames = detectDefaultNames()
		for o in TheObjects do SetUserProp o up_DefaultName false
		for o in dnames do SetUserProp o up_DefaultName true		
		SceneTotals.DefNamesObjs = dnames
		--polygon check
		ObjectsInfo.count = TheObjects.count
		SceneTotals.ObjsCount  = TheObjects.count
		for i=1 to TheObjects.count do
		(
			local o = TheObjects[i]
			local cc, bb 
			local numErrors = 0
			local Percent = 0
			-- first colunm Name, color, bold, instance)  
			ObjectsInfo[i] = #()
			ObjectsInfo[i].count = 9 -- NumColumns			
			if (GetUserProp o up_DefaultName)==true then 
			(
				bb=true 
				numErrors += 1
				ObjectsInfo[i][11] = #( "YES", COLOR_RED) 
			)else (bb=undefined; ObjectsInfo[i][11] = #( "no")  )
			ObjectsInfo[i][1] = #( o.name, undefined, bb, o) 
			
			--classname COLUMN 2 ******************************
			if ((classof o)!=PolyMeshObject) and ((classof o)!=Editable_Poly ) then cc=COLOR_GRAY
			ObjectsInfo[i][2] = #( classof o.baseObject, cc) 
			
			--poly info
			if  ((classof o)==PolyMeshObject) or ((classof o)==Editable_Poly ) then
			(
				if (classof o.baseObject)==Editable_Poly then polyOp.CollapsedeadStructs o       -- avoid possible dead feaces, edges, vertices
				Local PolyInfo = FindNonQuads o
				--** User Properties **
				SetUserProp o up_TriSel PolyInfo.TriPolys
				SetUserProp o up_NGonsSel PolyInfo.NGonsPolys
				--** ------------------ **
				
				--Verts COLUNM 3 **************************
				if PolyInfo.VertCount < 3 then 
				(
					cc = COLOR_RED
					numErrors +=1
				)	else cc= undefined
				ObjectsInfo[i][3] = #(PolyInfo.VertCount, cc,true)
				SceneTotals.VertCount += PolyInfo.VertCount
				
				--Polys Total: COLUMN 4 **********************
				if PolyInfo.PolyCount == 0 then 
				( 
					cc = COLOR_RED
					numErrors += 1
				)else cc= undefined
				ObjectsInfo[i][4] = #(PolyInfo.PolyCount, cc, true)
				SceneTotals.PolyCount += PolyInfo.PolyCount
					
				--TriCount: COLUMN 5 ********************
				if PolyInfo.PolyCount>0 then
				(					
					percent = ((PolyInfo.TriCount*100.0 )/ PolyInfo.PolyCount )
					if percent >= cm_TRIS_LIMIT then 
					( 
						cc = COLOR_RED
						numErrors += 1
					)
					else cc = undefined
					ObjectsInfo[i][5] = #( (PolyInfo.TriCount as string) + " (" + ((int percent) as string) + "%)", cc)
					if PolyInfo.TriCount > 0 then
					(
						SceneTotals.TriCount += PolyInfo.TriCount
						append SceneTotals.TriObjs o
					)
				)				
				
				-- NGons Count: COLUMN 6 ******************
				if PolyInfo.PolyCount>0 then
				(
					percent = ((PolyInfo.NgonsCount*100.0 )/ PolyInfo.PolyCount )
				)
				if PolyInfo.NGonsCount > 0 then
				(					
					cc = COLOR_RED
					numErrors +=1
					SceneTotals.NgonsCount += PolyInfo.NGonsCount 
					append SceneTotals.NgonsObjs o
				) else cc = undefined 
				ObjectsInfo[i][6] = #( (PolyInfo.NGonsCount as string) + " (" + ((int percent) as string) + "%)", cc )  
								
				-- Material COLUMN 9 *******************
				if o.Material==undefined then
				( 				 
					numErrors += 1
					ObjectsInfo[i][9] = #( "NO", COLOR_RED )
					append SceneTotals.NoMaterialObjs o
				) else 
				(
					cc = undefined
					if (matchPattern o.Material.name pattern:"?? - Default" ) or (  matchPattern o.material.name pattern:"Standard_*") then 
					(
						cc = COLOR_RED
						numErrors += 1
					)
					ObjectsInfo[i][9] = #( o.Material.Name, cc )
				)	
				
			)
			-- scale COLUMN 7 ********************
			if (o.Transform.Scalepart as string)!="[1,1,1]" then 
			(
				 cc = COLOR_RED
				numErrors += 1
				append SceneTotals.WrongScaleObjs o
			) else cc = undefined
			 ObjectsInfo[i][7] = #( o.Transform.Scalepart, cc)
			
			-- parent COLUMN 8 *******************
			if o.Parent==undefined then
			( 				 
				--numErrors += 1
				ObjectsInfo[i][8] = #( "--", COLOR_RED )
				append SceneTotals.NoParentsObjs o
			) else 
			(
				ObjectsInfo[i][8] = #( o.Parent.Name, undefined )
			)	
			
			--Vp.Hidden COLUMN 10 ****************************
			if o.isHiddenInVpt then
			(				
				ObjectsInfo[i][10] = #("YES", COLOR_RED)
				append SceneTotals.HiddenObjs o
			) else
			(
				ObjectsInfo[i][10] = #("no")
			)
						
			if NumErrors > 0 then 
			( 
				ObjectsInfo[i][1][2] = COLOR_RED
				ObjectsInfo[i][1][5] = NumErrors
				SetUserProp o up_NumErrors NumErrors
				SceneTotals.NumErrors += NumErrors
			) else ObjectsInfo[i][1][2] =undefined
			
			mainProgressBar.value = 50 +(i*50)/TheObjects.count
			
		)--for
		
		ObjectsInfoListView.data = ObjectsInfo			
	)
	
	-- Build_SummaryInfo ----------------------------------
	-----------------------------------------------------------
	-- should call this just after update objects info
	function Build_SummaryInfo =
	(			
		local row
		local percent, cc
		local TempArray
		SummaryInfo.count = 0     -- initialize wihout losting the reference, instead of =#(), 
		
		function AddStandardRow aDescText aVal aTotal aListObjs =
		(
			local p,c,ps --percent, color 
			if aTotal > 0 then p = (aVal*100.0)/aTotal else p=0
			if aVal>0 then c = COLOR_RED else c = COLOR_GREEN
			if (p>0) and (p<1) then ps = (p as string) + "%" else ps = ((int p) as string)+"%" 
			--Result
			local ocount = undefined; if aListObjs!=undefined then ocount = aListObjs.count
			#( #(aDescText,c,undefined,undefined,undefined, aListObjs),  #(aVal), #(ps), #(ocount))			
		)		
		
		row = #( #("Total Objects"),  #(TheObjects.count))
		append SummaryInfo row		
		row = #( #( "Total Vertices"),  #(SceneTotals.VertCount,undefined,true) )
		append SummaryInfo row						
		row =#( #("Total Polygons"),  #(SceneTotals.PolyCount,undefined,true) )
		append SummaryInfo row 		
		row = AddStandardRow "Triangles" SceneTotals.TriCount SceneTotals.PolyCount SceneTotals.TriObjs
		append SummaryInfo row				
		row = AddStandardRow "NGons" SceneTotals.NgonsCount SceneTotals.PolyCount SceneTotals.NgonsObjs
		append SummaryInfo row
		row = AddStandardRow "Scaled Objs." SceneTotals.WrongScaleObjs.Count TheObjects.Count SceneTotals.WrongScaleObjs
		append SummaryInfo row		
		row = AddStandardRow "Objs. with no Parents" SceneTotals.NoParentsObjs.Count TheObjects.Count SceneTotals.NoParentsObjs
		append SummaryInfo row
		row = AddStandardRow "Objs. without Materials" SceneTotals.NoMaterialObjs.Count TheObjects.Count SceneTotals.NoMaterialObjs
		append SummaryInfo row		
		row = AddStandardRow "Objs. with default names" SceneTotals.DefNamesObjs.Count TheObjects.count  SceneTotals.DefNamesObjs
		append SummaryInfo row 
		row = AddStandardRow "Objs. Hidden in Viewport" SceneTotals.HiddenObjs.Count TheObjects.count  SceneTotals.HiddenObjs
		append SummaryInfo row 	
		row = AddStandardRow "Isolated vertices"  SceneTotals.IsoVertCount  SceneTotals.VertCount  SceneTotals.IsoVertObjs
		append SummaryInfo row
		row = AddStandardRow "Overlapping Vertices" SceneTotals.OvVertCount SceneTotals.VertCount SceneTotals.OvFaceObjs
		append SummaryInfo row
		row = AddStandardRow "Overlapping Faces" SceneTotals.OvFaceCount sceneTotals.PolyCount SceneTotals.OvFaceObjs
		append SummaryInfo row
		row = AddStandardRow "Overlapping UV Map Faces" SceneTotals.OvUVFaceCount sceneTotals.PolyCount SceneTotals.OvUVFaceObjs
		append SummaryInfo row
		row = AddStandardRow "Flipped Normal Faces"  SceneTotals.FlippedFaceCount sceneTotals.PolyCount sceneTotals.FlippedFaceObjs
		append SummaryInfo row
		row = AddStandardRow "Missing file references" MissingFiles.count ((usedMaps()).count+MissingFiles.count) undefined
		append SummaryInfo row
		
		row = #( #("Scene processing time (Seconds)"), #( (SceneTotals.ProcessingTime/1000.0) )  )
		append SummaryInfo row
		   		
		
		SummaryInfoListView.data = SummaryInfo
	)
	
	--============ Start_MeshAnalysis  ============---------
	--
	function Start_MeshAnalysis =
	(
		OvVerts_Tolerance = Roll_Options.spnOvVertsTole.value
		OvFaces_Tolerance = Roll_Options.spnOvFacesTole.value
		MeshAnalysisInfo.count = 0  
		local winCaption = rf_MainWin.title 
		
		function runTest aTestFunc Obj  &ElementCounter &ObjsArray &numErr &CurrRow aUp_prop =
		(
			local res = aTestFunc Obj
			local c,col
			if res.numberSet>0 then 
				(
					c = COLOR_RED;  numErr += 1
					ElementCounter += res.numberSet
					append ObjsArray Obj
				)  else c = undefined
				col = #(res.numberSet, c)
				setUserProp Obj aUp_prop res
				append CurrRow col				
		)
		
		local tt=timeStamp()
		
		for i=1 to TheObjects.count do 
		(
			local o = TheObjects[i]
			if  ((classof o)==PolyMeshObject) or ((classof o)==Editable_Poly ) then
			(
				local row = #()
				local col
				local res
				local cc=undefined
				local numErrors
				local numcols = 7.0		
				
				
			    rf_MainWin.title   = winCaption + " ->" + o.name
				
				select o
				redrawViews()   -- to shows the current selected object, cutest! :) 
				
				--ObjectName COL 1 frist ********************				
				append row #()  --update at the end
				numErrors=0				
				
				----- The calls bellow are the most time consuming for the whole script
				-- IsoVerts COL2 
				if Roll_Options.chkIsoVerts.checked 
					then runTest FindIsoVerts o &SceneTotals.IsoVertCount &SceneTotals.IsoVertObjs &numErrors &Row up_IsoVertsSel				
						else append row #()
				-- Overlapping verts 				
				if Roll_Options.chkOvVerts.checked 
					then	runTest FindOverlappingVerts o &SceneTotals.OvVertCount &SceneTotals.OvVertObjs &numErrors &Row up_OvVertsSel
						else append row #()
				-- Overlapping Faces 
				if Roll_Options.chkOvFaces.checked
					then	RunTest FindOverlappingFaces o  &SceneTotals.OvFaceCount &SceneTotals.OvFaceObjs &numErrors &Row up_OvFacesSel
						else append row #()
				-- Overlapping UVMap Faces 
				if Roll_Options.chkOvUVFaces.checked 
					then RunTest FindOverlappingMapFaces o &SceneTotals.OvUVFaceCount &SceneTotals.OvUVFaceObjs &numErrors &Row up_OvUVFacesSel
						else append row #()
				-- Flipped Normal Faces
				if Roll_Options.chkFlippedFaces.checked 
					then RunTest FindFlippedFaces o &SceneTotals.FlippedFaceCount &SceneTotals.FlippedFaceObjs &numErrors &Row up_FlippedFacesSel
						else append row #()				
				
				---- end of COLLUMNS
				--updating First item
				if numErrors>0 then 
					( row[1]=#(o.name,COLOR_RED,undefined,o ) 
						SetUserProp o up_NumErrors ((GetUserProp o up_NumErrors)+numErrors)
						SceneTotals.NumErrors += numErrors
					) else
				    (  row[1]=#(o.name,undefined,undefined,o ) )
				append MeshAnalysisInfo row
				
				mainProgressBar.value = (i*100)/TheObjects.count
					
				-----updating listview real-time
				if not BatchMode then
				(
					MeshAnalysisListView.data  = MeshAnalysisInfo
					MeshAnalysisListView.Refresh()	
				)
				
				if (timeStamp() - tt) > 10000 then (format "mem:%\n" gc(); tt=timeStamp() )
			)
		)
		mainProgressBar.value = 100
		--data ready for listview
		MeshAnalysisListView.data  = MeshAnalysisInfo
		
	)	
	
	--return string
	function GetCleanKeyName KeyStr =
	(
		substring KeyStr ("siup_fSel_".count) KeyStr.count		
	)
	
	--find clean object on listviews data
	function MarkCleanObjects =
	(		
		local obj
		for i=1 to ObjectsInfo.count do
		(
			obj = ObjectsInfo[i][1][4] 
			if isValidObj obj then
			(
				if (getUserProp obj up_NumErrors)==0 then ObjectsInfo[i][1][2] = COLOR_GREEN
			)
		)
		for i=1 to MeshAnalysisInfo.count do
		(
			obj = MeshAnalysisInfo[i][1][4] 
			if isValidObj obj then
			(
				if (getUserProp obj up_NumErrors)==0 then MeshAnalysisInfo[i][1][2] = COLOR_GREEN
			)
		)
	)
	
	-- get all max files in Dir and subdirectories recursivelly
	function ScanMaxFiles IniDir =
	(
		local res = GetFiles (IniDir+"*.max")
		local subDirs = GetDirectories (IniDir+"/*")
		for newDir in subDirs do 
		(			
			local newFiles = ScanMaxFiles newDir
			join res newFiles
		)
		res
	)
	
	function SetMainTitle str =
	(
		if str!="" then rf_MainWin.title = "Scene Inspector" + str
		           else rf_MainWin.title = "Scene Inspector - Denys Almaral"

	)
	
	function GetCapturesAndRender =
	(		
		SetMainTitle  " - Rendering scene..."
		if Roll_Options.chkDoRender.checked then 
		(	
			VPCaptures[1] = GetRenderBmp() 
			local vt = viewport.getType()
			VPcaptures[2] = GetViewPortBmp vpType:#view_front
			VPcaptures[3] = GetViewPortBmp vpType:#view_left
			VPcaptures[4] = GetViewPortBmp vpType:#view_top		
			viewport.SetType vt
		) else 
		(
			VPcaptures.count = 0
		)
	)
	
	--* * * * * *===============================* * * * * *--
	function START_UPDATE_PROCESS =
	(
		gc() --free some memory
		if Roll_InspectorReports.chkSelectionOnly.checked
			then TheObjects = selection as array 
				else TheObjects = objects as array
		if TheObjects.count>0 then
		(
			mainProgressBar = roll_InspectorReports.pbMain	
			BatchMode = false
		    local myDelay = TimeStamp()			
			EnabledEvents = false
			DestroyDialog roll_SubObjSelect
			local s = rf_MainWin.title 
			
		   
		    GetCapturesAndRender()
		    SetMainTitle  " - Object info..."
			SceneTotals = TSceneTotals()
			PrepareSceneObjects()
			Update_ObjectsInfo()
		    MissingFiles = GetMissingFiles() 
			ObjectsInfoListView.Refresh()			
			
			SetMainTitle " - Analyzing Mesh..."
		    			
			Start_MeshAnalysis()			
		    
		    myDelay = TimeStamp() - myDelay; 	SceneTotals.ProcessingTime = myDelay
			format "Total scene processing time: % Mins % Secs\n"  (myDelay/60000) ((mod myDelay 60000)/1000)
			Build_SummaryInfo()
			MarkCleanObjects()	
			ObjectsInfoListView.Refresh()			
			SummaryInfoListView.Refresh()			
			MeshAnalysisListView.Refresh()
			roll_InspectorReports.btnRestore.enabled = true
			roll_InspectorReports.btnMissing.caption = "("+(MissingFiles.count as string)+") View missing..."
			roll_InspectorReports.btnMissing.enabled = (MissingFiles!=0)
			EnabledEvents = true
			SetMainTitle ""
			CreateDialog roll_SubObjSelect
		)
	)
	
	-- Adds an Item to ResultsBySceneListView
	function Add_SceneResults fname =
	(
		local thetime = (SceneTotals.ProcessingTime/1000.0) as string
		local cc 
		if SceneTotals.NumErrors>0 then cc= COLOR_RED else cc=COLOR_GREEN
		local row = #(#(fname,cc),#(SceneTotals.ObjsCount), #(SceneTotals.NumErrors,cc), #(thetime))
		append ResultsByScene row
		ResultsBySceneListView.data = ResultsByScene
		ResultsBySceneListView.Refresh()
	)
	
	--remove instances references from listViewDatas
	function Remove_InfoReferences  =
	(
		for i=1 to ObjectsInfo.count do 
		( 
			if ObjectsInfo[i][1]!=undefined then ObjectsInfo[i][1][4] = undefined
		)
		for i=1 to SummaryInfo.count do
		(			
			if SummaryInfo[i][1]!=undefined then 
			(	
				SummaryInfo[i][1][4] = undefined	
				SummaryInfo[i][1][6] = undefined
			)
				
		)		
		for i=1 to MeshAnalysisInfo.count do
		(
			if MeshAnalysisInfo[i][1]!=undefined then MeshAnalysisInfo[i][1][4]= undefined 
		)
	)
	
	--show missing refreces - opening error messages in listBox
	function ShowMissingLbx aSceneInfo =
	(
		local ss = #()
		for s in aSceneInfo.MissingExtFiles do append ss ("ExtFile: " +s)
		for s in aSceneInfo.MissingDLLs do append ss ("DLLs: " +s)
		for s in aSceneInfo.MissingXRefs do append ss ("XRefs: "+s)		
		roll_BatchProcessing.lbxMissingFiles.items = ss				
	)	
	
	--save report with automated filenames
	function BatchSaveReports InfoCopy numerator =
	(
			local newName = sirep_prefix + (numerator as string) + "_" + (getFilenameFile InfoCopy.nameOnly)			
			case roll_BatchProcessing.rdoFormat.state of
			(
				1: InfoCopy.SaveToHTML 	(roll_BatchProcessing.edtOutputFolder.text+ "\\" + newName + ".html")
				2: InfoCopy.SaveToCSV 	(roll_BatchProcessing.edtOutputFolder.text+ "\\" + newName + ".csv")
				3: InfoCopy.SaveToXML 	(roll_BatchProcessing.edtOutputFolder.text+ "\\" + newName + ".xml")
			)						
	)
	
	--* * * * * *===============================* * * * * *--
	function START_BATCH_PROCESS =
	(
		BatchMode = true
		EnabledEvents = false
		mainProgressBar = roll_BatchProcessing.pbBatch 
		roll_BatchProcessing.pbTotalFiles.value = 0
		ResultsByScene = #()
		InfoCopyByScene = #()
        		
		for i =1 to BatchMaxFiles.count do
		(
			local maxfile = BatchMaxFiles[i]
			local nameOnly = filenameFromPath maxfile			
			local ic = TSceneInfoCopy()
			ic.MaxFile = maxfile
			ic.NameOnly = nameOnly
			
			if isMaxFile maxfile then
			(
				local mExtFiles=#(), mDLLs=#(), mXRefs=#()				
			 	if loadMaxFile maxfile quiet:true 	missingExtFilesAction:#logmsg \
															missingExtFilesList:&mExtFiles \									
															missingDLLsAction:#logmsg \
															missingDLLsList:&mDLLs\
															missingXRefsAction:#logmsg \
															missingXRefsList:&mXRefs then
				(
					TheObjects = objects as array
					
					ObjectsInfo = ic.ObjectsInfo   		--redirecting references
					SummaryInfo = ic.SummaryInfo      --avoids later deepcopy
					MeshAnalysisInfo = ic.MeshAnalysisInfo
					VPCaptures = ic.VPCaptures
										
					ic.MissingExtFiles = mExtFiles 
					ic.MissingDLLs = mDLLs
					ic.MissingXRefs = mXRefs
					MissingFiles = ic.MissingExtFiles 
					join MissingFiles ic.MissingDLLs
					join MissingFiles ic.MissingXRefs
					redrawViews()
					GetCapturesAndRender() 
					print ("Processing file: " + nameOnly)
					local myDelay = TimeStamp()					
					SetMainTitle (" - " +nameOnly)
					SceneTotals = TSceneTotals()
					PrepareSceneObjects()
					Update_ObjectsInfo()
					Start_MeshAnalysis()					
					myDelay = TimeStamp() - myDelay; 	SceneTotals.ProcessingTime = myDelay
					Build_SummaryInfo()
					MarkCleanObjects()	
					Add_SceneResults nameOnly
					Remove_InfoReferences()	
					if  roll_BatchProcessing.chkSaveReports.checked then BatchSaveReports ic i
					
				) else
				(
					print ("Error: Can't open .MAX file: "+(filenameFromPath maxfile))					
					append ResultsByScene #(#(("Error: Can't open .MAX file: "+(filenameFromPath maxfile)),COLOR_RED,true),#(""), #(""), #(""))
					ResultsBySceneListView.data = ResultsByScene
					ResultsBySceneListView.Refresh()
				)
			) else
			(
				print "Error: Invalid .MAX file: "+maxfile
				append ResultsByScene #(#(("Error: Invalid .MAX file: "+(filenameFromPath maxfile)),COLOR_RED,true),#(""), #(""), #(""))
				ResultsBySceneListView.data = ResultsByScene
				ResultsBySceneListView.Refresh()
			)
			
			Append InfoCopyByScene ic
			
			roll_BatchProcessing.pbTotalFiles.value = (i*100.0)/BatchMaxFiles.count
			
			gc() --force garbage collection: frees memory
		)
		SetMainTitle ""
		BatchMode = false
		EnabledEvents = true
		messageBox "Finshed processing files." title:"Done!" beep:true
	)

	--===============================================================================================
	----------Sub-Object Select ROLLOUT Dialog-------------------------------------------------------------------
	--===============================================================================================
    rollout SubObjSelect "Sub-Object Selection" width:163 height:283
    (
    	GroupBox grpSelected "Obj:" pos:[2,5] width:156 height:226
    	listbox lbxSelections "" pos:[6,23] width:147 height:8
    	label lblStatus "No selections present" pos:[7,136] width:143 height:14
    	button btnSelectThem "Select them!" pos:[6,150] width:143 height:43 enabled:false
    	button btnTopLevel "Back to Top stack level" pos:[6,197] width:144 height:28 enabled:true
    	label lbl2 "(?) ListBox above will automatically update when selecting other scene objects" pos:[3,233] width:156 height:43
		
		local CurrObject 
		local upSelections=#()
						
		function UpdateListBox =
		(
			--get selection arrays from node UserProps
			upSelections=#()
			lbxSelections.items=#()
			local tempStrings=#()
			--check every possible SelKeys
			for upKey in UserProp_SelKeys do
			(
				local aSel = GetUserProp CurrObject upKey										
				if (aSel!=undefined) and ((classof aSel)==String) then
				(				
					--using Execute to convert the String to bitArray	
					try aSel = (execute aSel) catch() 					
					if (classof aSel)==bitArray then
					(
						if not aSel.isEmpty then
						(							
							--the text for listbox item
							append tempStrings ((GetCleanKeyName upKey)+" ("+aSel.numberSet as string+")")
							--storing selection bitArray and Type chat "f"-face "v"-verts ....
							append upSelections #(aSel, upKey[key_SelTypePos])						
						)
					)
				)
			)
			lbxSelections.items = tempStrings
			if upSelections.count==0 then 
			( 
				lblStatus.caption = "No selections present" 		
				btnSelectThem.Enabled = false
			) else
			(
				lblStatus.caption = ""
				btnSelectThem.Enabled = true			
			)
		)
		
		function UpdateBtnText =
		(
			local sel = lbxSelections.selection
			if sel>0 then
    		(
    			btnSelectThem.Enabled = true
    			local SelType = upSelections[sel][2]
    			case SelType of
    				(
    					"f" : btnSelectThem.caption = "Select Faces"
    					"v": btnSelectThem.caption = "Select Vertices"
    					default: btnSelectThem.caption = "Select them!"
    				)
    		)
		)
		
		function On_SelectionChanged =
		(
			if SubObjSelect.open then
			(
				if (Selection.count ==1) and (Selection[1]!=CurrObject) then
				(
					local o = Selection[1]
					currObject = o
					grpSelected.Caption = "Obj: "+o.name
					UpdateListBox()
					UpdateBtnText()
				) else if Selection.count > 1 then grpSelected.Caption = "Obj: (Multiple...)" 
						 else if Selection.count == 0 then grpSelected.Caption = "Obj: (None)"
				if Selection.count==0 then
				(
					--clear all
					currObject = undefined
					upSelections = #()
					lbxSelections.items = #()
				)
			)
		)	

    	on SubObjSelect open do
    	(
    		On_SelectionChanged()    		
    	)
    	on SubObjSelect close do
	    	(    		
    	)
    	on lbxSelections selected sel do
    	(
    		UpdateBtnText()
    	)
    	on btnSelectThem pressed do
    	(
    		local idx = lbxSelections.selection
    		if (upSelections.count>0) and (idx>0) then
    		(
    			--ensure current object is selected
    			if currObject==$ then 
    			(
    				local theSel = upSelections[idx][1]
    				local SelType = upSelections[idx][2]
    				case SelType of
    				(
    					"f" :
    					(
    						--select faces
    						print "selecting faces"
    						print theSel
    						if (classof currObject)==Editable_poly then
    						(
    							max modify mode								
    							modPanel.setCurrentObject currObject
    							subobjectlevel = 4
    							polyop.setFaceSelection currObject theSel
    						) else
    						if (classof currObject)==PolyMeshObject then
    						(
    							local m = currObject.modifiers[TEMPMOD + "edit_poly"]
    							if (classof m)==Edit_poly then
    							(
    								max modify mode								
    							    modPanel.setCurrentObject m node:currObject
    								m.SetEPolySelLevel #Face
    								m.SetSelection #Face #{}
    								m.Select #Face theSel									
    							) 
    						)
    					)
    					"v":
    					(
    						--select vertices
    						print "selecting vertices"
    						print theSel
    						if (classof currObject)==Editable_poly then
    						(
    							max modify mode								
    							modPanel.setCurrentObject currObject
    							subobjectlevel = 1
    							polyop.setVertSelection currObject theSel
    						) else
    						if (classof currObject)==PolyMeshObject then
    						(
    							local m = currObject.modifiers[TEMPMOD + "edit_poly"]
    							if (classof m)==Edit_poly then
    							(
    								max modify mode								
    							    modPanel.setCurrentObject m node:currObject
    								m.SetEPolySelLevel #Vertex
    								m.SetSelection #Vertex #{}
    								m.Select #Vertex theSel									
    							) 
    						)
    					)
    					default:
    					(
    						print "ERROR: selection type unsupported"
    					)
    				)
    			) else
    			(
    				print "ERROR: currObject != Selected object"					
    			)
    		)
    	)--on btnSelectThem
    	on btnTopLevel pressed do
    	(
    		subobjectlevel = 0
    	)
    )

	--===============================================================================================
	----------ShowFilesList ROLLOUT-------------------------------------------------------------------------
	--===============================================================================================
	rollout ShowFilesList "Files" width:500 height:215
	(
		listbox lbx1 "" pos:[9,4] width:480 height:13
		button btn9 "Ok" pos:[412,183] width:74 height:21
		editText edtFile "" pos:[8,185] width:396 height:15
		
		
		function Refresh =
		(
			local sel = lbx1.selection
			if (sel>0) and (sel<=lbx1.items.count) then
			(
				EdtFile.text = (FileNameFromPath lbx1.items[sel])
			)
		)
		
		on ShowFilesList open do
		(

		)
		on lbx1 selected sel do
		(
			if (sel>0) and (sel<=lbx1.items.count) then
			(				
				EdtFile.text = (FileNameFromPath lbx1.items[sel])
			)
		)
		on btn9 pressed do
		(
			DestroyDialog ShowFilesList
		)
	)
	
	--===============================================================================================
	----------InspectorReports ROLLOUT-------------------------------------------------------------------------
	--===============================================================================================
	rollout InspectorReports "Inspector Reports (Current scene)" width:400 height:680
	(
		GroupBox grpObjectsInfo "Objects Info" pos:[3,226] width:392 height:177
		dotNetControl lvSceneObjects "System.Windows.Forms.ListView" pos:[9,241] width:381 height:157
		button btnStart "START/UPDATE" pos:[7,3] width:101 height:24 toolTip:"Start inspection process for current scene..."
		button btnRestore "Restore Modifiers" pos:[297,3] width:92 height:22 enabled:true toolTip:"Restore objects to its original state."
		checkbox chkAutoSelect "Auto Select" pos:[303,582] width:77 height:15
		progressBar pbMain "ProgressBar" pos:[8,30] width:382 height:8 enabled:true value:0 orient:#horizontal
		GroupBox grp8 "Summary" pos:[4,38] width:389 height:186
		dotNetControl lvSummary "System.Windows.Forms.ListView" pos:[8,51] width:379 height:141				
		button btnSelectObjs "Select Objects" pos:[299,196] width:86 height:22 enabled:true toolTip:"Select objects with selected issue (Double-click item) "
		GroupBox grp12 "Mesh analysis" pos:[3,404] width:391 height:173
		dotNetControl lvMeshAnalysis "System.Windows.Forms.ListView" pos:[6,418] width:383 height:154
		button btnSubObjSel1 "Open Face/Verts Selector..." pos:[4,579] width:150 height:21 toolTip:"Open Face/Verts selector tool, allow selecting problematic faces and vertices."
		button btnSave "Save report..." pos:[219,5] width:73 height:19 toolTip:"Save report as XML, CSV..."
		button btnMissing "(0) View missing ..." pos:[127,197] width:118 height:19 enabled:false toolTip:"Show missing references"
		button btnShowImages "Show Images..." pos:[7,197] width:116 height:20 toolTip:"View screen captures and camera render"
		checkbox chkSelectionOnly "Selection only" pos:[116,8] width:94 height:18
		
		function On_SelectionChanged =
		(
			--print "si ya me enteré"
		)	
		
		
		on InspectorReports close do
		(
			--Ending all
			Callbacks.removeScripts #selectionSetChanged  id:#si_SelectionChangedEvent
			DestroyDialog SubObjSelect
		)
		on lvSceneObjects ItemSelectionChanged do
		(							
			if lvSceneObjects.SelectedItems.Count==1 then
			(
				local ListItem = lvSceneObjects.SelectedItems.Item[0]
				if ( ListItem!=undefined ) then
				(
					if ListItem.tag.value!=Undefined  then
					(						
						if (chkAutoSelect.checked )  then 
						(						
							if isValidNode ListItem.tag.value then select ListItem.tag.value
						)
					)
				)
			)
		)
		on lvSceneObjects DoubleClick do
		(
			if lvSceneObjects.SelectedItems.Count==1 then
			(
				local ListItem = lvSceneObjects.SelectedItems.Item[0]
				if  (not chkAutoSelect.checked ) and (ListItem!=undefined) then 
				(
					if ListItem.tag.value!=Undefined  then
					(
						local obj = ListItem.tag.value --ObjectsInfo[ListItem.index][1][4]
						if isValidNode obj then select obj
					)				
				)
			)
		)
		on btnStart pressed do
		(
			START_UPDATE_PROCESS()
		)
		on btnRestore pressed do
		(
			RestoreModifiers()			
		)
		on lvSummary ItemSelectionChanged do
		(
			if lvSummary.SelectedItems.Count==1 then
			(
				local ListItem = lvSummary.SelectedItems.Item[0]
				if ListItem!=undefined then
				(			
					if ListItem.index>=0 then 	
						btnSelectObjs.enabled = false
						if SummaryInfo[ListItem.index+1][1][6] !=undefined  then
						(
							if SummaryInfo[ListItem.index+1][1][6].count>0 then btnSelectObjs.enabled = true
						)				
				)
			)			
		)
		on lvSummary DoubleClick do
		(
			btnSelectObjs.pressed()
		)
		on btnSelectObjs pressed do
		(
			if lvSummary.SelectedItems.Count==1 then
			(
				local ListItem = lvSummary.SelectedItems.Item[0]
				if ListItem!=undefined then
				(			
					if ListItem.index>=0 then 	
					(
						local selobjs = SummaryInfo[ListItem.index+1][1][6]
						if selobjs !=undefined then
						(	
							select selobjs
						)					
					)
				)
			)
		)
		on lvMeshAnalysis ItemSelectionChanged do
		(				
			if lvMeshAnalysis.SelectedItems.Count==1 then
			(
				local ListItem = lvMeshAnalysis.SelectedItems.Item[0]
				if ( ListItem!=undefined ) then
				(
					if ListItem.tag.value!=Undefined  then
					(						
						if (chkAutoSelect.checked )  then 
						(						
							if isValidNode ListItem.tag.value then select ListItem.tag.value
						)
					)
				)
			)
		)
		on lvMeshAnalysis DoubleClick do
		(
			if lvMeshAnalysis.SelectedItems.Count==1 then
			(
				local ListItem = lvMeshAnalysis.SelectedItems.Item[0]
				if  (not chkAutoSelect.checked ) and ( ListItem!=undefined ) then
				(
					if ListItem.tag.value!=Undefined  then
					(						
						if isValidNode ListItem.tag.value then select ListItem.tag.value						
					)
				)
			)
		)
		on btnSubObjSel1 pressed do
		(
			CreateDialog SubObjSelect
		)
		on btnSave pressed do
		(
			local saveFile = getSaveFileName  types:"HTML(*.html)|*.html|Excel(*.csv)|*.csv|XML (*.xml)|*.xml|" 
			if saveFile!=undefined then
			(
				local ext=getFileNameType saveFile
				local ic = TSceneInfoCopy()
				ic.MaxFile = maxFilePath + maxFileName
				ic.NameOnly = maxFileName
				ic.ObjectsInfo = ObjectsInfo
				ic.SummaryInfo = SummaryInfo
				ic.MeshAnalysisInfo = MeshAnalysisInfo
				ic.MissingExtFiles = MissingFiles
				ic.VPCaptures = VPCaptures
				if ext==".xml"	then ic.SaveToXML saveFile 
				if ext==".csv" then ic.SaveToCSV saveFile
				if ext==".html" then ic.SaveToHTML saveFile				
			)
		)
		on btnMissing pressed do
		(			
			CreateDialog ShowFilesList 			
			ShowFilesList.title = "Missing file references"
			ShowFilesList.lbx1.items=MissingFiles	
			ShowFilesList.refresh()
		)
		on btnShowImages pressed do
		(			
			for i=1 to VPcaptures.count do 
			(
				if (classof VPCaptures[i])==BitMap then display VPCaptures[i]				
			)			
		)
	)
	
	
	--=========================================================================================
	--- Batch Processing ROLLOUT ----------------------------------------------------------------------------
	--=========================================================================================
	rollout BatchProcessing "Batch Processing (Multiple scene files)" width:400 height:680
	(
		GroupBox grp1 "0 Max files" pos:[8,8] width:382 height:173
		listbox lbxMaxFiles "" pos:[13,26] width:278 height:10
		button btnScan "Scan folders.." pos:[297,26] width:87 height:24
		button btnAddSingle "Add single file..." pos:[297,54] width:84 height:22
		button btnRemove "Remove file" pos:[297,91] width:84 height:21
		button btnRemoveAll "Remove All" pos:[298,117] width:81 height:18
		button btnStartBatch "START" pos:[9,183] width:105 height:26		
		button btnGetFolder "..." pos:[300,276] width:31 height:25 toolTip:"Select output folder"
		GroupBox grp3 "Results by scene file" pos:[9,304] width:387 height:338
		progressBar pbBatch "ProgressBar" pos:[11,213] width:376 height:8
		progressBar pbTotalFiles "ProgressBar" pos:[12,228] width:376 height:15 enabled:true value:0 color:(color 30 200 40) orient:#horizontal
		dotNetControl lvResultsByScene "System.Windows.Forms.ListView" pos:[18,319] width:374 height:142 enabled:true
		button btnShowInfo "Show scene info " pos:[199,468] width:92 height:33
		label lbl1 "(?) Fills Inspector Reports above with selected scene info" pos:[296,468] width:96 height:41		
		button btnOpen1 "Open max scene" pos:[20,472] width:97 height:21
		button btnOpen2 "Open file" pos:[299,154] width:78 height:19
		listbox lbxMissingFiles "Missing references" pos:[13,506] width:379 height:7
		edittext edtOutputFolder "" pos:[8,276] width:289 height:21
		button btnSaveAll "Save now" pos:[264,249] width:64 height:21 enabled:false toolTip:"Save reports now"
		radiobuttons rdoFormat "" pos:[340,252] width:53 height:48 labels:#("HTML", "CSV", "XML") default:1 columns:1
		label lbl2 "Reports output:" pos:[20,253] width:79 height:17
		checkbox chkSaveReports "Auto save" pos:[106,254] width:75 height:18 enabled:true checked:true
		
		local LastDir = ""
		
				
		function AddNewFile s =
		(
			if (findItem BatchMaxFiles s )==0 then
			(
				append BatchMaxFiles s
			)
		)
		function Update_FilesListBox =
		(
			newList =#()
			newList.count = BatchMaxFiles.count
			for i=1 to BatchMaxFiles.count do
			(
				local lastFolder = ""
				local s = filenameFromPath BatchMaxFiles[i]
				local folders = filterString (BatchmaxFiles[i]) "\\"
				if folders.count>2 then  LastFolder = folders[ folders.count-1 ]
				newList[i] = "..\\" + LastFolder + "\\" + s 
			)
			lbxMaxFiles.items = newList
			grp1.caption =  (newList.count as string) + " Max files"
		)
		
		
		on BatchProcessing open do
		(
			lastDir = getDir #scene
			edtOutputFolder.text = lastdir
		)
		on btnScan pressed do
		(
			if LastDir == ""  then lastDir = getDir #scene
			local iniDir = (GetSavePath caption:"Select root folder to scan..." initialDir:LastDir ) 			
			if iniDir!=undefined then
			(
				LastDir = iniDir
				local fileNames = ScanMaxFiles (IniDir+"\\")
				for i=1 to fileNames.count do
				(
					addNewFile fileNames[i]
				)
			)
			Update_FilesListBox()
		)
		on btnAddSingle pressed do
		(
			if (LastDir == "") or (LastDir==undefined)  then LastDir = (getDir #scene)
			local newFile = getOpenFileName filename:(LastDir+"\\") types:"3dx Max(*.max)|*.max" 
			if newFile!=undefined then
			(
				addNewFile newFile
				Update_FilesListBox()
			)
		)
		on btnRemove pressed do
		(
			if lbxMaxFiles.items.count>0 then
			(
				local idx = lbxMaxFiles.selection
				if idx>0 then
				(
					--deleteItem LbxMaxFiles.items idx
					deleteItem BatchMaxFiles idx
					Update_FilesListBox()
				)
			)
		)
		on btnRemoveAll pressed do
		(
			BatchMaxFiles = #()
			Update_FilesListBox()
		)
		on btnStartBatch pressed do
		(
			START_BATCH_PROCESS()
			btnSaveAll.enabled = true
		)
		on btnGetFolder pressed do
		(
			local folder = (GetSavePath caption:"Select root folder for ouput..." initialDir:LastDir ) 
			if folder!=undefined then edtOutputFolder.text = folder
		)
		on lvResultsByScene ItemSelectionChanged do
		(
			if lvResultsByScene.SelectedItems.count==1 then
			(
				local ListItem = lvResultsByScene.SelectedItems.Item[0]
				if ListItem!=undefined then
				(			
					if ListItem.index>=0 then 
					(
						ShowMissingLbx InfoCopyByScene[ListItem.index+1]					
					)
				)
			)
		)
		on btnShowInfo pressed do
		(	
			if lvResultsByScene.SelectedItems.count==1 then
			(
				local ListItem = lvResultsByScene.SelectedItems.Item[0]
				if ListItem!=undefined then
				(			
					if ListItem.index>=0 then 
					(
						local ic = InfoCopyByScene[ListItem.index+1]
						print ("Show file info: " + ic.maxfile)
						SetMainTitle (" - "+ic.nameOnly)
						ObjectsInfoListView.data = ic.ObjectsInfo
						MeshAnalysisListView.data = ic.MeshAnalysisInfo
						SummaryInfoListView.data = ic.SummaryInfo					
						ObjectsInfoListView.refresh()
						MeshAnalysisListView.refresh()
						SummaryInfoListView.refresh()
						MissingFiles = ic.MissingExtFiles
						VPCaptures = ic.VPCaptures
						roll_InspectorReports.btnMissing.caption = "("+(MissingFiles.count as string)+") View missing..."
						roll_InspectorReports.btnMissing.enabled = (MissingFiles!=0)
						roll_inspectorReports.Open = true
					)									
				)				
			)
		)
		on btnOpen1 pressed do
		(
			if lvResultsByScene.SelectedItems.count==1 then
			(
				local ListItem = lvResultsByScene.SelectedItems.Item[0]
				if ListItem!=undefined then
				(			
					if ListItem.index>=0 then 
					(
						local ic = InfoCopyByScene[ListItem.index+1]
						print ("Opening file: " + ic.maxfile)
						if (isMaxFile ic.maxfile) then loadMaxFile ic.maxfile quiet:false
					)
				)
			)
		)
		on btnOpen2 pressed do
		(
			if lbxMaxFiles.items.count>0 then
			(
				local idx = lbxMaxFiles.selection
				if idx>0 then
				(
					print ("Opening file: "+BatchmaxFiles[idx])
					if (isMaxFile BatchmaxFiles[idx]) then loadMaxFile BatchmaxFiles[idx] quiet:false
				)
			)
		)
		on btnSaveAll pressed do
		(
			for i=1 to InfoCopyByScene.count do
			(
				BatchSaveReports InfoCopyByScene[i] i
				pbTotalFiles.value = i*100 / InfoCopyByScene.count				
			)
			messageBox "Reports saved!"
		)
	)
	
	
	--=========================================================================================
	--- DesignerTools ROLLOUT ----------------------------------------------------------------------------
	--=========================================================================================
	rollout DesignerTools "Designer Tools (Single objects)" width:400 height:212
	(
		
	)--=== / DesignerTools ROLLOUT END ===--
	
	
	--=========================================================================================
	--- DefOptions ROLLOUT ----------------------------------------------------------------------------
	--=========================================================================================
	rollout DefOptions "Options" width:400 height:302
	(
		checkbox chkIsoVerts "Isolated Verts" pos:[24,32] width:113 height:16 enabled:true checked:true
		checkbox chkOvVerts "Overlapping Verts ..............." pos:[24,56] width:152 height:16 checked:true
		GroupBox grp7 "Mesh Analysis" pos:[8,8] width:384 height:152
		spinner spnOvVertsTole "Tolerance" pos:[204,56] width:120 height:16 range:[0,10,0.0001] type:#float scale:0.0001 
		checkbox chkOvFaces "Overlaping Faces ..............." pos:[24,80] width:152 height:16 checked:true
		spinner spnOvFacesTole "Tolerance" pos:[203,81] width:120 height:16 range:[0,10,0.0001] scale:0.0001 
		checkbox chkOvUVFaces "Overlapping UVMap Faces" pos:[24,104] width:160 height:16 checked:true
		checkbox chkFlippedFaces "Flipped Faces" pos:[24,128] width:152 height:16 checked:true
		GroupBox grp8 "Report files" pos:[6,166] width:378 height:90
		checkbox chkSaveImages "Save image with reports" pos:[16,192] width:144 height:16 checked:false
		checkbox chkDoRender "Render and Viewport captures" pos:[16,216] width:172 height:16 checked:false
		HyperLink hlink1 "by Denys Almaral - Help..." pos:[126,263] width:221 height:28 hovercolor:[0,100,255] color:[0,0,255] address:"http://www.denysalmaral.com/2012/12/scene-inspector-help-document.html"
		
		on DefOptions open do
		(
			if g_ConfigOptions==undefined then g_ConfigOptions = TConfigOptions()
			else 
			(
				chkIsoVerts.checked = g_ConfigOptions.chkIsoVerts
				chkOvVerts.checked = g_ConfigOptions.chkOvVerts
				spnOvVertsTole.value = g_ConfigOptions.spnOvVertsTole
				chkOvFaces.checked = g_ConfigOptions.chkOvFaces
				spnOvFacesTole.value = g_ConfigOptions.spnOvFacesTole
				chkOvUVFaces.checked = g_ConfigOptions.chkOvUVFaces
				chkFlippedFaces.checked = g_ConfigOptions.chkFlippedFaces
				chkSaveImages.checked = g_ConfigOptions.chkSaveImages
				chkDoRender.checked  = g_ConfigOptions.chkDoRender
			)
		)
		on DefOptions close do
		(
				g_ConfigOptions.chkIsoVerts = chkIsoVerts.checked  
				g_ConfigOptions.chkOvVerts = chkOvVerts.checked 
				g_ConfigOptions.spnOvVertsTole = spnOvVertsTole.value
				g_ConfigOptions.chkOvFaces = chkOvFaces.checked
				g_ConfigOptions.spnOvFacesTole = spnOvFacesTole.value
				g_ConfigOptions.chkOvUVFaces = chkOvUVFaces.checked
				g_ConfigOptions.chkFlippedFaces = chkFlippedFaces.checked
				g_ConfigOptions.chkSaveImages = chkSaveImages.checked
				g_ConfigOptions.chkDoRender	 = chkDoRender.checked
		)
	)
	
	--selection chenged event
	function SelectionChanged =
	(
		if EnabledEvents then
		(
			roll_inspectorReports.On_SelectionChanged()			
			SubObjSelect.On_SelectionChanged()
		)
	)
	
	-------------MainInit -------------------------------------------------------------
	function MainInit =
	(
		--local xwinpos = (sysInfo.DesktopSize)[1] - 450  --  
		local xwinpos = (GetMaxWindowSize())[1] - 450
		rf_MainWin = newRolloutFloater "Scene Inspector - by Denys Almaral " 410 700 xwinpos 10
		addRollout InspectorReports rf_MainWin rolledUp:false
		roll_InspectorReports = InspectorReports
		roll_SubObjSelect = SubObjSelect	
		roll_BatchProcessing = BatchProcessing
		roll_Options = DefOptions
		addRollout BatchProcessing rf_MainWin rolledUp:true
		--addRollout DesignerTools rf_MainWin rolledUp:true		
        addRollout DefOptions rf_MainWin rolledUp:false			
			
		ObjectsInfoListView = ListViewClass()
		ObjectsInfoListView.lvControl = InspectorReports.lvSceneObjects		
		ObjectsInfoListView.layout_def = ObjectsInfoColumns
		ObjectsInfoListView.Init()
			
		SummaryInfoListView = ListViewClass()
	    SummaryInfoListView.lvControl = InspectorReports.lvSummary
		SummaryInfoListView.layout_def = SummaryColumns
		SummaryInfoListView.Init()	

		MeshAnalysisListView = ListViewClass()
		MeshAnalysisListView.lvControl = InspectorReports.lvMeshAnalysis
		MeshAnalysisListView.layout_def = MeshAnalysisColumns
		MeshAnalysisListView.Init()
		
		ResultsBySceneListView = ListViewClass()
		ResultsBySceneListView.lvControl = BatchProcessing.lvResultsByScene
		ResultsBySceneListView.layout_def = ResultsBySceneColumns
		ResultsBySceneListView.Init()
		
		SelectionChanged_Func = SelectionChanged
		Callbacks.addScript #selectionSetChanged "SelectionChanged_Func()" id:#si_SelectionChangedEvent
		escapeEnable = true
		if HeapSize < 20000000 then HeapSize=20000000
	) 
	
	on execute do MainInit()
)