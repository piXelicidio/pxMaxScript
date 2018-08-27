macroScript DisplayVertNum
category:"Mesh Infos"
toolTip:"Show Vert Nums"
(
	global VertNumEnabled = false
	unRegisterRedrawViewsCallback DispVertNum
	
	fn DispVertNum =
	(
		gw.setTransform(Matrix3 1)
		
		for obj in selection where superClassof obj == GeometryClass do
		(
			objTM = obj.objectTransform
			for v = 1 to getNumVerts obj.mesh do
			(
				coordVal = (getVert obj.mesh v) * objTM				
				coordPos = gw.wTransPoint coordVal
				if coordPos!= undefined then coordPos.x = coordPos.x + 5
				txt = v as string -- + ": " + coordVal as string
				gw.wText coordPos txt color:yellow
			)
		)
	
		gw.enlargeUpdateRect #whole
		gw.updateScreen()
	)
	
	on isChecked return VertNumEnabled
	
	on execute do
	(
		VertNumEnabled = not VertNumEnabled
		if VertNumEnabled then
		(
			unRegisterRedrawViewsCallback DispVertNum
			registerRedrawViewsCallback DispVertNum
			DispVertNum()
			forceCompleteRedraw()
		)
		else unRegisterRedrawViewsCallback DispVertNum
		forceCompleteRedraw()
	)
)

