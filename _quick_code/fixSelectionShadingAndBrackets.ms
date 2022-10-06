function fixSelectionShadingAndBrackets =
(
	local se = NitrousGraphicsManager.GetSelectionSetting()
	se.SelectionHighlightEnabled = false
	local vs = NitrousGraphicsManager.GetActiveViewportSetting()
	vs.ShowSelectionBracketsEnabled = true
)
fixSelectionShadingAndBrackets()
