

thePI = thepainterinterface
thePI.startPaintSession()
thePI.initializeNodes 0 ($ as array)

function startStroke = 
(
	print "start stroke"
)

function paintStroke =
(
	--print "paint"
	local theObj = undefined
	local bary = [0,0,0]
	local faceIndex = 1
	theObj = thePI.getHitNode 0
	thePI.getHitFaceData &bary &faceIndex theObj 0	
	format "% % %\n" bary faceIndex theobj
	
	--<node>thePainterInterface.getHitNode <index>sampleIndex 
)

function endStroke =
(
	print "end"
)

function cancelStroke =
(
	print "end"
)

function SystemEndPaintSession =
(
	print "end paint session"
)

function endSession =
(
	thePI.endPaintSession()
)

thePI.scriptFunctions startStroke paintStroke endStroke cancelStroke SystemEndPaintSession