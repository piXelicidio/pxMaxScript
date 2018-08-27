macroScript ThePuppetTool category:"ScriptAttack" buttonText:"TPT" tooltip:"ThePuppetTool v1.1" --Icon: #("SuperPainter",1) --silentErrors: true
(

global floaterThePuppetTool
global floaterThePuppetToolpos=[100,100]
	
on ischecked return try(execute "floaterThePuppetTool.isOpen")catch(off)
on execute do (
if (floaterThePuppetTool == undefined) then (
try (
check=(getDir #ui); check=substring check check.count 1
a=(getDir #ui)+"\\macroscripts\\ThePuppetTool\\ThePuppetTool.mse"
if check=="\\" then a=(getDir #ui)+"macroscripts\\ThePuppetTool\\ThePuppetTool.mse"
filein a
)
catch(ClearListener())
)
if floaterThePuppetTool.isOpen then (floaterThePuppetToolpos=GetDialogPos floaterThePuppetTool; destroyDialog floaterThePuppetTool; updateToolbarButtons())
else (CreateDialog floaterThePuppetTool pos: floaterThePuppetToolpos style: #(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox)
	--CreateDialog floaterThePuppetTool pos: floaterThePuppetToolpos
	)
)
)