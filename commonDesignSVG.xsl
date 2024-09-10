<?xml version="1.0" encoding="US-ASCII"?>
<?xml-stylesheet type="text/xsl" href="utilities/xslstyle/xslstyle-docbook.xsl"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.CraneSoftwrights.com/ns/xslstyle"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
                xmlns:math="http://www.w3.org/2005/xpath-functions/math"
                xmlns="http://www.w3.org/2000/svg"
                xmlns:c="urn:X-Crane"
                exclude-result-prefixes="xs xsd c math"
                xpath-default-namespace="http://www.w3.org/2000/svg"
                version="2.0">

<xs:doc info="" filename="designSVG2burnFiles.xsl" vocabulary="DocBook">
  <xs:title>Common code supporting Crane's designSVG files</xs:title>
  <para>
    This stylesheet is supporting multiple stylesheets that access a Crane
    designSVG file.
  </para>
  <programlisting>
BSD 3-Clause License

Copyright (c) 2024, Crane Softwrights Ltd.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.    
  </programlisting>
</xs:doc>

<xs:function>
  <para>
    Return the indication of the given Inkscape construct specifying
    a directory
  </para>
  <xs:param name="c:node">
    <para>Where to look from</para>
  </xs:param>
</xs:function>
<xsl:function name="c:isAdirectory" as="xsd:boolean">
  <xsl:param name="c:node" as="node()"/>
  <xsl:sequence select="exists($c:node
                        [tokenize(@inkscape:label,'\s+')[normalize-space(.)][1]
                         [ends-with(.,'/')]])"/>
</xsl:function>

<xs:function>
  <para>
    Return the path inferred by ancestral Inkscape labels that end with "/"
  </para>
  <xs:param name="c:node">
    <para>Where to look from</para>
  </xs:param>
</xs:function>
<xsl:function name="c:getPath" as="xsd:string">
  <xsl:param name="c:node" as="node()"/>
  <xsl:sequence select="
                  string-join($c:node/ancestor-or-self::*[c:isAdirectory(.)]/
                  tokenize(@inkscape:label,'\s+')[normalize-space(.)][1],'')"/>
</xsl:function>

<xs:function>
  <para>Report the hierarchy of labels including and above the given</para>
  <xs:param name="c:context">
    <para>Where to start from</para>
  </xs:param>
</xs:function>
<xsl:function name="c:labelPath" as="xsd:string">
  <xsl:param name="c:context" as="node()"/>
  <xsl:value-of>
    <xsl:for-each select="($c:context/ancestor-or-self::*)">
      <xsl:text>&#xa;</xsl:text>
      <xsl:for-each select="1 to position()">
        <xsl:text>  </xsl:text>
      </xsl:for-each>
      <xsl:variable name="c:ref" select="(@inkscape:label,@id)[1]"/>
      <xsl:text/>"<xsl:value-of select="$c:ref"/>"<xsl:text/>
      <xsl:if test="preceding-sibling::*[(@inkscape:ladebel,@id)[1]=$c:ref]">
        <xsl:text/>[<xsl:value-of select="count(preceding-sibling::*
                [(@inkscape:label,@id)[1]=$c:ref]) + 1"/>]<xsl:text/>
      </xsl:if>
      <xsl:for-each select="@id">{<xsl:value-of select="."/>}</xsl:for-each>
      <xsl:if test="position()!=last()">/</xsl:if>
    </xsl:for-each>
  </xsl:value-of>
</xsl:function>

<xs:function>
  <para>
    Determine a scaling factor from all contributors to scaling found in
    an element's attributes.
  </para>
  <xs:param name="c:transformation">
    <para>The string of functions applied to </para>
  </xs:param>
</xs:function>
<xsl:function name="c:determineStrokeScalingFactor" as="xsd:double">
  <xsl:param name="c:transformation" as="xsd:string?"/>
  
  <xsl:variable name="c:factors" as="xsd:double*">
    <!--ensure the sequence of scaling factors is not empty-->
    <xsl:analyze-string select="$c:transformation" flags="x"
                        regex="(matrix|scale)\s*\(\s*([\d.-]+)
 (\s*,\s*([\d.-]+))?(\s*,\s*([\d.-]+))?(\s*,\s*([\d.-]+))?(\s*,\s*([\d.-]+))?">
      <xsl:matching-substring>
        <xsl:choose>
          <xsl:when test="regex-group(1)='scale'">
            <!--scale(sx)-->
            <xsl:sequence select="(regex-group(2),'1')[normalize-space(.)][1]
                                  cast as xsd:double,
                                  (regex-group(4),'1')[normalize-space(.)][1]
                                  cast as xsd:double"/>
          </xsl:when>
          <xsl:otherwise><!--'matrix-->
            <xsl:variable name="c:a"
     select="(regex-group(2),'0')[normalize-space(.)][1] cast as xsd:double"/>
            <xsl:variable name="c:b"
     select="(regex-group(4),'0')[normalize-space(.)][1] cast as xsd:double"/>
            <xsl:variable name="c:c"
     select="(regex-group(6),'0')[normalize-space(.)][1] cast as xsd:double"/>
            <xsl:variable name="c:d"
     select="(regex-group(8),'0')[normalize-space(.)][1] cast as xsd:double"/>
            <xsl:sequence select="for $c:determinant in
                                  abs(($c:a * $c:d) - ($c:b * $c:c))
                                  return if( $c:determinant = 0 ) then 0 else
                                  math:sqrt( $c:determinant )"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:matching-substring>
    </xsl:analyze-string>
  </xsl:variable>
  <xsl:sequence select="c:product($c:factors)"/>
</xsl:function>

<xs:function>
  <para>
    Determine a scaling factor from all contributors to scaling found in
    an element's ancestors.
  </para>
  <xs:param name="c:node">
    <para>Where to start looking for ancestors</para>
  </xs:param>
</xs:function>
<xsl:function name="c:determineAncestralStrokeScalingFactor" as="xsd:double">
  <xsl:param name="c:node" as="node()?"/>

  <xsl:sequence select="c:product($c:node/ancestor-or-self::*[@transform]/
                                 c:determineStrokeScalingFactor(@transform))"/>
</xsl:function>

<xs:function>
  <para>
    Calculate the product of a sequence of numbers
  </para>
  <xs:param name="c:seq">
    <para>The sequence of numbers being converted</para>
  </xs:param>
</xs:function>
<xsl:function name="c:product" as="xsd:double">
  <xsl:param name="c:seq" as="xsd:double*"/>
  <xsl:sequence select="($c:seq[1] * c:product($c:seq[position()>1]),1)[1]"/>
</xsl:function>

<xs:function>
  <para>
    Convert a length specification '\d+\w* into a specific number of inches.
  </para>
  <xs:param name="c:length">
    <para>The string being converted</para>
  </xs:param>
</xs:function>
<xsl:function name="c:lengthInInchesDefaultPX" as="xsd:double?">
  <xsl:param name="c:length" as="xsd:string"/>
  <xsl:sequence select="c:lengthInInchesWithDefault($c:length,1 div 96)"/>
</xsl:function>

<xs:function>
  <para>
    Convert a length specification '\d+\w* into a specific number of inches.
  </para>
  <xs:param name="c:length">
    <para>The string being converted</para>
  </xs:param>
</xs:function>
<xsl:function name="c:lengthInInches" as="xsd:double?">
  <xsl:param name="c:length" as="xsd:string?"/>
  <xsl:sequence
             select="c:lengthInInchesWithDefault($c:length,$c:nonUnitInches)"/>
</xsl:function>

<xs:function>
  <para>
    Convert a length specification '\d+\w* into a specific number of inches.
  </para>
  <xs:param name="c:length">
    <para>The string being converted</para>
  </xs:param>
  <xs:param name="c:defaultConversionToInches">
    <para>The conversion to use as default when no units specified</para>
  </xs:param>
</xs:function>
<xsl:function name="c:lengthInInchesWithDefault" as="xsd:double?">
  <xsl:param name="c:length" as="xsd:string?"/>
  <xsl:param name="c:defaultConversionToInches" as="xsd:double"/>
  <xsl:for-each select="normalize-space($c:length)">
    <xsl:variable name="c:amount" 
             select="replace(.,'([\d\.\-]+)(\w+)?','$1') cast as xsd:double"/>
    <xsl:variable name="c:units" 
             select="replace(.,'([\d\.\-]+)(\w+)?','$2')"/>
    <xsl:variable name="c:normalizedWidthInchesFactor"
                  select="if( $c:units='' )   then $c:defaultConversionToInches
                     else if( $c:units='px' ) then 1 div 96
                     else if( $c:units='pt' ) then 1 div 72
                     else if( $c:units='pc' ) then 1 div 6
                     else if( $c:units='mm' ) then 1 div 25.4
                     else if( $c:units='cm' ) then 1 div 2.54 else 1"/> 
    <xsl:sequence select="$c:amount * $c:normalizedWidthInchesFactor"/>
  </xsl:for-each>
</xsl:function>

<xs:function>
  <para>
    Convert a length specification '\d+\w* into a specific number of units
    of default size.
  </para>
  <xs:param name="c:length">
    <para>The string being converted</para>
  </xs:param>
</xs:function>
<xsl:function name="c:lengthInDefault" as="xsd:double?">
  <xsl:param name="c:length" as="xsd:string?"/>
  <xsl:for-each select="normalize-space($c:length)">
    <xsl:variable name="c:amount" 
             select="replace(.,'([\d\.\-]+)(\w+)?','$1') cast as xsd:double"/>
    <xsl:variable name="c:units" 
             select="replace(.,'([\d\.\-]+)(\w+)?','$2')"/>
    <xsl:variable name="c:normalizedWidthDefaultFactor"
            select="if( $c:units='' )   then 1
               else if( $c:units='px' ) then $c:nonUnitInches * 96
               else if( $c:units='pt' ) then $c:nonUnitInches * 72
               else if( $c:units='pc' ) then $c:nonUnitInches * 6
               else if( $c:units='mm' ) then $c:nonUnitInches * 25.4
               else if( $c:units='cm' ) then $c:nonUnitInches * 2.54
                                        else $c:nonUnitInches"/> 
    <xsl:sequence select="$c:amount div $c:normalizedWidthDefaultFactor"/>
  </xsl:for-each>
</xsl:function>

<xs:variable>
  <para>
    Determine in inches the unit of measure of non-unit-specified values
  </para>
</xs:variable>
<xsl:variable name="c:nonUnitInches" as="xsd:double">
  <xsl:variable name="c:pageWidthInInches" as="xsd:double"
                select="c:lengthInInchesDefaultPX(/svg/@width)"/>
  <xsl:variable name="c:viewWidth" as="xsd:double"
                select="for $c:width in replace(/svg/@viewBox,
                    '\s*([-.\d]+)\s*([-.\d]+)\s*([-.\d]+)\s*([-.\d]+)\s*','$3')
                        return $c:width cast as xsd:double"/>
  <xsl:sequence select="$c:pageWidthInInches div $c:viewWidth"/>
</xsl:variable>

</xsl:stylesheet>
