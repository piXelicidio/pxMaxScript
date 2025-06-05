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

function ExportUVSection EditPolyObj SectionName basePath =
(
	local sel = polyOp.getFaceSelection EditPolyObj
	local diffmap = findMatDiffuseMap EditPolyObj.material
	local diffbmp = diffmap.bitmap
	sel = sel as array
	if sel.count > 0 then
	(
		local outFileName = basePath + maxFileName+"@" +EditPolyObj.name + "@" + SectionName + ".txt"
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

function ProcessFiles basePath =
(
	local textFiles = getFiles (basePath + "*.txt")
	local sections = dictionary #string --by section name
	local tagsCodes = #() --encoded tags array
	local tagsCodesDic = dictionary #string --tags code by string
	local totalFaces = 0
	for fname in textFiles do
	(
		local tags = filterString ( getfilenamefile fname) "@"
		
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
		if sections[tags[3]] == undefined then
		(
			sections[tags[3]] = #()			
		)
		local currSection = sections[tags[3]] 
		local f = openFile fname mode:"r"		
		while not eof f do
		(
			local l = stringstream(readLine f)
			local face = readValue l
			local uv = readvalue l --ignore
			local col = (readvalue l) as point3
			--bellow using tagsCodesDic to store numbers instead of strings to keep memory waste low,
			--and future faster value comparisons
			append currSection #(col, #(face, tagsCodesDic[tags[2]], tagsCodesDic[tags[1]]))
			totalFaces = totalFaces + 1
		)
		close f
	)		
	format "NumSecions %\n" sections.count
	format "NumTags %\n" tagsCodes.count
	format "Average face count %\n" (totalFaces / textFiles.count)
	format "Total Plyxel count %\n" totalfaces
	(Dictionary sections:sections tagsCodes:tagsCodes tagsCodesDic:tagsCodesDic)
)

function Reduction data threshold =
(	
	for sec in data[#sections] do
	(
		--each section is array of color info
		local cinfo = sec.value
		format "Before (%) : %\n" sec.key cinfo.count
		for i=1 to (cinfo.count - 1) do
		(
			if cinfo[i] != undefined then 
			(
				--each item is a also nested array with first value the color as point3
				local c1 = cinfo[i][1] 
				--lets compare with each bro, bro.
				for j= i+1 to cinfo.count do
				(
					if cinfo[j] != undefined then
					(
						local c2 = cinfo[j][1]
						local dist = distance c1 c2
						if dist < threshold then
						(
							-- too similar let's join face info
							-- after fist item cinfo[i][1], each other item is a face info array (cinfo[i][2] == some face data as array
							-- bring all face datas from cinfo[j] to cinfo[i]
							for k =  2 to cinfo[j].count do
							(
								append cinfo[i] cinfo[j][k]
							)
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
	

rollout roll_palCompile "Palette Compilation"
(
	button btnExportUV "Export UV from face sel."
	edittext edtSectionName "SectionName" text:"cloth"
	label lblSeparator "-------"
	button btnProcessFiles "Process TXT files"	
	button btnReduction "Similarity reduction..."
	edittext edtThreshold "Threshold" text:"1"
	
	local sectionData = undefined
	
	on btnExportUV pressed do (ExportUVSection $ edtSectionName.text maxFilePath)
	on btnProcessFiles pressed do (sectionData = ProcessFiles maxFilePath)
	on btnReduction pressed do (Reduction sectionData (edtThreshold.text as number))
)

CreateDialog roll_palCompile