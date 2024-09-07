if [ ! -f utilities/xslstyle/xslstyle-docbook.xsl ] || \
   [ ! -f utilities/saxon655/saxon.jar ]
then
echo Expecting the XSLStyle documentation subsystem is installed in the
echo utilities/xslstyle/ directory: https://github.com/CraneSoftwrights/xslstyle and
echo expecting the Saxon 6.5.5 XSLT 1 processor is installed in the
echo utilities/saxon655/ directory:
echo https://sourceforge.net/projects/saxon/files/saxon6/6.5.5/
exit 1
fi
java -jar utilities/saxon655/saxon.jar -a -o designSVG2burnFiles.html designSVG2burnFiles.xsl
open designSVG2burnFiles.html
java -jar utilities/saxon655/saxon.jar -a -o convertBadStrokes4designSVG.html convertBadStrokes4designSVG.xsl
open convertBadStrokes4designSVG.html
