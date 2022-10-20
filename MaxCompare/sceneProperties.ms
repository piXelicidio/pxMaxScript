
(
	local py = python.import "builtins"
	local json = python.import "json"
	local classof_tag = "_CLASSOF_"
	
	function GetProps ref propsArr = --return dict
	(
		--propsArr array of strings with property names
		local dic = py.dict()
		for prop in propsArr do
		(
			try 
			(
				local val = getProperty ref prop
				dic[(prop as string)] = (val as string) 
			) 
			catch (format "No property '%' in '%'\n" prop ref.name)
		)	
		--return
		(dic)
	)
	
	function GetInstanceProperties ref addClassOf:true = --returns as python dictionary
	(
		local props = getPropNames ref
		local dic = GetProps ref props
		if addClassof then 
		(
			dic[classof_tag] = (classof ref) as string
		)
		--return		
		(dic)
	)	
	
	
	function getCommonNodeProps ref = --return dict
	(
		local s = "name material parent displayByLayer motionByLayer renderByLayer colorByLayer globalIlluminationByLayer"
		s = s + " isTarget lookAt target targetDistance isHidden isNodeHidden isHiddenInVpt isFrozen isNodeFrozen xray"
		s = s + " boxMode allEdges vertexTicks backFaceCull showTrajectory ignoreExtents showFrozenInGray wireColor showLinks showLinksOnly"
		s = s + " showVertexColors vertexColorType vertexColorsShaded isDependent visibility renderable inheritVisibility primaryVisibility"
		s = s + " secondaryVisibility receiveShadows castShadows applyAtmospherics renderOccluded gbufferChannel imageMotionBlurMultiplier motionBlurOn"
		s = s + " motionBlurOnController motionBlur"; 
		local props = filterString s " "
		local dic = GetProps ref props
		--ret
		dic[classof_tag] = (classof ref) as string
		(dic)
	)
	
	function getModifiers ref = --return array of dicts?
	(
		local mods = #()
		for i=1 to ref.modifiers.count do
		(
			local m = ref.modifiers[i] 
			mods[i] = GetInstanceProperties m 
			--TODO: add common modifier properties
			
			mods[i]["name"] = m.name
			mods[i]["enabled"] = m.enabled as string
			mods[i]["enabledInViews"] = m.enabledInViews as string
			mods[i]["enabledInRenders"] = m.enabledInRenders as string			
		)
		--ret
		(mods)
	)
	
	function InspectAllNodes =
	(		
		local sceneDict = py.dict()
		local nodesDict = py.dict()
		for obj in objects do
		(
			local propGroups = py.dict()
			propGroups["commonnode"] = getCommonNodeProps obj			
			propGroups["baseobject"] = GetInstanceProperties obj.baseObject
			propGroups["inode"] = GetInstanceProperties obj.inode addClassOf:false
			propGroups["modifiers"] = getModifiers obj
			nodesDict[(obj.inode.handle as string)+" "+obj.name]  = propGroups
		)
		sceneDict["nodes"]=nodesDict;
		local ss = (json.dumps sceneDict indent:2) as stringStream		
		include @"F:\_px\3D\MaxScripts\_common\TextParse.mxs"
		local tp = TextParse()
		tp.WriteAllText ss @"F:\_px\3D\MaxScripts\MaxCompare\output.json" 
		close ss
	)
	InspectAllNodes();
)