macroScript RebusFarminizer category:"Rebus" buttonText:"Rebus Farminizer" tooltip:"Validate and Export project to REBUS Renderfarm" icon:#("farminizer",1)
(
	global bRebusStarted = true
	try
	(
		global farminizerDialog
		if farminizerDialog !=undefined then
			destroydialog farminizerDialog
		filein "rebus.mse"
	)
	catch
	(
		if querybox "Something went wrong with the farminizer script. Please Contact Rebusfarm!" == true then
			ShellLaunch "http://www.rebusfarm.net/" ""
	)
	
)
