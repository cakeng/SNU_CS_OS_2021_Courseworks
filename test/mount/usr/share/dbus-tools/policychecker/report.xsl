<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:svrl="http://purl.oclc.org/dsdl/svrl">
	<xsl:output method="text" encoding="utf-8"/>
	<xsl:strip-space elements="*"/>

	<xsl:template match="svrl:failed-assert">
FAILED(assert)<!-- "<xsl:if test="string-length(@test) &lt;= 20"><xsl:value-of select="@test"/></xsl:if>" --> at <xsl:value-of select="@location"/> : <xsl:value-of select="svrl:text"/>
	</xsl:template>

	<xsl:template match="svrl:successful-report">
FAILED(report)<!-- "<xsl:if test="string-length(@test) &lt;= 20"><xsl:value-of select="@test"/></xsl:if>" --> at <xsl:value-of select="@location"/> : <xsl:value-of select="svrl:text"/>
	</xsl:template>

</xsl:stylesheet>
