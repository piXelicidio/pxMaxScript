macroScript BipContinuityZero category:"pX Tools" 
(
	function setContinuityZero obj =
	(
		 idx = getkeyindex obj.controller sliderTime	
		 if idx!=0 then
		 (
		  bipkey = biped.getkey obj.controller idx
		  bipkey.continuity = 0
		 )
	)
	
	if (classof $)==Biped_Object then 
	(
		setContinuityZero $
	) else if (classof $)==ObjectSet then
	(
		for obj in $ do 
		(
			if (classof obj)==Biped_Object then 
			(
				setContinuityZero obj
			)
		)
	)	
)