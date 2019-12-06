macroScript RemoveTurboSmooth category:"pX Tools" buttonText:"Remove TurboSmooth"
(
local mName = "TurboSmooth"
for obj in  $ do
(
	m = obj.modifiers[mName]
	if m!=undefined then deleteModifier obj m
)
)