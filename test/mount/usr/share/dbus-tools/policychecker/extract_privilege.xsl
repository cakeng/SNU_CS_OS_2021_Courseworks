<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="text" encoding="utf-8"/>
	<xsl:strip-space elements="*"/>
	<xsl:template match="/">
		<xsl:for-each select="//check">
			<xsl:value-of select="@privilege" />
			<xsl:text>&#xa;</xsl:text>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
