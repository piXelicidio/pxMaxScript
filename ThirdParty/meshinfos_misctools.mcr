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


-------------------------------------------------------------------
-------------------------------------------------------------------


macroScript quickZDir
category:"Mesh Infos"
toolTip:"Quick Z Direction"
(
	fn disp_txt txt1 txt2 =
	(
		forceCompleteRedraw()
		pos1 = [(gw.getWinSizeX()-(gw.getTextExtent txt1).x)/2,25,0]
		pos2 = [(gw.getWinSizeX()-(gw.getTextExtent txt2).x)/2,40,0]
		gw.wText pos1 txt1 color:green
		gw.wText pos2 txt2 color:green
		gw.enlargeUpdateRect #whole
		gw.updateScreen()
	)
	
	disp_txt "Z Direction: pick two points" "Pick point 1"
	pt1 = pickPoint snap:#3D
	if pt1 == #escape OR pt1 == #rightClick then
	(
		forceCompleteRedraw()
	)
	else
	(
		disp_txt "Distance: pick two points" "Pick point 2"
		pt2 = pickPoint snap:#3D rubberBand:pt1
		if pt2 == #escape OR pt2 == #rightClick then
		(
			forceCompleteRedraw()
		)
		else
		(		
			for obj in selection do
			(
				try obj.dir = pt2 - pt1
				catch()
			)
			disp_txt "done" ""
		)
	)
)


-------------------------------------------------------------------
-------------------------------------------------------------------


macroScript distToClipboard
category:"Mesh Infos"
toolTip:"Distance to Clipboard"

(
	fn disp_txt txt1 txt2 =
	(
		forceCompleteRedraw()
		pos1 = [(gw.getWinSizeX()-(gw.getTextExtent txt1).x)/2,25,0]
		pos2 = [(gw.getWinSizeX()-(gw.getTextExtent txt2).x)/2,40,0]
		gw.wText pos1 txt1 color:green
		gw.wText pos2 txt2 color:green
		gw.enlargeUpdateRect #whole
		gw.updateScreen()
	)
	
	
	disp_txt "Distance: pick two points" "Pick point 1"
	pt1 = pickPoint snap:#3D
	if pt1 == #escape OR pt1 == #rightClick then
	(
		forceCompleteRedraw()
	)
	else
	(
		disp_txt "Distance: pick two points" "Pick point 2"
		pt2 = pickPoint snap:#3D rubberBand:pt1
		if pt2 == #escape OR pt2 == #rightClick then
		(
			forceCompleteRedraw()
		)
		else
		(
			print (dist = distance pt1 pt2)
			dist = formattedPrint dist
			local cbClass = dotNetClass "System.Windows.Forms.Clipboard"
		
			if dist != "" do
			(
				-- uncomment the next two lines for comma as decimal separator
				p = findString dist "."
				if p != undefined do dist = replace dist p 1 ","
				
				cbClass.SetText(dist)
				disp_txt "Distance pasted to clipboard" ""
			)
		)
	)
)


-------------------------------------------------------------------
-------------------------------------------------------------------


macroScript angleToClipboard
category:"Mesh Infos"
toolTip:"Angle to Clipboard"

(
	fn disp_txt txt1 txt2 =
	(
		forceCompleteRedraw()
		pos1 = [(gw.getWinSizeX()-(gw.getTextExtent txt1).x)/2,25,0]
		pos2 = [(gw.getWinSizeX()-(gw.getTextExtent txt2).x)/2,40,0]
		gw.wText pos1 txt1 color:green
		gw.wText pos2 txt2 color:green
		gw.enlargeUpdateRect #whole
		gw.updateScreen()
	)
	
	
	fn find_angle p1 p2 p3 = 
	(
		acos (dot (normalize (p1-p2)) (normalize (p3-p2)))
	)


	disp_txt "Angle : pick three points" "Pick point 1"
	pt1 = pickPoint snap:#3D
	if pt1 == #escape OR pt1 == #rightClick then
	(
		forceCompleteRedraw()
	)
	else
	(
		disp_txt "Angle : pick three points" "Pick point 2"
		pt2 = pickPoint snap:#3D rubberBand:pt1
		if pt2 == #escape OR pt2 == #rightClick then
		(
			forceCompleteRedraw()
		)
		else
		(
			disp_txt "Angle : pick three points" "Pick point 3"
			pt3 = pickPoint snap:#3D rubberBand:pt2
			if pt3 == #escape OR pt3 == #rightClick then
			(
				forceCompleteRedraw()
			)
			else
			(
				print (angle = find_angle pt1 pt2 pt3)
				angle = formattedPrint angle
				local cbClass = dotNetClass "System.Windows.Forms.Clipboard"
			
				if angle != "" do
				(
					-- uncomment the next two lines for comma as decimal separator
					p = findString angle "."
					if p != undefined do angle = replace angle p 1 ","
					
					cbClass.SetText(angle)
					disp_txt "Angle pasted to clipboard" ""
				)
			)
		)
	)
)
