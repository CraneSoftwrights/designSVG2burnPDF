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

rm designSVG2burnFiles.html
java -jar utilities/saxon655/saxon.jar -a -o designSVG2burnFiles.html designSVG2burnFiles.xsl
if [ $? -ne 0 ]; then
  exit 1
fi
if [ ! -f designSVG2burnFiles.html ]; then
  echo "Error: Documentation not produced
fi
if grep -q -i "inconsistencies.detected" designSVG2burnFiles.html; then
  echo "Error: The file designSVG2burnFiles.html contains inconsistencies."
  exit 1
fi

rm convertBadStrokes4designSVG.html
java -jar utilities/saxon655/saxon.jar -a -o convertBadStrokes4designSVG.html convertBadStrokes4designSVG.xsl
if [ $? -ne 0 ]; then
  exit 1
fi
if [ ! -f convertBadStrokes4designSVG.html ]; then
  echo "Error: Documentation not produced
fi
if grep -q -i "inconsistencies.detected" convertBadStrokes4designSVG.html; then
  echo "Error: The file convertBadStrokes4designSVG.html contains inconsistencies."
  exit 1
fi

echo Documentation created successfully
