rollout quickExport "Quick Multi-Export"
(
	checkbox chkFBX "" across:2 checked:true
	edittext edtPathFBX "Path FBX:" offset:[-160,0] width:340 text:@"F:\_px\3D\_sell\LowPolyStyle\WorldPeople\_publish"
	checkbox chkOBJ "" across:2 checked:true
	edittext edtPathOBJ "Path OBJ:" offset:[-160,0] width:340 text:@"F:\_px\3D\_sell\LowPolyStyle\WorldPeople\_publish"
	checkbox chkMAX "" across:2 checked:false
	edittext edtPathMAX "Path MAX:" offset:[-160,0] width:340 text:@"F:\_px\3D\_sell\LowPolyStyle\WorldPeople\_publish"
	checkBox chkOutName "Use Current Scene Name" across:2 checked:true
	edittext edtOutName "Out Filename:" text:"outname" enabled:false
	checkbox chkSelectedOnly "Export Selected Objects Only" checked:false
	
	button btnExport "Export"
	
	on chkOutName changed val do
	(
		edtOutName.enabled = (not chkOutName.checked)
	)		
	
	on btnExport pressed do
	(
		local outName = (getFileNameFile maxfilename)
		if (chkOutName.checked == false) then outName = edtOutName.text
		outName = "\\" + outName
		if chkFBX.checked then 
		(
			ExportFile (edtPathFBX.text + outName + ".fbx") #noPrompt selectedOnly:chkSelectedOnly.checked
		)
		if chkOBJ.checked then 
		(
			ExportFile (edtPathOBJ.text + outName + ".obj") #noPrompt selectedOnly:chkSelectedOnly.checked
		)
		
		if chkMAX.checked then
		(		
			if chkSelectedOnly.checked then 
			(
				saveNodes (selection as array) (edtPathMAX.text + outName + ".max") quiet:true
			) else (
				saveMaxFile (edtPathMAX.text + outName + ".max") useNewFile:false quiet:true
			)
		)
	)
	
	
)

CreateDialog quickExport 400 150 