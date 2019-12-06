--Script to rename paths of bitmap textures in a scene.
try(destroyDialog ro_bmRename)catch()
rollout ro_bmRename "Single edit Bitmap filepaths or do a search & replace on all (case insensitive)" width:906 height:495
(
	local arrBMs = #()
	local arrPaths = #()
	combobox cbx_bm "Bitmap Filepaths" pos:[6,5] width:890 height:31
	button btn_get "Get Bitmaps in Scene" pos:[5,449] width:124 height:40
	checkbutton ckb_edit "Enable Edit" pos:[134,449] width:140 height:40
	edittext edt_s "Search for:" pos:[323,450] width:439 height:16 enabled:false
	edittext edt_r "Replace with: " pos:[323,472] width:439 height:16 enabled:false
	button btn_rep "Do for All" pos:[769,449] width:132 height:40 enabled:false
	button btn_swap "Swap" pos:[279,449] width:40 height:40
 
	fn update_list=
	(
		arrBMs = #()
		arrPaths = #()
		arrBMs = getClassInstances bitmapTexture
		for i=1 to arrBMs.count do
			append arrPaths arrBMs[i].filename
		cbx_bm.items = arrPaths
	)--end fn
 
	on cbx_bm entered txt do
	(
		if ckb_edit.checked do
		(
			arrBMs[cbx_bm.selection].filename = txt
			update_list()
		)--end if
	)--end on
	on btn_get pressed do
	(
		update_list()
	)--end on
	on ckb_edit changed state do
	(
		if state then
		(
			edt_s.enabled = true
			edt_r.enabled = true
			btn_rep.enabled = true
		)--end if
		else
		(
			edt_s.enabled = false
			edt_r.enabled = false
			btn_rep.enabled = false
		)--end else
	)--end
	on btn_swap pressed do
	(
		temp = edt_s.text
		edt_s.text = edt_r.text
		edt_r.text = temp
	)--end on
	on btn_rep pressed do
	(
		local searchFor = edt_s.text
		local replaceWith = edt_r.text
		if searchFor != "" AND replaceWith != "" then
		(
			--loop through object names:
			for i=1 to arrBMs.count do
			(
				local startIndex = findString arrBMs[i].fileName searchFor -- returns the starting index of the found string
 
				if startindex != undefined do
				(
					-- replace the string at "startIndex" with length of "searchFor.count" with "replaceWith" 
					arrBMs[i].fileName = (replace arrBMs[i].fileName startIndex searchFor.count replaceWith)
				)--end if
			)--end for
			update_list()
		)--end if
		else displayTempPrompt ">>>>>> Fill in what to search for and what to replace with! <<<<<<<" 5000
	)--end on
)
createDialog ro_bmRename