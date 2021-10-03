<?xml version="1.0" standalone="yes"?>

<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron">

	<sch:pattern name="No '*' anywhere">
		<!-- don't place any more rules here as probably they won't fire -->
		<sch:rule context="*[@*]">
			<!-- here we use report, not assert, as report with @*='*' works as "if any attribute matches", while assert @*!='*' works as "if all attributes match" -->
			<sch:report test="@* = '*'">Rules using "*" are not allowed.</sch:report>
		</sch:rule>
	</sch:pattern>

	<sch:pattern name="Default denials not specified (send_destination, own, own_prefix)">
		<sch:rule context="allow[@send_destination]">
			<sch:let name="dest_name" value="@send_destination"/>
			<sch:assert test="//policy[@context='default']/deny[@send_destination = $dest_name]">For each allow send_destination you must add a deny send_destination in default context.</sch:assert>
			<sch:assert test="//policy[@context='default']/deny[@own = $dest_name]">For each allow send_destination you must add a deny own in default context.</sch:assert>
		</sch:rule>
		<sch:rule context="allow[@own]">
			<sch:let name="dest_name" value="@own"/>
			<sch:assert test="//policy[@context='default']/deny[@own = $dest_name]">For each allow own you must add a deny own in default context.</sch:assert>
		</sch:rule>
		<sch:rule context="allow[@own_prefix]">
			<sch:let name="dest_name" value="@own_prefix"/>
			<sch:assert test="//policy[@context='default']/deny[@own_prefix = $dest_name]">For each allow own_prefix you must add a deny own_prefix in default context.</sch:assert>
		</sch:rule>
	</sch:pattern>

	<sch:pattern name="Unconstrained allow in default context (or mandatory)">
		<!-- policy[@context] means that it applies to both default and mandatory contexts -->
		<sch:rule context="policy[@context]/allow[@send_type='method_call']">
			<sch:assert test="@send_destination">Unconstrained allows are not allowed in context default and context mandatory: missing send_destination, but send_type="method_call" is present.</sch:assert>
			<sch:assert test="@send_interface">Unconstrained allows are not allowed in context default and context mandatory: missing send_interface, but send_type="method_call" is present.</sch:assert>
		</sch:rule>
		<sch:rule context="policy[@context]/allow[@send_path]">
			<sch:assert test="@send_destination">Unconstrained allows are not allowed in context default and context mandatory: missing send_destination, but send_path is present.</sch:assert>
		</sch:rule>
		<sch:rule context="policy[@context]/allow[@receive_type='method_call']">
			<sch:assert test="@receive_sender">Unconstrained allows are not allowed in context default and context mandatory: missing receive_sender, but receive_type="method_call" is present.</sch:assert>
			<sch:assert test="@receive_interface">Unconstrained allows are not allowed in context default and context mandatory: missing receive_interface, but receive_type="method_call" is present.</sch:assert>
		</sch:rule>
		<sch:rule context="policy[@context]/allow[@receive_path]">
			<sch:assert test="@receive_sender">Unconstrained allows are not allowed in context default and context mandatory: missing receive_sender, but receive_path is present.</sch:assert>
		</sch:rule>
		<!-- user and group contexts need at least send_destination -->
		<sch:rule context="policy[@user]/allow[@send_type='method_call'] | policy[@group]/allow[@send_type='method_call']">
			<sch:assert test="@send_destination">Unconstrained allows are not allowed in user or group context: missing send_destination, but send_type="method_call" is present.</sch:assert>
		</sch:rule>
		<sch:rule context="policy[@user]/allow[@send_path] | policy[@group]/allow[@send_path]">
			<sch:assert test="@send_destination">Unconstrained allows are not allowed in user or group context: missing send_destination, but send_path is present.</sch:assert>
		</sch:rule>
		<sch:rule context="policy[@user]/allow[@receive_type='method_call'] | policy[@group]/allow[@receive_type='method_call']">
			<sch:assert test="@receive_sender">Unconstrained allows are not allowed in user or group context: missing receive_sender, but receive_type="method_call" is present.</sch:assert>
		</sch:rule>
		<sch:rule context="policy[@user]/allow[@receive_path] | policy[@group]/allow[@receive_path]">
			<sch:assert test="@receive_sender">Unconstrained allows are not allowed in user or group context: missing receive_sender, but receive_path is present.</sch:assert>
		</sch:rule>
	</sch:pattern>
	<!-- additional rule -->
	<sch:pattern name="Don't depend on global deny-own and deny-method-call">
		<!-- TODO maybe we can guess somehow the exact dbus name? -->
		<sch:rule context="busconfig">
			<sch:assert test="policy[@context='default']">You must provide a policy context-default section.</sch:assert>
		</sch:rule>
		<sch:rule context="policy[@context='default']">
			<sch:assert test="deny[@own]">You must define a 'deny own="yourname"' rule in context-default policy to avoid depending on a global 'deny own="*"'.</sch:assert>
			<sch:assert test="deny[@send_destination]">You must define a 'deny send_destination="yourname"' rule in context-default policy to avoid depending on a global deny.</sch:assert>

			<!-- TODO what constraints should be made on send_destination and receive sender? -->
		</sch:rule>
	</sch:pattern>
	<!-- -->


	<!-- TODO ineffective (masked) rules, TBD -->

	<!-- Duplicate rules in different contexts are processed using same.xsl -->

	<sch:pattern name="No empty policies">
		<sch:rule context="policy">
			<sch:report test="not(*)">Empty policy is not allowed.</sch:report>
		</sch:rule>
	</sch:pattern>

	<!-- we have to check Cynara privileges outside Schematron as xslt fails when given a rule with 1500 Cynara privileges (as taken from mobile emulator) -->
	<!--sch:pattern name="Invalid Cynara privilege">
		<sch:rule context="check">
			<sch:assert test="PRIVILEGES_TEST">Privilege does not exist.</sch:assert>
		</sch:rule>
	</sch:pattern-->

	<sch:pattern name="No at_console rules">
		<sch:rule context="policy[@at_console]/*">
			<!-- this will fail on many upstream packages which still have at_console rules despite at_console being deprecated since a long time -->
			<!-- use true() so that we print an error for every allow/deny, and not only for every policy at_console once -->
			<sch:report test="true()">You mustn't define rules in at_console contexts (it's deprecated on dbus-daemon systems and not supported on kdbus systems).</sch:report>
		</sch:rule>
	</sch:pattern>

	<sch:pattern name="Invalid user">
		<sch:rule context="*[@user]">
			<sch:assert test="@user = '*' or USERS_TEST">User does not exist.</sch:assert>
		</sch:rule>
	</sch:pattern>

	<sch:pattern name="Invalid group">
		<sch:rule context="*[@group]">
			<sch:assert test="@group = '*' or GROUPS_TEST">Group does not exist.</sch:assert>
		</sch:rule>
	</sch:pattern>

	<sch:pattern name="No SMACK-context policies">
		<sch:rule context="policy[@context]">
			<!-- I have no better idea how to check for SMACK labels. Policies must obey the test below anyway. -->
			<sch:report test="@context != 'default' and @context != 'mandatory'">You mustn't use SMACK-context policies, use privileges exclusively.</sch:report>
		</sch:rule>
	</sch:pattern>

	<sch:pattern name="No user/group rules outside policy context=default|mandatory">
		<sch:rule context="policy[@user|@group]/deny[@user|@group] | policy[@user|@group]/allow[@user|@group]">
			<sch:report test="true()">You mustn't allow/deny user/group anywhere except policy context=default|mandatory.</sch:report>
		</sch:rule>
	</sch:pattern>

	<sch:pattern name="No eavesdrop rules">
		<sch:rule context="allow|deny">
			<sch:report test="@eavesdrop">You mustn't use eavesdrop rules as they are a potential security risk.</sch:report>
		</sch:rule>
	</sch:pattern>

	<sch:pattern name="No complex globs">
		<sch:rule context="*[@*]">
			<!-- No ends-with() (xpath 2.0 in general) using xsltproc :( -->
			<sch:report test="string-length(@*) > 1 and substring(@*, string-length(@*)) = '*'">Globs like sth* are not allowed.</sch:report>
		</sch:rule>
	</sch:pattern>

	<sch:pattern name="No send_interface without send_destination">
		<sch:rule context="*[@send_interface]">
			<sch:assert test="@send_destination">You mustn't use send_interface without send_destination</sch:assert>
		</sch:rule>
		<sch:rule context="*[@receive_interface]">
			<sch:assert test="@receive_sender">You mustn't use receive_interface without receive_sender</sch:assert>
		</sch:rule>
	</sch:pattern>

	<sch:pattern name="No send and receive in one rule">
		<sch:rule context="allow|deny">
			<sch:report test="(@send_interface or @send_member or @send_error or @send_broadcast or @send_destination or @send_type or @send_path or @send_requested_reply) and (@receive_interface or @receive_member or @receive_error or @receive_sender or @receive_type or @receive_path or @receive_requsted_reply)">You mustn't use send_ and receive_ attributes in one rule.</sch:report>
		</sch:rule>
	</sch:pattern>




	<!-- additional rule -->
	<sch:pattern name="Not implemented in libdbuspolicy">
		<sch:rule context="allow|deny">
			<sch:report test="@eavesdrop">eavesdrop rules not implemented on kdbus systems.</sch:report>
			<sch:report test="@send_error">send_error rules not implemented on kdbus systems.</sch:report>
			<sch:report test="@receive_error">send_error rules not implemented on kdbus systems.</sch:report>
			<sch:report test="@send_requested_reply">send_requested_reply rules not implemented on kdbus systems.</sch:report>
			<sch:report test="@receive_requested_reply">receive_requested_reply rules not implemented on kdbus systems.</sch:report>
			<sch:report test="@send_broadcast">send_broadcast rules not implemented on kdbus systems.</sch:report>
		</sch:rule>
	</sch:pattern>

</sch:schema>
