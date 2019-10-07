--Assign all selected objects as targets for named object :
(
    local TheObject = $trunk
    local usePostfixName = true --use only last part of object name as marph target channel name
    for i=1 to selection.count do 
    (
        local obj =selection[i]
        local targetString = (FilterString obj.name "_")
        local postfix = targetString[ targetString.count ]
        WM3_MC_BuildFromNode TheObject.Morpher i obj 
        if usePostfixName then
        (
            WM3_MC_SetName TheObject.Morpher i postfix
        )
    )
   
)