
function SubObjectDraw =
(   
	if not ((subObjectLevel == 0) or (subObjectLevel == undefined)) then
	(			
		local labeltext = "SUB-OBJECT"
		
		--gw.SetTransform (matrix3 1)
		local width = gw.getWinSizeX();				
		gw.wText [width-100, 20, 0] ("SUB-OBJECT-"+(subObjectLevel as string)) color:yellow	
		gw.updateScreen() 		
	)
)

function RemoveCallbacks = (
	--use this to remove the callbacks, maybe need a few executions
	r = showregisteredRedrawViewsCallbacks asArray:true
	for f in r do (unRegisterRedrawViewsCallback r[1][3])
)

function GPX_ViewPortDrawTime =
(
	SubObjectDraw()
)

function RegisterMyCallbacks =
(
	unregisterRedrawViewsCallback GPX_ViewPortDrawTime
	registerRedrawViewsCallback GPX_ViewPortDrawTime
)

RegisterMyCallbacks()