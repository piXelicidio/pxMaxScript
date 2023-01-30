--startup script to reopen last scene
--Gets the file name from "Open Recent" menu stored in RecentDocuments.xml

function GetRecentDocuments = 
(
	local mi = getMaxIniFile()
	local xml_path = (getFileNamePath mi) + "RecentDocuments.xml"
	local file = OpenFile xml_path mode:"r"
	local found = false
	local fileTag = "<FilePath>"
	local fileTagClose = "</FilePath>"
	local result = #()
	while (not eof file) do
	(
		local s = readLine file
		local idx = findString s fileTag
		if idx != undefined then 
		(
			local idxClose = findString s fileTagClose
			if idxClose != undefined then
			(
				s = substring s (idx+fileTag.count) (idxClose-idx-fileTag.count)
				append result s
				print s
			)
		)
	)	
	--return
	(result)
)

function OpenLast =
(
	local rd = GetRecentDocuments()
	if rd.count>0 then
	(
		loadMaxFile rd[1] quiet:true useFileUnits:true 
	)
)

OpenLast()
