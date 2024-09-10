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

<xsl:import href="commonDesignSVG.xsl"/>

<xs:doc info="" filename="designSVG2burnFiles.xsl" vocabulary="DocBook">
  <xs:title>Convert "troublesome" strokes from a Crane designSVG file</xs:title>
  <para>
    This stylesheet walks through a Crane designSVG file reporting and
    replacing non-zero strokes that are less than a given dimension provided as
    an argument to be that specified minimum dimension on output.
  </para>
  <para>
    The need arose when arbitrary graphics with arbitrary scaling resulted in
    a stroke specification that triggers cutting instead of rastering. Cleaning
    the strokes with this stylesheet ensures those seemingly benign
    specifications are not transformed into a troublesome specification
    resulting in lost material due to unexpected and unwanted cutting.
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

<!--========================================================================-->
<xs:doc>
  <xs:title>Invocation parameters and input file</xs:title>
  <para>
    The input file is a Crane designSVG file.
  </para>
</xs:doc>
  
<xs:param>
  <para>
    The minimum width allowed for a stroke, lower of which are elided.
  </para>
</xs:param>
<xsl:param name="minimum-stroke-width" as="xsd:string" required="yes"/>

<xs:variable>
  <para>
    The minimum stroke width for comparison purposes
  </para>
</xs:variable>
<xsl:variable name="c:minimumStrokeWidthInInches" as="xsd:double"
              select="c:lengthInInchesDefaultPX($minimum-stroke-width)"/>

<xs:param>
  <para>
    The colour assumed to be modified into a cutting stroke.
  </para>
</xs:param>
<xsl:param name="cut-colour" as="xsd:string" required="yes"/>

<xs:variable>
  <para>Need to remember the input context for key() to work</para>
</xs:variable>
<xsl:variable name="c:top" as="document-node()" select="/"/>
  
<!--========================================================================-->
<xs:doc>
  <xs:title>Process all content</xs:title>
</xs:doc>

<xs:template>
  <para>Check arguments then continue</para>
</xs:template>
<xsl:template match="/">
  <xsl:variable name="c:analysisStrings" as="xsd:string*">
    <!--check the arguments for stroke widths-->
    <xsl:if test="not(replace($minimum-stroke-width,'([\d\.\-]+)(\w+)?','$1')
                        castable as xsd:double)">
      <xsl:value-of select="concat('Specified minimum stroke width ''',
                                   $minimum-stroke-width,
                         ''' is not a number optionally followed by a unit')"/>
    </xsl:if>
  </xsl:variable>
  <!--bail if any such problems-->
  <xsl:if test="exists($c:analysisStrings)">
    <xsl:message terminate="yes"
                 select="string-join(($c:analysisStrings,
                                    concat(count($c:analysisStrings),
                                           ' reports to be fixed')),'&#xa;')"/>
  </xsl:if>
  <!--bail if any such problems-->
  <xsl:if test="exists($c:analysisStrings)">
    <xsl:message terminate="yes"
                 select="string-join(($c:analysisStrings,
                                    concat(count($c:analysisStrings),
                                           ' reports to be fixed')),'&#xa;')"/>
  </xsl:if>
 
  
  <xsl:next-match/>
</xsl:template>

<xs:template>
  <para>Preserve everything else</para>
</xs:template>
<xsl:template match="node()">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates select="node()"/>
  </xsl:copy>
</xsl:template>

<xs:template>
  <para>Preserve all defs</para>
</xs:template>
<xsl:template match="defs">
  <xsl:copy-of select="."/>
</xsl:template>

<xs:template>
  <para>
    Catch all strokes to check each
  </para>
</xs:template>
<xsl:template match="*[contains(@style,'stroke-width')]
                      [not(contains(@style,'stroke:none'))]">
  <xsl:variable name="c:strokeColour"
        select="if( contains( @style, 'stroke:#' ) )
                then replace(@style,'.*?stroke:#([^;]*);?.*','$1') else ''"/>
  <xsl:variable name="c:strokeWidth" 
       select="replace(@style,'^.*?stroke-width:([\d\.\-]+\w*);?.*$','$1')"/>
  <xsl:variable name="c:strokeWidthLength" 
       select="replace(@style,'^.*?stroke-width:([\d\.\-]+)\w*;?.*$','$1')"/>
  <xsl:variable name="c:normalizedWidthInInches"
                select="c:lengthInInches($c:strokeWidthLength)"/>
  <xsl:variable name="c:scale"
                select="c:determineAncestralStrokeScalingFactor(.)"/>
  <xsl:variable name="c:scaledWidthInInches"
                select="round( $c:normalizedWidthInInches * $c:scale * 100000 )
                        div 100000"/>
  <xsl:variable name="c:scaledMinimumWidthInInches"
                select="if( $c:scale = 0 ) then 0
else round(($c:minimumStrokeWidthInInches div $c:scale) * 100000) div 100000"/>
  <xsl:variable name="c:scaledMinimumWidthInDefault"
                select="round( c:lengthInDefault(
           concat($c:scaledMinimumWidthInInches,'in')) * 100000 ) div 100000"/>
  
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:choose>
      <xsl:when test="empty(@style)">
        <!--nothing to look for here!-->
      </xsl:when>
      <xsl:when test="not( $c:strokeWidthLength castable as xsd:double )">
        <xsl:message select="concat('Unexpected stroke specification ''',
                                     $c:strokeWidth,''' ',
                                     c:labelPath(.),' = ',$c:strokeWidth)"/>
        <!--bad attriBute is being preserved-->
      </xsl:when>
      <xsl:when test="$c:strokeColour = $cut-colour">
        <!--preserve; don't treat as problem; the stroke will get converted-->
      </xsl:when>
      <xsl:when test="$c:scaledWidthInInches = 0">
        <!--special case; leave zeroes alone-->
      </xsl:when>
      <xsl:when test="$c:scaledWidthInInches &lt; $c:minimumStrokeWidthInInches
                  and $c:strokeColour != $cut-colour">
          <xsl:variable name="c:newStyle"
                        select="replace(@style,'stroke-width:([^;]*);?',
                concat('stroke-width:',$c:scaledMinimumWidthInDefault,';'))"/>
          <xsl:attribute name="style" select="$c:newStyle"/>
          <xsl:message select="'Cutting stroke increased from',
                                $c:scaledWidthInInches,'inches to',
                                $c:minimumStrokeWidthInInches,'inches',
                                '=',$c:scaledMinimumWidthInDefault,
                                c:labelPath(.),' old =',$c:strokeWidth,
                                '=',$c:normalizedWidthInInches,'inches;',
                                'less than',$c:scaledMinimumWidthInInches,
                                'inches scale',$c:scale,
                                (ancestor-or-self::*[@transform]/@transform/
                            (string(.),'=',c:determineStrokeScalingFactor(.))),
                                '@',$c:scale,'=',$c:scaledWidthInInches,
                                'colour',$c:strokeColour,'new:',$c:newStyle"/>
      </xsl:when>
    </xsl:choose>
    <xsl:apply-templates select="node()"/>
  </xsl:copy>
  
</xsl:template>

</xsl:stylesheet>
