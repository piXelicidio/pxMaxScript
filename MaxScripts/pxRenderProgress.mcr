
macroScript RenderProgress category:"pX Tools" buttonText:"Render Progress"
(
	global rpFileNumber
	global rpCameraName
	global rpFileName = "c:\\temp\\renderprogress"
	if rpFileNumber==undefined then rpFileNumber = 0
	if rpCamera==undefinded then rpCamera = $Camera01
	
	local NewFileName = rpFileName + (rpFileNumber as string) + ".jpg"
	local bm
	if rpCamera == undefined then 
	(
		bm = render vfb:false
	) else
	(
		bm = render camera:rpCamera vfb:false
	)
	bm.FileName = NewFileName
	Save bm	
	rpFileNumber += 1
)