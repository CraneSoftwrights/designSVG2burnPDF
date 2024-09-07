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
  <xs:title>Burst a Crane SVG design file into individual SVG burn files</xs:title>
  <para>
    This stylesheet is taking a collection of sets of layers and creating
    individual SVG files with only the layers in the given set. At the same
    time, any strokes that are magenta in colour are indicated to have a
    specified stroke width for the cutter to recognize as a cut, not an etch.
    A set of Inkscape action files is created and the invocation of Inkscape
    for these files.
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
    The input file has layers with layer titles that name the output SVG file
    dedicated to that layer's content.
  </para>
</xs:doc>
  
<xs:output>
  <para>The output is a script to be executed in the operating system</para>
</xs:output>
<xsl:output method="text"/>
  
<xs:param>
  <para>
    The path in which to put the SVG XML files and action text files.
  </para>
</xs:param>
<xsl:param name="path2svg" as="xsd:string" required="yes"/>

<xs:param>
  <para>
    The path in which to put the result PNG files
  </para>
</xs:param>
<xsl:param name="path2png" as="xsd:string" required="yes"/>

<xs:param>
  <para>
    The path in which to put the result PDF files
  </para>
</xs:param>
<xsl:param name="path2pdf" as="xsd:string" required="yes"/>

<xs:param>
  <para>
    The suffix to use for the names of the files generated.
  </para>
</xs:param>
<xsl:param name="name-suffix" as="xsd:string" required="yes"/>

<xs:param>
  <para>
    The colour assumed to be modified into a cutting stroke.
  </para>
</xs:param>
<xsl:param name="cut-colour" as="xsd:string" required="yes"/>

<xs:param>
  <para>
    The width to use for a cutting stroke.
  </para>
</xs:param>
<xsl:param name="cut-width" as="xsd:string" required="yes"/>

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

<xs:variable>
  <para>Need to remember the input context for key() to work</para>
</xs:variable>
<xsl:variable name="c:top" as="document-node()" select="/"/>

<!--========================================================================-->
<xs:doc>
  <xs:title>Convert all identified layers</xs:title>
</xs:doc>

<xs:key>
  <para>Find some layers that are building blocks</para>
</xs:key>
<xsl:key name="c:build"
         match="g[matches(@inkscape:label,':')]"
         use="'__all__',
              for $each in tokenize(@inkscape:label,'\s+')[matches(.,':')]
              return substring-before($each,':')"/>

<xs:key>
  <para>Find more layers that are building blocks</para>
</xs:key>
<xsl:key name="c:build"
         match="g[starts-with(tokenize(@inkscape:label,'\s+')[2],'=')]"
         use="'__all__',
              tokenize(@inkscape:label,'\s+')[1]"/>

<xs:key>
  <para>Find all layers that are assembled building blocks</para>
</xs:key>
<xsl:key name="c:assemble" use="'__all__',tokenize(@inkscape:label,'\s+')[1]"
         match="g[not(ancestor-or-self::*[contains(@style,'display:none')])]
                 [tokenize(@inkscape:label,'\s+')[starts-with(.,'=')]]"/>

<xs:key>
  <para>Find all objects based on their label</para>
</xs:key>
<xsl:key name="c:objectsByLabel" match="*[@inkscape:label]"
         use="normalize-space(@inkscape:label)"/>

<xs:key>
  <para>All ids</para>
</xs:key>
<xsl:key name="c:objectsById" match="*[@id]" use="normalize-space(@id)"/>

<xs:template>
  <para>
    Can't get started
  </para>
</xs:template>
<xsl:template match="/*">
  <xsl:message terminate="yes"
               select="'Unexpected input document element:',name(.)"/>
</xsl:template>

<xs:template>
  <para>Get started</para>
</xs:template>
<xsl:template match="/svg" priority="1">
  <!--Checking the arithmetic:
  <xsl:message select="'DEBUG nonUnitInches',$c:nonUnitInches"/>
  <xsl:message select="'DEBUG length .001in',c:lengthInDefault('.001in')"/>
  <xsl:message select="'DEBUG length 1pc',c:lengthInDefault('1pc')"/>
  <xsl:message select="'DEBUG length 1in',c:lengthInDefault('1in')"/>
  <xsl:message select="'DEBUG length 1cm',c:lengthInDefault('1cm')"/>
  <xsl:message select="'DEBUG length 1mm',c:lengthInDefault('1mm')"/>
  <xsl:message select="'DEBUG length  1 def',c:lengthInDefault('1')"/>
  <xsl:message select="c:determineStrokeScalingFactor(())"/>
  <xsl:message select="c:determineStrokeScalingFactor('matrix(1,1,1,1,0,0)')"/>
  <xsl:message select="c:determineStrokeScalingFactor('
matrix(-0.10215694,0.10215694,-0.10214641,-0.10214641,282.66397,204.85245)')"/>
  <xsl:message select="c:determineStrokeScalingFactor('scale(1)')"/>
  <xsl:message select="c:determineStrokeScalingFactor('scale(1,1)')"/>
  <xsl:message select="c:determineStrokeScalingFactor('scale(2,3)')"/>
  -->
  <!--where are all the images?-->
  <!--<xsl:message terminate="yes">
    <xsl:for-each select="//image">
      <xsl:text>
    </xsl:text>
      <xsl:value-of select="c:labelPath(.)"/>
    </xsl:for-each>
  </xsl:message>-->
  

  <!--in support of the integrity check on version strings-->
  <xsl:variable name="c:printVersionStrings"
                select="key('c:objectsByLabel','Version')/
                        replace(.,'[\s-:]','')"/>

  <!--other integrity checks-->
  <xsl:variable name="c:analysisStrings" as="xsd:string*">
    <!--If multiple version strings, they must all be the same-->
    <xsl:if test="count(distinct-values($c:printVersionStrings))>1">
      <xsl:value-of select="'Inconsistent version strings:',
                           distinct-values($c:printVersionStrings),
                           'at locations:',
       string-join( key('c:objectsByLabel','Version')/c:labelPath(.), '; ' )"/>
    </xsl:if>
    
    <!--check the arguments for stroke widths-->
    <xsl:if test="not(replace($minimum-stroke-width,'([\d\.\-]+)(\w+)?','$1')
                        castable as xsd:double)">
      <xsl:value-of select="concat('Specified minimum stroke width ''',
                                   $minimum-stroke-width,
                                   ''' is not a number followed by a unit')"/>
    </xsl:if>
    <xsl:if test="not(replace($cut-width,'([\d\.\-]+)(\w+)?','$1')
                        castable as xsd:double)">
      <xsl:value-of select="concat('Specified cutting stroke width ''',
                                   $cut-width,
                                   ''' is not a number followed by a unit')"/>
    </xsl:if>
    
    <!--If no or multiple ids being referenced, cannot guess which to use-->
    <xsl:for-each select="key('c:assemble','__all__',$c:top)">
      <xsl:variable name="c:refs" select="tokenize(@inkscape:label,'\s+')"/>
      <xsl:call-template name="c:checkReferencedLayers">
        <xsl:with-param name="c:layer" select="."/>
        <xsl:with-param name="c:review" tunnel="yes" select="true()"/>
      </xsl:call-template>
    </xsl:for-each>
  
    <!--check anything close to burn size that isn't expressly cut colour-->
    <xsl:variable name="c:checkStrokes"
                  select="(//*[contains(@style,'stroke-width')]
                              [not(contains(@style,'stroke:none'))]) except (//defs//*)"/>
    <xsl:for-each select="$c:checkStrokes">
      <xsl:variable name="c:strokeColour"
          select="if( contains( @style, 'stroke:#' ) )
                  then replace(@style,'.*?stroke:#([^;]*);?.*','$1') else ''"/>
      <xsl:variable name="c:strokeWidth" 
         select="replace(@style,'^.*?stroke-width:([\d\.\-]+\w*);?.*$','$1')"/>
      <xsl:variable name="c:strokeWidthLength" 
         select="replace(@style,'^.*?stroke-width:([\d\.\-]+)\w*;?.*$','$1')"/>
      <xsl:variable name="c:strokeWidthLength" 
           select="replace(@style,'.*?stroke-width:([\d\.\-]+)\w*;?.*','$1')"/>
      <xsl:variable name="c:normalizedWidthInInches"
                    select="c:lengthInInches($c:strokeWidthLength)"/>
      <xsl:variable name="c:scale"
                    select="c:determineStrokeScalingFactor(@transform)"/>
      <xsl:variable name="c:scaledWidthInInches"
                select="round( $c:normalizedWidthInInches * $c:scale * 100000 )
                        div 100000"/>
      
      <xsl:choose>
        <xsl:when test="not( $c:strokeWidthLength castable as xsd:double )">
          <xsl:value-of select="concat('Unexpected stroke specification ''',
                                       $c:strokeWidth,''' ',
                                       c:labelPath(.),' = ',$c:strokeWidth)"/>
        </xsl:when>
        <xsl:when test="$c:strokeColour = $cut-colour">
          <!--don't treat as a problem; the stroke will get converted-->
        </xsl:when>
        <xsl:when test="$c:scaledWidthInInches = 0">
          <!--special case; leave zeroes alone-->
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="$c:scaledWidthInInches&lt;$c:minimumStrokeWidthInInches
                    and $c:strokeColour != $cut-colour">
            <xsl:value-of>
              <xsl:value-of select="'Rogue cutting stroke detected at',
                                    $c:scaledWidthInInches,'inches (min',
                                    $c:minimumStrokeWidthInInches,' inches)',
                                    c:labelPath(.),'=',$c:strokeWidth,
                                    string(@transform),'colour',
                                    $c:strokeColour"/>
            </xsl:value-of>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  
  </xsl:variable>
  <!--bail if any such problems-->
  <xsl:if test="exists($c:analysisStrings)">
    <xsl:message terminate="yes"
                 select="string-join(($c:analysisStrings,
                                    concat(count($c:analysisStrings),
                                           ' reports to be fixed')),'&#xa;')"/>
  </xsl:if>
  
  <!--======================================================-->
  <xsl:variable name="c:output" select="key('c:assemble','__all__',$c:top)"/>

  <!--create review SVG file of all layers-->
  <xsl:result-document href="{$path2svg}review-all-burns{$name-suffix}.svg"
                       method="xml" indent="no">
    <xsl:copy>
      <!--preserve document element-->
      <xsl:copy-of select="@*"/>
      <!--preserve everything other than groups-->
      <xsl:copy-of select="* except g"/>
      <!--put everything in a group to make conversion easier-->
      <g inkscape:label="All {count(key('c:assemble','__all__',$c:top))
                        } burn files with cutting disabled but visible">
        <xsl:for-each select="key('c:assemble','__all__',$c:top)">
          <xsl:variable name="c:refs" 
                        select="tokenize(@inkscape:label,'\s+')"/>
          <!--the output layer uses the given name-->
          <g inkscape:label="{@inkscape:label}" id="{$c:refs[1]}"
             style="display:none">
            <xsl:call-template name="c:addReferencedLayers">
              <xsl:with-param name="c:layer" select="."/>
              <xsl:with-param name="c:review" tunnel="yes" select="true()"/>
            </xsl:call-template>
          </g>
        </xsl:for-each>
      </g>
    </xsl:copy>
  </xsl:result-document>
  
  <!--======================================================-->

  <!--create individual SVG files for each layer-->
  <xsl:for-each select="$c:output">
    <xsl:variable name="c:thisAssembly" select="."/>
    <!--determine (and assume) umique identifier for each-->
    <xsl:variable name="c:tokens" 
               select="c:disambiguateTokens(tokenize(@inkscape:label,'\s+'))"/>
    <!--act on the disambiguated references; initial tokens should be same-->
    <xsl:variable name="c:id" select="$c:tokens[1]"/>
    <xsl:variable name="c:path" select="c:getPath(.)"/>
    <xsl:variable name="c:directive" select="$c:tokens[2]"/>
    <!--create the SVG file for the target layer-->
    <xsl:result-document href="{$path2svg}{$c:path}{$c:id}{$name-suffix}.svg"
                         method="xml" indent="no">
      <xsl:for-each select="$c:top/*">
        <xsl:copy>
          <!--preserve document element-->
          <xsl:copy-of select="@*"/>
          <!--preserve everything other than groups-->
          <xsl:copy-of select="* except g"/>
          <!--put out the one group only, turning on visibility-->
          <xsl:for-each select="$c:thisAssembly">
            <xsl:copy>
              <xsl:copy-of select="@*"/>
              <xsl:attribute name="id" select="$c:id"/>
              <xsl:attribute name="style"
                             select="concat('display:inline;',
                                       replace(@style,'display:[^;]+;?',''))"/>
              <xsl:call-template name="c:addReferencedLayers">
                <xsl:with-param name="c:layer" select="."/>
              </xsl:call-template>
            </xsl:copy>
          </xsl:for-each>
        </xsl:copy>
      </xsl:for-each>
    </xsl:result-document>

    <!--======================================================-->

    <!--create the Inkscape actions file for the target layer-->
    <xsl:result-document method="text"
                      href="{$path2svg}{$c:path}{$c:id}{$name-suffix}.svg.txt">
<xsl:text/>select-by-id:<xsl:value-of 
                                  select="$c:id"/>
      <xsl:text>;object-to-path;select-clear;
</xsl:text>
      <xsl:choose>
        <xsl:when test="$c:directive='=#'"><!--this is a collage-->
          <xsl:for-each select="$c:tokens[starts-with(.,'#')]">
<xsl:text/>select-by-id:<xsl:value-of select="replace(.,'^#?(.+?)$','$1')"
                                         />;page-fit-to-selection;select-clear;  
<xsl:text/>
          </xsl:for-each>
          <xsl:for-each select="$c:tokens[position()>2 and
                                          not(starts-with(.,'#'))]">
            <xsl:variable name="c:rotation"
           select="if( position() mod 2 = 0 ) then 'ccw;' else 'cw;'"/>
            <xsl:variable name="c:horizontal"
           select="if( position() mod 2 = 0 ) then 'object-align:right page;'
                                              else 'object-align:left page;'"/>
            <xsl:variable name="c:vertical"
           select="if( position() = ( 1,2 ) ) then 'object-align:top page;'
              else if( position() > last()-2 ) then 'object-align:bottom page;'
              else 'object-align:vcenter page;'"/>
<xsl:text/>select-by-id:<xsl:value-of select="
    concat(replace(.,'^#?(.+?):.*$','$1'),
    ';object-rotate-90-',$c:rotation,$c:vertical,$c:horizontal)"/>select-clear;
<xsl:text/>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="$c:directive='=!'"><!--this page is trimmed-->
<xsl:text/>page-fit-to-selection;
<xsl:text/>
        </xsl:when>
        <xsl:when test="$c:directive='=>'">
<xsl:text/>select-by-id:<xsl:value-of
       select="$c:id"/>;object-rotate-90-cw;page-fit-to-selection;select-clear;
<xsl:text/>
        </xsl:when>
        <xsl:when test="$c:directive='=&lt;'">
<xsl:text/>select-by-id:<xsl:value-of
       select="$c:id"/>;object-rotate-90-ccw;page-fit-to-selectio'n;select-clear;
<xsl:text/>
        </xsl:when>
        <xsl:when test="$c:directive=('=v','=V')">
<xsl:text/>select-by-id:<xsl:value-of
       select="$c:id"/>;object-rotate-90-cw;object-rotate-90-cw;page-fit-to-selection;select-clear;
<xsl:text/>
        </xsl:when>
        <xsl:when test="$c:directive='=|'">
<xsl:text/>select-by-id:<xsl:value-of
       select="$c:id"/>;object-flip-horizontal;page-fit-to-selection;select-clear;
<xsl:text/>
        </xsl:when>
        <xsl:when test="$c:directive='=-'">
<xsl:text/>select-by-id:<xsl:value-of
       select="$c:id"/>;object-flip-vertical;page-fit-to-selection;select-clear;
<xsl:text/>
        </xsl:when>
        <xsl:when test="$c:directive='='">
          <!--do nothing with the upright image-->
        </xsl:when>
        <xsl:otherwise>
          <xsl:message select="concat('Unexpected assignment directive ''',
                                      $c:directive,''' in layer ''',
                                      string(@inkscape:label),'''')"
                       terminate="yes"/>
        </xsl:otherwise>
      </xsl:choose>
<xsl:text/>export-filename:<xsl:value-of
      select='concat($path2svg,$c:path,$c:id,$name-suffix,".svg")'/>;export-do;
<xsl:text/>
<xsl:text/>export-dpi:300;export-filename:<xsl:value-of
      select='concat($path2png,$c:path,$c:id,$name-suffix,".png")'/>;export-do;
<xsl:text/>
<xsl:text/>export-dpi:300;export-filename:<xsl:value-of
      select='concat($path2pdf,$c:path,$c:id,$name-suffix,".pdf")'/>;export-do;
<xsl:text/>

    </xsl:result-document>
  </xsl:for-each>
  
  <!--======================================================-->
  
  <!--put out the script that invokes inkscape to the standard output-->
echo Number of outputs being created: <xsl:value-of select="count($c:output)"/>

  <!--need to create directories to get started; first determine full paths-->
  <xsl:variable name="c:directories" as="xsd:string*">
    <xsl:for-each select="$c:output">
      <xsl:sequence select="c:getPath(.)"/>
    </xsl:for-each>
  </xsl:variable>
  
  <!--next build up any needed subdirectories in a piecemail fashion-->
  <xsl:for-each select="distinct-values($c:directories)">
    <xsl:variable name="c:steps" select="tokenize(.,'/')[normalize-space(.)]"/>
    <xsl:for-each select="$c:steps">
      <xsl:variable name="c:thisPos" select="position()"/>
      <xsl:for-each select="
                         string-join($c:steps[position()&lt;=$c:thisPos],'/')">

if [ ! -d "svg/<xsl:value-of select="."/>" ]; then mkdir "svg/<xsl:value-of
                                                             select="."/>" ; fi 
if [ ! -d "png/<xsl:value-of select="."/>" ]; then mkdir "png/<xsl:value-of
                                                             select="."/>" ; fi 
if [ ! -d "pdf/<xsl:value-of select="."/>" ]; then mkdir "pdf/<xsl:value-of
                                                             select="."/>" ; fi
        
      </xsl:for-each>
    </xsl:for-each>
  </xsl:for-each>
  
  <!--create the README files for each directory-->
  <xsl:for-each select="$c:output/ancestor-or-self::*[c:isAdirectory(.)]">
    <xsl:variable name="c:directory"
              select="tokenize(@inkscape:label,'\s+')[normalize-space(.)][1]"/>
    <xsl:variable name="c:content"
    select="translate(substring-after(@inkscape:label,$c:directory),'''','')"/>
    <xsl:variable name="c:content" select="replace($c:content,'^\s+','')"/>
    
echo >svg/<xsl:value-of select="c:getPath(.)"/>README.txt '<xsl:value-of select="
  $c:content"/>'
echo >png/<xsl:value-of select="c:getPath(.)"/>README.txt '<xsl:value-of select="
  $c:content"/>'
echo >pdf/<xsl:value-of select="c:getPath(.)"/>README.txt '<xsl:value-of select="
  $c:content"/>'
  </xsl:for-each>
  
  <!--now invoke Inkscape with the script put aside for the SVG file-->
  <xsl:for-each select="$c:output">
    <xsl:variable name="c:path" select="c:getPath(.)"/>
    <xsl:variable name="c:id" select="tokenize(@inkscape:label,'\s+')[1]"/>
echo "<xsl:value-of select="concat($c:path,$c:id)"/>" - remaining: <xsl:text/>
    <xsl:value-of select="last()-position()"/>
inkscape "<xsl:value-of select='concat($path2svg,$c:path,$c:id,$name-suffix,
        ".svg""",
        " --actions-file=""",(: --batch-process slows things down a lot!:)
        $path2svg,$c:path,$c:id,$name-suffix,".svg.txt""&#xa;")'/>
  </xsl:for-each>
</xsl:template>
  
<!--========================================================================-->
<xs:doc>
  <xs:title>Walking around the various layers</xs:title>
</xs:doc>

<xs:template>
  <para>Prevalidate and report problems in building, checking for loops</para>
  <xs:param name="c:layer">
    <para>The layer making the references</para>
  </xs:param>
  <xs:param name="c:pastLayers">
    <para>A history of layers to prevent infinite loops and visibility</para>
  </xs:param>
</xs:template>
<xsl:template name="c:checkReferencedLayers">
  <xsl:param name="c:layer" as="element(g)" required="yes"/>
  <xsl:param name="c:pastLayers" as="element(g)*"/>
  <xsl:variable name="c:labelTokens" 
      select="c:disambiguateTokens(tokenize($c:layer/@inkscape:label,'\s+'))"/>
  <!--the output layer uses the given name-->
    <xsl:for-each select="reverse($c:labelTokens[position()>2])">
      <!--tease out the authored reference before it was disambiguated-->
      <xsl:variable name="c:disambiguated"
                    select="replace(.,'^#','')"/>
      <xsl:variable name="c:ref"
                    select="replace(.,'^#?(.+?)(____\d+)?$','$1')"/>
      <xsl:choose>
        <xsl:when test="some $c:past in $c:pastLayers
                        satisfies $c:past is $c:layer">
          <!--this is an infinite loop-->
          <xsl:value-of>
            <xsl:text>An infinite loop detected with:&#xa;</xsl:text>
            <xsl:for-each select="$c:pastLayers">
              <xsl:value-of select="string-join($c:pastLayers/c:labelPath(.),
                                                '; ')"/>
            </xsl:for-each>
          </xsl:value-of>
        </xsl:when>
        <xsl:when test="count(key('c:assemble',$c:ref,$c:top))>1">
          <!--something is amiss-->
          <xsl:value-of>
         <xsl:text>Multiple definitions for the assembly reference: </xsl:text>
            <xsl:value-of select="$c:ref"/>
          </xsl:value-of>
        </xsl:when>
        <xsl:when test="exists(key('c:assemble',$c:ref,$c:top))">
          <xsl:call-template name="c:checkReferencedLayers">
            <xsl:with-param name="c:layer"
                            select="key('c:assemble',$c:ref,$c:top)"/>
            <xsl:with-param name="c:pastLayers"
                            select="$c:pastLayers,$c:layer"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="empty(key('c:build',$c:ref,$c:top))">
          <!--something is amiss-->
          <xsl:value-of>
            <xsl:text>Missing a definition for the reference: </xsl:text>
            <xsl:value-of select="$c:ref"/>
            <xsl:text> at </xsl:text>
            <xsl:value-of select="c:labelPath($c:layer)"/>
          </xsl:value-of>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
</xsl:template>

<xs:template>
  <para>Recursively copy in referenced groups, assuming pre-checked</para>
  <xs:param name="c:layer">
    <para>The layer making the references</para>
  </xs:param>
</xs:template>
<xsl:template name="c:addReferencedLayers">
  <xsl:param name="c:layer" as="element(g)" required="yes"/>
  <xsl:variable name="c:labelTokens" 
      select="c:disambiguateTokens(tokenize($c:layer/@inkscape:label,'\s+'))"/>
  <!--the output layer uses the given name-->
    <xsl:for-each select="reverse($c:labelTokens[position()>2])">
      <!--tease out the authored reference before it was disambiguated-->
      <xsl:variable name="c:disambiguated"
                    select="replace(.,'^#','')"/>
      <xsl:variable name="c:ref"
                    select="replace(.,'^#?(.+?)(____\d+)?$','$1')"/>
      <!--label group as disambiguated, but populate the group as authored-->
      <g inkscape:label="{$c:disambiguated}" id="{$c:disambiguated}">
        <xsl:choose>
          <xsl:when test="exists(key('c:assemble',$c:ref,$c:top))">
            <xsl:call-template name="c:addReferencedLayers">
              <xsl:with-param name="c:layer"
                              select="key('c:assemble',$c:ref,$c:top)"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:for-each select="key('c:build',$c:ref,$c:top)">
              <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:attribute name="style"
                               select="concat('display:inline;',
                                       replace(@style,'display:[^;]+;?',''))"/>
                <xsl:apply-templates/>
              </xsl:copy>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </g>
    </xsl:for-each>
</xsl:template>

<xs:function>
  <para>Disambiguate a string of token values ahead of a colon</para>
  <xs:param name="c:inputs">
    <para>The set of tokens to be disambiguated</para>
  </xs:param>
</xs:function>
<xsl:function name="c:disambiguateTokens" as="xsd:string*">
  <xsl:param name="c:inputs" as="xsd:string*"/>
  
  <xsl:for-each select="$c:inputs">
    <xsl:variable name="c:disambiguatePosition" select="position()"/>
    <xsl:choose>
      <xsl:when test=". = $c:inputs[position() &lt; $c:disambiguatePosition]">
        <!--this is a duplicate, so disambiguate-->
        <xsl:sequence select="concat(.,'____',
                       count($c:inputs[position() &lt; $c:disambiguatePosition]
                                      [. = current()]) + 1)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
</xsl:function>

<!--========================================================================-->
<xs:doc>
  <xs:title>Document manipulation</xs:title>
</xs:doc>

<xs:template>
  <para>
    Convert cut-colour lines to cut-width, but only when creating burn, not
    when reviewing content
  </para>
  <xs:param name="c:review">
    <para>Indication that a review copy is being created</para>
  </xs:param>
</xs:template>
<xsl:template match="@style[contains(.,concat('stroke:#',$cut-colour))]">
  <xsl:param name="c:review" as="xsd:boolean" tunnel="yes" select="false()"/>
  <xsl:choose>
    <xsl:when test="$c:review">
      <xsl:copy/><!--preserve thickness for review purposes-->
    </xsl:when>
    <xsl:otherwise>
      <xsl:attribute name="style"
      select="replace(.,'stroke-width:[^;]*;?',
                  concat('stroke-width:',c:lengthInDefault($cut-width),';'))"/>
    </xsl:otherwise>
  </xsl:choose>  
</xsl:template>

<xs:template>
  <para>
    The identity template is used to copy all nodes not already being handled
    by other template rules.
  </para>
</xs:template>
<xsl:template match="@*|node()" mode="#all">
  <xsl:copy>
    <xsl:apply-templates mode="#current" select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<!--========================================================================-->
<xs:doc>
  <xs:title>Utility functions and arithmetic</xs:title>
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
  <xsl:param name="c:context" as="element()"/>
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
            <xsl:sequence select="math:sqrt( ($c:a * $c:d) - ($c:b * $c:c) )"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:matching-substring>
    </xsl:analyze-string>
  </xsl:variable>
  
  <xsl:sequence select="c:product($c:factors)"/>
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

</xsl:stylesheet>
