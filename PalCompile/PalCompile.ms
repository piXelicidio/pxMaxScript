--PalCompile
--Toolkit that:
-- collect polygon section texel colors from different models and  scenes
-- save info to text files
-- reduce color by similarity
-- compile a new Texture  palette to fit them all

struct PlyxelData (
    color,      -- point3
    uv,        -- point2
    faces       -- array of #(face, tagObj, tagScene)
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
			PhysicalMaterial: mat.base_color_map
			PBRMetalRough: mat.base_color_map
			PBRSpecGloss: mat.base_color_map
			ai_standard_surface: mat.base_color_shader
			default: undefined
		)
		
	)    
	(diffMap)
)


function UVtoColor UV tempBitmap gamma:true =
(
	local w = tempBitmap.width
	local h = tempBitmap.height			
	(getPixels tempBitmap [ UV.x * w ,  (1-UV.y) * h ] 1 linear:gamma )[1]
)

function ExportUVSections basePath =
(
	local objs = $selection
	if objs.count == 0 then
	(
		objs = objects
	)
	objs = objs as array
	local totalSections = 0
	for obj in objs do
	(
		if (classof obj.baseObject)==Editable_Poly then
		(
			modPanel.setCurrentObject obj.baseObject	

			for ss in obj.faces.selSetNames do
			(
				ExportSelSet obj ss basePath
				totalSections += 1
			)
		)
	)	
	format "Done! Exported sections: %\n" totalSections
)

function ExportSelSet EditPolyObj NamedSelSet basePath =
(
	local SelSet = EditPolyObj.Faces[NamedSelSet]
	if SelSet == undefined then 
	(
		print "Selection set not found"
		return()
	)
	local sel = SelSet as BitArray
	sel = sel as array
	local diffmap = findMatDiffuseMap EditPolyObj.material
	local diffbmp = diffmap.bitmap
	
	if sel.count > 0 then
	(
		local outFileName = basePath + maxFileName+"@" +EditPolyObj.name + "@" + NamedSelSet + ".txt"
		local f = createFile outFileName 
		for face in sel do 
		(
			local mapFace = polyop.getMapFace EditPolyObj 1 face
			local uv = polyop.getMapVert EditPolyObj 1 mapFace[1]
			local col = UVtoColor uv diffbmp
			format "% % %\n" face uv col to:f 
		)
		close f		
	) else print "You need to select some faces to make an UV section"
)

function ProcessFiles basePath wildCard:"*.txt" =
(
	format "Processing: '%'\n" (basePath + wildcard)
	local textFiles = getFiles (basePath + wildCard)
	local sections = dictionary #string --by section name
	local tagsCodes = #() --encoded tags array
	local tagsCodesDic = dictionary #string --tags code by string
	local faceCheckDic = dictionary #string --dic of bitArrays to find repeated face references on same object
	local totalFaces = 0
	for fname in textFiles do
	(
		local tags = filterString ( getfilenamefile fname) "@"
		if tags.count < 3 then
		(
			format "ERROR: Filenames needs 3 tags separated by @. Tags.count = %'\n" tags.count
			return()
		)
		
		--encoding tags as numbers, keeping both as array and dictionary
		for i=1 to 2 do
		(			
			t = tags[i]
			if tagsCodesDic[t]==undefined then			
			(				
				append tagsCodes t
				tagsCodesDic[t] = tagsCodes.count
			)
		)
		local tagSection = tags[3]
		local tagObject = tags[2]
		local tagScene = tags[1]
		if sections[tagSection] == undefined then
		(
			sections[tagSection] = #()			
		)
		local SceneAndObjectTag = tagScene + "@" + tagObject
		if faceCheckDic[SceneAndObjectTag] == undefined then
		(
			faceCheckDic[SceneAndObjectTag] = #{} 
		)
		

		local currSection = sections[tagSection] 
		local f = openFile fname mode:"r"	
			
		while not eof f do
		(
			local l = stringstream(readLine f)
			local face = readValue l
			local oldUV = readvalue l
			local col = (readvalue l) as point3
			append currSection (PlyxelData color:col uv:oldUV faces:#(#(face, tagsCodesDic[tagObject], tagsCodesDic[tagScene])))
			totalFaces = totalFaces + 1
			--validating: Face cannot repeat on a single file
			if faceCheckDic[SceneAndObjectTag][face] then 
			(
				format "WARNING: Face already referenced: #% scene: % obj: % Section: %\n" face tagScene tagObject tagSection
			)
			(
				faceCheckDic[SceneAndObjectTag][face] = true --all fine
			)
		)
		close f
	)		
	format "NumSecions %\n" sections.count
	format "NumTags %\n" tagsCodes.count
	format "Average face count %\n" (totalFaces / textFiles.count)
	format "Total Plyxel count %\n" totalfaces
	(Dictionary sections:sections tagsCodes:tagsCodes tagsCodesDic:tagsCodesDic)
)

function Reduction data threshold thisSectionOnly =
(	
	local sections = data[#sections]
	if thisSectionOnly != undefined then
	(
		sections = dictionary #string
		sections[thisSectionOnly] = data[#sections][thisSectionOnly]
	)
	for sec in sections do
	(
		--each section is array of color info
		local cinfo = sec.value
		format "Before (%) : %\n" sec.key cinfo.count
		for i=1 to (cinfo.count - 1) do
		(
			if cinfo[i] != undefined then 
			(
				--each item is now a PlyxelData struct, use .color for color
				local c1 = cinfo[i].color 
				--lets compare with each bro, bro.
				for j= i+1 to cinfo.count do
				(
					if cinfo[j] != undefined then
					(
						local c2 = cinfo[j].color
						local dist = distance c1 c2
						if dist < threshold then
						(
							-- too similar, let's join face info
							-- bring all face datas from cinfo[j].faces to cinfo[i].faces
							join cinfo[i].faces cinfo[j].faces
							--mark this color info for discarding... deletion.. removal... 
							cinfo[j] = undefined
							--and be careful
						)
					)
				)	
			)			
		)
		--now being careful this section data needs a rebuilds discarding the deletions
		local newColorInfo = #()
		for i=1 to cinfo.count do
		(
			if cinfo[i] != undefined then
			(
				append newColorInfo cinfo[i]
			)				
		)
		--override the section
		data[#sections][sec.key] = newColorInfo		
		format "After (%) : %\n" sec.key newColorInfo.count		
	)
	local final = 0
	for sec in data[#sections] do
	(
		final = final + sec.value.count
	)
	format "Final Plyxels count %\n" final
)	

-- findBestLayout: choose grid minimizing we*empty + wd*distortion
-- Returns: #(bestRows, bestCols)
function findBestLayout containerW containerH N =
(
    local bestCost = 1e9
    local bestRows = 1
    local bestCols = N
	local we = 1
	local wd = 9

    for rows = 1 to N do
    (
        local cols    = (ceil (N as float / rows)) as integer
        local cellW   = containerW as float/ cols
        local cellH   = containerH as float / rows
        local emptycells   = rows * cols - N
		local maxside = amax #(cellW, cellH)	
        local dist    = (abs (cellW - cellH)) / maxside
        local cost    = we * emptycells + wd * dist

        if cost < bestCost then
        (
            bestCost = cost
            bestRows = rows
            bestCols = cols
        )
    )

    return #(bestCols, bestRows)
)

function drawRect dst_Bitmap rect_box2 col = 
(
	local b = bitmap rect_box2.w rect_box2.h color:col
	pasteBitmap b dst_Bitmap [0,0] [rect_box2.x,rect_box2.y]
)

function BuildPackedBitmap data sizeWH:256 padding:3 =
(
	struct SectionInfo (
		count,
		data,
		height,
		name
	)
    local TotalCells = 0
    local sectionsInfo = #()
    local ii = 0
    for sec in data[#sections] do
    (
        ii = ii + 1
        local count = sec.value.count
        TotalCells += count
        append sectionsInfo (SectionInfo count:count data:sec.value height:0 name:sec.key)
    )

    -- Calculate heights
    for i = 1 to sectionsInfo.count do
    (
        local h = ((sectionsInfo[i].count as float) / TotalCells) * (sizeWH-padding*2)
        h = ((ceil h) - padding) as integer
        sectionsInfo[i].height = h
    )

    -- Sort descending by count
	fn compare a b = (b.count - a.count)
    qsort sectionsInfo compare

    local ySection = padding
    local outBitmap = bitmap sizeWH sizeWH color:black
    for i = 1 to sectionsInfo.count do
    (
        local sectionW = (sizeWH-(padding*2))
        local sectionH = sectionsInfo[i].height
        local bestGrid = findBestLayout sectionW sectionH sectionsInfo[i].count
        local cellW = sectionW / bestGrid[1]
        local cellH = sectionH / bestGrid[2]
        local rect = box2 0 0 1 1
        for j = 1 to sectionsInfo[i].count do
        (
            local row = (j-1) / bestGrid[1]
            local col = mod (j-1) bestGrid[1]
            rect.x = padding + col * cellW
            rect.y = row * cellH + ySection
            rect.w = cellW
            rect.h = cellH
            drawRect outBitmap rect (sectionsInfo[i].data[j].color as color)
            -- NEW UVs important stuff!
            local newUV = [0,0]
            newUV.x = (rect.x + rect.w * 0.5) / sizeWH
            newUV.y = 1.0 - ((rect.y + rect.h * 0.5) / sizeWH)
            sectionsInfo[i].data[j].uv = newUV           
        )
        format "% %\n" sectionsInfo[i].name sectionsInfo[i].count
        ySection = ySection + padding + sectionsInfo[i].height
    )
    display outBitmap
)


/*=============================================================
    Greedy Nearest-Neighbour ordering
    -----------------------------------------------------------
    nnOrder  ptsArray  [startIdx:<1>]
        � ptsArray : #(point3 �)   (RGB or XYZ)
        � startIdx : optional 1-based starting vertex
        � returns  : #( idx0, idx1, � )  � visit order
=============================================================*/
function nnOrder pts startIdx:1 =
(
    local n = pts.count
    if n == 0 do return #()

    local visited = for i = 1 to n collect false
    local order   = #()
    local cur     = startIdx

    for k = 1 to n do
    (
        append order cur
        visited[cur] = true

        if k < n do
        (
            local best   = 0
            local bestD2 = 1e9

            for j = 1 to n where not visited[j] do
            (
                local d2 = distance pts[cur] pts[j]
                if d2 < bestD2 do 
				(
					bestD2 = d2; 
					best = j
				)
            )
            cur = best     -- jump to nearest unvisited
        )
    )
    order          -- 1-based indices
)


function NiceColorSorting data =
(
	for sec in data[#sections] do
	(
		colorPoints = for i = 1 to sec.value.count collect sec.value[i].color;
		sorted = nnOrder colorPoints
		newSection = #()
		for i=1 to sorted.count do
		(
			newSection[i] = sec.value[sorted[i]]
		)
		data[#sections][sec.key] = newSection
	)
)

function PackTexture data =
(			
	if data != undefined then
	(
		NiceColorSorting data; 
		BuildPackedBitmap data;
	)
)

function ExportRepackedUVs data basePath =
(
    local tagsCodes = data[#tagsCodes]
    local tagsCodesDic = data[#tagsCodesDic]
    local sections = data[#sections]

    -- Build reverse lookup for tagsCodes
    local tagsByCode = #()
    for i=1 to tagsCodes.count do tagsByCode[i] = tagsCodes[i]

    -- Add .repacked subfolder to basePath
    local repackedPath = basePath + ".repacked\\"
    if not (doesFileExist repackedPath) do makeDir repackedPath

    -- Rebuild file structure in memory
    local fileData = dictionary #string
    for secName in sections.keys do
    (
        local sec = sections[secName]
        for plyxel in sec do
        (
            for faceInfo in plyxel.faces do
            (
                local faceIdx = faceInfo[1]
                local objCode = faceInfo[2]
                local sceneCode = faceInfo[3]
                local objName = tagsByCode[objCode]
                local sceneName = tagsByCode[sceneCode]
                local fileName = repackedPath + sceneName + "@" + objName + "@" + secName + ".txt"
                if fileData[fileName] == undefined do fileData[fileName] = #()
                append fileData[fileName] #(faceIdx, plyxel.uv)
            )
        )
    )

    -- Write each file once, overwriting
    for fileName in fileData.keys do
    (
        local f = createFile fileName
        for entry in fileData[fileName] do
        (
            format "% %\n" entry[1] entry[2] to:f
        )
        close f
    )
    format "Done! Exported repacked UVs to .repacked folder.\n"
)

function ApplyRepackedUVs basePath =
(
    local repackedPath = basePath + ".repacked\\"
    local sceneTag = maxFileName
    local objs = $selection
    if objs.count == 0 then objs = objects
    objs = objs as array

    for obj in objs do
    (
        if (classof obj.baseObject) == Editable_Poly then
        (
            modPanel.setCurrentObject obj.baseObject
            local baseObj = obj.baseObject

            -- Find all repacked files for this object (any section)
            local pattern = repackedPath + sceneTag + "@" + obj.name + "@*.txt"
            local files = getFiles pattern

            for fileName in files do
            (
                format "Applying UVs from: %\n" fileName
                local f = openFile fileName mode:"r"
                local faceUVs = #()
                while not eof f do
                (
                    local l = stringstream(readLine f)					
                    local face = readValue l
                    local uv = readValue l
					uv = [uv.x, uv.y, 0]
                    append faceUVs #(face, uv)
                )
                close f

                -- Apply UVs to all verts in the mapFace
                for pair in faceUVs do
                (
                    local faceIdx = pair[1]
                    local uv = pair[2]
                    local mapFace = polyop.getMapFace baseObj 1 faceIdx
                    if isKindOf mapFace Array then
                    (
                        for v = 1 to mapFace.count do
                        (
                            polyop.setMapVert baseObj 1 mapFace[v] uv
                        )
                    )
                    else
                    (
                        format "Warning: mapFace for face % is not an array, got: %\n" faceIdx mapFace
                    )
                )
            )
        )
    )
    format "Done applying repacked UVs.\n"
)

rollout roll_palCompile "Palette Compilation"
(
	group "" (
	button btnExportUV "Export UV sections" tooltip:"Export UV and texel by face selection sets"
	--edittext edtSectionName "SectionName" text:"cloth,items,hair,skin"
	)
	group "" (
	button btnProcessFiles "Process files..."
	edittext edtWildCard "" text:"*.txt"
	--button btn	
	button btnReduction "Similarity reduction..." enabled:false
	edittext edtThreshold "Threshold" text:"1"
	checkbox chkBySection "Named section only" checked:false
	edittext edtBySection "Section name:" text:"hair"
	)
	group "" (
	button btnPackTexture "Build Packed Texture" enabled:false
	button btnExportUpdatedUV "Export Repacked UVs..." tooltip:"Write updated UVs to files after packing texture" enabled:false
	)
	group "" (
		button btnApplyRepackedUV "Apply Repacked UVs" tooltip:"Apply repacked UVs to selected objects"
	)	
	
	local sectionData = undefined
	
	on btnExportUV pressed do (ExportUVSections maxFilePath)
	on btnProcessFiles pressed do (
			sectionData = ProcessFiles maxFilePath wildCard:edtWildCard.text
			if sectionData != undefined then 
			(
				btnReduction.enabled = true
				btnPackTexture.enabled = true
			)
		)
	on btnReduction pressed do (
			local byThisSection = undefined
			if chkBySection.checked then byThisSection = edtBySection.text
			Reduction sectionData (edtThreshold.text as number) byThisSection
		)
	on btnPackTexture pressed do (
		PackTexture sectionData
		btnExportUpdatedUV.enabled = true
	) 
	on btnExportUpdatedUV pressed do (
		ExportRepackedUVs sectionData maxFilePath
	)
	on btnApplyRepackedUV pressed do (
		ApplyRepackedUVs maxFilePath
	)
)

CreateDialog roll_palCompile