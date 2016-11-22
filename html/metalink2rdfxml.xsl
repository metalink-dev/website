<?xml version="1.0" ?> <!-- encoding="UTF-8" --> 

<!-- metalink2rdfxml.xsl

Converts metalinker.org XML files to an RDF representation

This version : 2007-08-10

Status : second pass, should be complete and valid, ready for feedback

Mapping Notes :
    generally if an element is missing, it'll also be left out of the RDF/XML version

    m:origin -> dc:source

    date attributes on elements moved out to equivalent elements - was easier for format conversion
    translated from RFC822 to RFC3339 format (if not correct RFC(2)822 then property left out)
        m:pubdate -> dc:date 
        m:refreshdate -> dcterms:modified 

    m:tags split (on ' ' and/or ','), expressed individually using Tag Ontology

    m:type (on root metalink element) -> m:type
    m:type (on m:url elements) -> individual of type scheme:Scheme
           see http://n2.talis.com/svn/playground/danja/schemas/uri-schemes.rdf
    m:type when used with hash element has been changed into m:md5_hash etc. properties

    m:url -> m:url@rdf:resource

    structure around files/file has been flattened, see code

    pieces rearranged, see code

Contributors :
    Anthony Bryan
    Dan Brickley
    Danny Ayers
-->

<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		xmlns:foaf="http://xmlns.com/foaf/0.1/"
		xmlns:dc="http://purl.org/dc/elements/1.1/"
		xmlns:dcterms="http://purl.org/dc/terms/"
		xmlns:doap="http://usefulinc.com/ns/doap#"
		xmlns:xhtml="http://www.w3.org/1999/xhtml"
		xmlns:tags="http://www.holygoat.co.uk/owl/redwood/0.1/tags/"
		xmlns:scheme="http://purl.org/stuff/uri-schemes" 
		xmlns:m="http://www.metalinker.org/"
		xmlns="http://www.metalinker.org/">

  <xsl:output method="xml" indent="yes" /><!--  encoding="UTF-8" -->

  <xsl:template match="/m:metalink">
    <rdf:RDF>
      <Metalink>

	<xsl:if test="@type">
	  <xsl:attribute name="m:type"><xsl:value-of select="@type"/></xsl:attribute>
	</xsl:if>

	<xsl:if test="@generator">
	  <xsl:attribute name="m:type"><xsl:value-of select="@type"/></xsl:attribute>
	</xsl:if>

	<xsl:if test="@origin">
	  <xsl:attribute name="dc:source"><xsl:value-of select="@origin"/></xsl:attribute>
	</xsl:if>

	<xsl:if test="@pubdate">
	  <xsl:call-template name="date">
	    <xsl:with-param name="name" select="'dc:date'"/>
	    <xsl:with-param name="raw_date" select="@pubdate"/>
	  </xsl:call-template>
	</xsl:if>

	<xsl:if test="@refreshdate">
	  <xsl:call-template name="date">
	    <xsl:with-param name="name" select="'dcterms:modified'"/>
	    <xsl:with-param name="raw_date" select="@refreshdate"/>
	  </xsl:call-template>
	</xsl:if>

	<xsl:apply-templates select="m:publisher"/> 
		
	<xsl:if test="m:description/text()">
	  <dc:description><xsl:value-of select="m:description" /></dc:description>
	</xsl:if>

	<xsl:apply-templates select="m:tags"/>
	<xsl:copy-of select="m:identity" /> 
	<xsl:copy-of select="m:version" /> 

	<m:file> 
	  <xsl:apply-templates select="m:files"/>
	</m:file>
      </Metalink>
    </rdf:RDF>
  </xsl:template>

  <xsl:template match="m:publisher">
    <m:publisher rdf:parseType="Resource">
      <m:name><xsl:value-of select="m:name" /></m:name>
      <m:url>
	<xsl:attribute name="rdf:resource"><xsl:value-of select="m:url" /></xsl:attribute>
      </m:url>
    </m:publisher>
  </xsl:template>
  
  <xsl:template match="m:tags">
<xsl:variable name="space-separated-tags"><xsl:value-of select="translate(text(), ',', ' ')"/></xsl:variable>

		<xsl:call-template name="split-list">
			<xsl:with-param name="list"><xsl:value-of select="$space-separated-tags" /></xsl:with-param>
		</xsl:call-template>
  </xsl:template>  

  
  <xsl:template match="m:files">
    <xsl:for-each select="m:file">
      <m:File  m:name="{@name}">
	<xsl:copy-of select="m:os" />
	<xsl:copy-of select="m:size" />
	<m:verification rdf:parseType="Resource">
	  <xsl:for-each select="m:verification/m:hash">
	    <xsl:element name="m:{@type}_hash"><xsl:value-of select="text()"/></xsl:element>
	  </xsl:for-each>
	  <xsl:for-each select="m:verification/m:pieces">
	    <xsl:call-template name="pieces">
	      <xsl:with-param name="pieces" select="." />
	    </xsl:call-template>
	  </xsl:for-each>
	</m:verification>
	<xsl:apply-templates />
      </m:File>
    </xsl:for-each>
  </xsl:template>    
  
  <xsl:template name="pieces">
    <xsl:param name="pieces" />
    <m:pieces>

  <m:Pieces m:length="{@length}">

    <xsl:for-each select="m:hash">
      <xsl:element name="m:{../@type}">
	<xsl:attribute name="rdf:parseType">Resource</xsl:attribute>
	<m:position><xsl:value-of select="position()"/></m:position>
	<rdf:value><xsl:value-of select="text()" /></rdf:value>
      </xsl:element>
    </xsl:for-each>

  </m:Pieces>

    </m:pieces>
  </xsl:template>

  <xsl:template match="m:resources">

    <xsl:for-each select="m:url">
      <m:url>
	<xsl:attribute name="rdf:resource"><xsl:value-of select="./text()"/></xsl:attribute>
	<xsl:attribute name="scheme:scheme">http://purl.org/stuff/uri-schemes/<xsl:value-of select="@type"/></xsl:attribute>
	<xsl:attribute name="m:location"><xsl:value-of select="@location" /></xsl:attribute>
	<xsl:attribute name="m:preference"><xsl:value-of select="@preference" /></xsl:attribute>
      </m:url>
    </xsl:for-each>

  </xsl:template>

<!-- based on a trick in Michael Kay's XSLT Ref. book -->
<xsl:template name="split-list">
    <xsl:param name="list" />
    <xsl:variable name="newlist" select="concat(normalize-space($list), ' ')" />
    <xsl:variable name="first" select="substring-before($newlist, ' ')" />
    <xsl:variable name="remaining" select="substring-after($newlist, ' ')" />

    <tags:taggedWithTag rdf:parseType="Resource">
      <tags:tagName><xsl:value-of select="$first" /></tags:tagName>
    </tags:taggedWithTag>
    <xsl:if test="$remaining">
        <xsl:call-template name="split-list">
            <xsl:with-param name="list" select="$remaining" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>
  
  <xsl:template name="date"> <!-- derived from mortenf's rss xslt -->
    <xsl:param name="name" select="'dc:date'"/>
    <xsl:param name="raw_date" />
	<xsl:if test="contains($raw_date,',') and string-length(normalize-space(substring-before($raw_date,',')))=3">
		<xsl:variable name="dmyhisz" select="normalize-space(substring-after($raw_date,','))"/>
		<!-- Fetch date of month. -->
		<xsl:if test="contains($dmyhisz,' ') and string-length(substring-before($dmyhisz,' '))&lt;=2">
			<xsl:variable name="d" select="substring-before($dmyhisz,' ')"/>
			<xsl:variable name="myhisz" select="normalize-space(substring-after($dmyhisz,' '))"/>
			<!-- Validate date of month, fetch and translate month name to month number. -->
			<xsl:if test="string-length(translate($d,'0123456789',''))=0 and contains($myhisz,' ') and string-length(substring-before($myhisz,' '))=3">
				<xsl:variable name="m-temp" select="translate(substring-before($myhisz,' '),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')"/>
				<xsl:variable name="yhisz" select="normalize-space(substring-after($myhisz,' '))"/>
				<xsl:variable name="m">
					<xsl:choose>
						<xsl:when test="$m-temp='jan'">
							<xsl:value-of select="'1'"/>
						</xsl:when>
						<xsl:when test="$m-temp='feb'">
							<xsl:value-of select="'2'"/>
						</xsl:when>
						<xsl:when test="$m-temp='mar'">
							<xsl:value-of select="'3'"/>
						</xsl:when>
						<xsl:when test="$m-temp='apr'">
							<xsl:value-of select="'4'"/>
						</xsl:when>
						<xsl:when test="$m-temp='may'">
							<xsl:value-of select="'5'"/>
						</xsl:when>
						<xsl:when test="$m-temp='jun'">
							<xsl:value-of select="'6'"/>
						</xsl:when>
						<xsl:when test="$m-temp='jul'">
							<xsl:value-of select="'7'"/>
						</xsl:when>
						<xsl:when test="$m-temp='aug'">
							<xsl:value-of select="'8'"/>
						</xsl:when>
						<xsl:when test="$m-temp='sep'">
							<xsl:value-of select="'9'"/>
						</xsl:when>
						<xsl:when test="$m-temp='oct'">
							<xsl:value-of select="'10'"/>
						</xsl:when>
						<xsl:when test="$m-temp='nov'">
							<xsl:value-of select="'11'"/>
						</xsl:when>
						<xsl:when test="$m-temp='dec'">
							<xsl:value-of select="'12'"/>
						</xsl:when>
					</xsl:choose>
				</xsl:variable>
				<!-- Validate month, fetch (possibly translating) year. -->
				<xsl:if test="string-length($m)!=0 and contains($yhisz,' ')">
					<xsl:variable name="y-temp" select="substring-before($yhisz,' ')"/>
					<xsl:variable name="hisz" select="normalize-space(substring-after($yhisz,' '))"/>
					<xsl:variable name="y">
						<xsl:choose>
							<xsl:when test="string-length(translate($y-temp,'0123456789',''))=0 and string-length($y-temp)=2 and $y-temp &lt; 70">
								<xsl:value-of select="concat('20',$y-temp)"/>
							</xsl:when>
							<xsl:when test="string-length(translate($y-temp,'0123456789',''))=0 and string-length($y-temp)=2 and $y-temp &gt;= 70">
								<xsl:value-of select="concat('19',$y-temp)"/>
							</xsl:when>
							<xsl:when test="string-length(translate($y-temp,'0123456789',''))=0 and string-length($y-temp)=4">
								<xsl:value-of select="$y-temp"/>
							</xsl:when>
						</xsl:choose>
					</xsl:variable>
					<!-- Validate year, fetch time, fetch and translate (valid) time zone. -->
					<xsl:if test="string-length($y)!=0 and contains($hisz,' ')">
						<xsl:variable name="his" select="substring-before($hisz,' ')"/>
						<xsl:variable name="z" select="normalize-space(substring-after($hisz,' '))"/>
						<xsl:variable name="offset">
							<xsl:choose>
								<xsl:when test="$z='GMT' or $z='+0000'">
									<xsl:value-of select="'Z'"/>
								</xsl:when>
								<xsl:when test="string-length($z)=5 and $z!='-0000' and (substring($z,1,1)='-' or substring($z,1,1)='+') and (substring($z,2,1)='0' or substring($z,2,1)='1') and string-length(translate($z,'0123456789',''))=1">
									<xsl:value-of select="concat(substring($z,1,3),':',substring($z,4,2))"/>
								</xsl:when>
							</xsl:choose>
						</xsl:variable>
						<!-- Validate time and time zone. -->
						<xsl:choose>
							<xsl:when test="string-length($his)=8 and string-length(translate($his,'0123456789',''))=2 and string-length(translate($his,':',''))=6 and string-length($offset)!=0">
								<xsl:element name="{$name}">
									<xsl:value-of select="concat($y,'-',format-number($m,'00'),'-',format-number($d,'00'),'T',$his,$offset)"/>
								</xsl:element>
							</xsl:when>
							<xsl:otherwise>
								<xsl:comment>
									<xsl:value-of select="."/>
								</xsl:comment>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:if>
			</xsl:if>
		</xsl:if>
	</xsl:if>
</xsl:template>

  
  <xsl:template match="text()"/>
</xsl:stylesheet>
