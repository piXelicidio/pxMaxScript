d = getFiles "D:\\Denys\\3d design Max9\\Diablo\\renders2\\DigitalCounter\\*.jpg"
for fx in d do
(
	s = filenameFromPath( fx )
	--cambia el nombre y lo deja intacto los ultimos 7 caracteres se incluye la extension
	news = "DigitalCounter_0" + ( substring s (s.count-7) -1)
	news = getFileNamePath( fx ) + news
	print news
	RenameFile fx news
)

