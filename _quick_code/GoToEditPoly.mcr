-- try to find EditPoly in object and go to subobject to edit.
-- if already on any-SubObject level it goes out if it.
macroScript GoToEditPoly category:"pX Tools" buttonText:"Go To EditPoly"
(
	if $ != undefined then
	(
		max modify mode
		if subObjectLevel == 0 then
		(
			ep_mod = $.modifiers["Edit_Poly"]
			if ep_mod != undefined then 
			(				
				modPanel.setCurrentObject ep_mod
				subObjectLevel = 1
			)
			else if (classof $.baseObject)==Editable_Poly then
			(				
				modPanel.setCurrentObject $.baseObject
				subObjectLevel = 1
			) 
		) else
		(
			subObjectLevel = 0
		)
		
	)
)