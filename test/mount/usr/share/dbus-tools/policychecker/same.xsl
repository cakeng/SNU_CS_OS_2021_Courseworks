<?xml version="1.0" standalone="yes"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exslt="http://exslt.org/common">
	<xsl:output method="text" encoding="utf-8"/>
	<xsl:strip-space elements="*"/>

	<!-- https://stackoverflow.com/questions/38053426/how-to-find-the-difference-between-two-xml-in-xslt -->
	<xsl:template name="attribute-value-mismatch">
		<xsl:param name="attributes1" />
		<xsl:param name="attributes2" />
		<attribute-match>
			<xsl:if test="(count($attributes1) != count($attributes2))">
				<attribute />
			</xsl:if>
			<xsl:if test="(count($attributes1) = count($attributes2))">
				<xsl:for-each select="$attributes1">
					<xsl:variable name="attribute1" select="."/>
					<xsl:variable name="result">
						<attroot>
							<xsl:for-each select="$attributes2">
								<xsl:if test="name(.) = name($attribute1/.)">
									<xsl:if test="not(. = $attribute1/.)">
										<not-matched-name/>
									</xsl:if>
								</xsl:if>
								<xsl:if test="name(.) != name($attribute1/.)">
									<not-matched-name/>
								</xsl:if>
							</xsl:for-each>
						</attroot>
					</xsl:variable>
					<xsl:if test="count(exslt:node-set($result)//not-matched-name) = count(exslt:node-set($attributes2))">
						<attribute />
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</attribute-match>
	</xsl:template>

	<xsl:template name="find-duplicates">
		<xsl:param name="curr_rule"/>
		<xsl:param name="other_rules"/>
		<xsl:variable name="same_rules">
			<xsl:for-each select="$other_rules">
				<xsl:if test="local-name()=local-name($curr_rule)">
					<xsl:variable name="attribute-mismatch">
						<xsl:call-template name="attribute-value-mismatch">
							<xsl:with-param name="attributes1" select="./@*"/>
							<xsl:with-param name="attributes2" select="$curr_rule/@*"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:value-of select="count(exslt:node-set($attribute-mismatch)//attribute)" />
					<xsl:if test="count(exslt:node-set($attribute-mismatch)//attribute) = 0"><node/></xsl:if>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="count(exslt:node-set($same_rules)//node)">FAILED(assert) at /busconfig/policy[<xsl:value-of select="1 + count(parent::*/preceding-sibling::policy)"/>]/<xsl:value-of select="local-name($curr_rule)"/>[<xsl:value-of select="1 + count(preceding-sibling::*[local-name()=local-name(current())])"/>] : Duplicate rule.
</xsl:if>
	</xsl:template>

	<!-- user vs context -->
	<xsl:template match="//policy[@user]/*">
		<!-- we cannot compare with group policies as we don't know which group rules will be applied to the current user (TODO? supply a user->groups mapping )-->
		<xsl:call-template name="find-duplicates">
			<xsl:with-param name="curr_rule" select="."/>
			<xsl:with-param name="other_rules" select="//policy[@context]/*"/>
		</xsl:call-template>
	</xsl:template>

	<!-- group vs context -->
	<xsl:template match="//policy[@group]/*">
		<xsl:call-template name="find-duplicates">
			<xsl:with-param name="curr_rule" select="."/>
			<xsl:with-param name="other_rules" select="//policy[@context]/*"/>
		</xsl:call-template>
	</xsl:template>

	<!-- context='default' vs context='mandatory' -->
	<xsl:template match="//policy[@context='default']/*">
		<xsl:call-template name="find-duplicates">
			<xsl:with-param name="curr_rule" select="."/>
			<xsl:with-param name="other_rules" select="//policy[@context='mandatory']/*"/>
		</xsl:call-template>
	</xsl:template>

</xsl:stylesheet>
