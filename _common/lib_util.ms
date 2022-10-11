-- UTIL
--Misc. useful funcitons
print "lib_util loaded"
struct lib_util 
(	
	iniFilename = (getDir #userScripts) + "\\g_maxscript_config.ini",
	iniSection = "general", 
	
	function setIni k v =
	(
		--returns bool
		(setINISetting iniFilename iniSection k (v as string))
	),
	function getIni k =
	(
		--returns value
		(getINISetting iniFilename iniSection k)
	),
	function writeLn s =
	(
		format "%\n" s
	),	
	--remove all PATH part from texture filenames
	function stripAllPaths allowedList:"array" =
	(
		local all_bmp = getClassInstances BitmapTexture 
		local count = 0
		for b in all_bmp do
		(			
			local strip = filenameFromPath b.filename
			if strip != b.filename then 
			(
				b.filename = strip
				count = count + 1
			)
			--non invited textures?
			if (classof allowedList) == Array then
			(
				local idx = findItem allowedList b.filename
				if idx == 0 then
				(
					print ("WARNING: Texture is not in the exclusive list: " + b.filename)
					
				)
			)
		)
		--return count
		(count)
	)	
)

