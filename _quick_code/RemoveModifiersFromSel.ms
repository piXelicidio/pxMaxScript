for obj in $ do
(
	m = obj.modifiers["TurboSmooth"]
	if (m!=undefined) then deletemodifier obj m
)