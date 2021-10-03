#!/bin/sh

#------------------------------------------#
# notification patch for upgrade (3.0 -> 4.0) #
#------------------------------------------#

# Macro
PATH=/bin:/usr/bin:/sbin:/usr/sbin

DB_DIR=/opt/dbspace
DB_NOTIFICATION=$DB_DIR/.notification.db

sqlite3 $DB_NOTIFICATION << EOF

DROP TABLE IF EXISTS notification_setting_temp;
CREATE TABLE notification_setting_temp (
	uid INTEGER,
	package_name TEXT NOT NULL,
	app_id TEXT NOT NULL,
	allow_to_notify INTEGER DEFAULT 1,
	do_not_disturb_except INTEGER DEFAULT 0,
	visibility_class INTEGER DEFAULT 0,
	pop_up_notification INTEGER DEFAULT 1,
	lock_screen_content_level INTEGER DEFAULT 0,
	app_disabled INTEGER DEFAULT 0,
	UNIQUE (uid, package_name, app_id)
);
INSERT INTO notification_setting_temp (uid, package_name, app_id, allow_to_notify, do_not_disturb_except, visibility_class, pop_up_notification, lock_screen_content_level, app_disabled) \
SELECT uid, package_name, appid, allow_to_notify, do_not_disturb_except, visibility_class, pop_up_notification, lock_screen_content_level, app_disabled FROM notification_setting;
DROP TABLE notification_setting;
ALTER TABLE notification_setting_temp RENAME TO notification_setting;


DROP TABLE IF EXISTS noti_list_temp;
CREATE TABLE noti_list_temp (
	type INTEGER NOT NULL,
	layout INTEGER NOT NULL default 0,
	pkg_id TEXT NOT NULL,
	caller_app_id TEXT NOT NULL,
	launch_app_id TEXT,
	app_label TEXT,
	image_path TEXT,
	priv_image_path TEXT,
	group_id INTEGER default 0,
	internal_group_id INTEGER default 0,
	priv_id INTEGER PRIMARY KEY AUTOINCREMENT,
	title_key TEXT,
	b_text TEXT,
	b_key TEXT,
	tag TEXT,
	b_format_args TEXT,
	num_format_args INTEGER default 0,
	text_domain TEXT,
	text_dir TEXT,
	time INTEGER default 0,
	insert_time INTEGER default 0,
	args TEXT,
	group_args TEXT,
	b_execute_option TEXT,
	b_service_responding TEXT,
	b_service_single_launch TEXT,
	b_service_multi_launch TEXT,
	b_event_handler_click_on_button_1 TEXT,
	b_event_handler_click_on_button_2 TEXT,
	b_event_handler_click_on_button_3 TEXT,
	b_event_handler_click_on_button_4 TEXT,
	b_event_handler_click_on_button_5 TEXT,
	b_event_handler_click_on_button_6 TEXT,
	b_event_handler_click_on_icon TEXT,
	b_event_handler_click_on_thumbnail TEXT,
	b_event_handler_click_on_text_input_button TEXT,
	sound_type INTEGER default 0,
	sound_path TEXT,
	priv_sound_path TEXT,
	vibration_type INTEGER default 0,
	vibration_path TEXT,
	priv_vibration_path TEXT,
	led_operation INTEGER default 0,
	led_argb INTEGER default 0,
	led_on_ms INTEGER default -1,
	led_off_ms INTEGER default -1,
	flags_for_property INTEGER default 0,
	flag_simmode INTEGER default 0,
	display_applist INTEGER,
	progress_size DOUBLE default 0,
	progress_percentage DOUBLE default 0,
	ongoing_flag INTEGER default 0,
	ongoing_value_type INTEGER default 0,
	ongoing_current INTEGER default 0,
	ongoing_duration INTEGER default 0,
	auto_remove INTEGER default 1,
	default_button_index INTEGER default 0,
	hide_timeout INTEGER default 0,
	delete_timeout INTEGER default 0,
	text_input_max_length INTEGER default 0,
	event_flag INTEGER default 0,
	extension_image_size INTEGER default 0,
	uid INTEGER
);
INSERT INTO noti_list_temp (type, layout, caller_app_id, launch_app_id, image_path, group_id, internal_group_id, priv_id, title_key, b_text, b_key, tag, b_format_args, num_format_args, text_domain, text_dir, time, insert_time, args, group_args, b_execute_option, b_service_responding, b_service_single_launch, b_service_multi_launch, b_event_handler_click_on_button_1, b_event_handler_click_on_button_2, b_event_handler_click_on_button_3, b_event_handler_click_on_button_4, b_event_handler_click_on_button_5, b_event_handler_click_on_button_6, b_event_handler_click_on_icon, b_event_handler_click_on_thumbnail, b_event_handler_click_on_text_input_button, sound_type, sound_path, vibration_type, vibration_path, led_operation, led_argb, led_on_ms, led_off_ms, flags_for_property, flag_simmode, display_applist, progress_size, progress_percentage, ongoing_flag, ongoing_value_type, ongoing_current, ongoing_duration, auto_remove, default_button_index, hide_timeout, text_input_max_length, event_flag, uid, pkg_id) \
SELECT type, layout, caller_pkgname, launch_pkgname, image_path, group_id, internal_group_id, priv_id, title_key, b_text, b_key, tag, b_format_args, num_format_args, text_domain, text_dir, time, insert_time, args, group_args, b_execute_option, b_service_responding, b_service_single_launch, b_service_multi_launch, b_event_handler_click_on_button_1, b_event_handler_click_on_button_2, b_event_handler_click_on_button_3, b_event_handler_click_on_button_4, b_event_handler_click_on_button_5, b_event_handler_click_on_button_6, b_event_handler_click_on_icon, b_event_handler_click_on_thumbnail, b_event_handler_click_on_text_input_button, sound_type, sound_path, vibration_type, vibration_path, led_operation, led_argb, led_on_ms, led_off_ms, flags_for_property, flag_simmode, display_applist, progress_size, progress_percentage, ongoing_flag, ongoing_value_type, ongoing_current, ongoing_duration, auto_remove, default_button_index, timeout, text_input_max_length, event_flag, nl.uid, COALESCE(package_name, caller_pkgname) FROM noti_list nl LEFT OUTER JOIN notification_setting as ns ON nl.caller_pkgname=ns.app_id;
DROP TABLE noti_list;
ALTER TABLE noti_list_temp RENAME TO noti_list;


DROP TABLE IF EXISTS noti_group_data_temp;
CREATE TABLE noti_group_data_temp (
	caller_app_id TEXT NOT NULL,
	group_id INTEGER default 0,
	badge INTEGER default 0,
	title TEXT,
	content TEXT,
	loc_title TEXT,
	loc_content TEXT,
	count_display_title INTEGER,
	count_display_content INTEGER,
	rowid INTEGER PRIMARY KEY AUTOINCREMENT,
	UNIQUE (caller_app_id, group_id)
);
INSERT INTO noti_group_data_temp (caller_app_id, group_id, badge, title, content, loc_title, loc_content, count_display_title, count_display_content, rowid) \
SELECT caller_pkgname, group_id, badge, title, content, loc_title, loc_content, count_display_title, count_display_content, rowid FROM noti_group_data;
DROP TABLE noti_group_data;
ALTER TABLE noti_group_data_temp RENAME TO noti_group_data;


DROP TABLE IF EXISTS ongoing_list_temp;
CREATE TABLE ongoing_list_temp (
	caller_app_id TEXT NOT NULL,
	launch_app_id TEXT,
	icon_path TEXT,
	group_id INTEGER default 0,
	internal_group_id INTEGER default 0,
	priv_id INTERGER NOT NULL,
	title TEXT,
	content TEXT,
	default_content TEXT,
	loc_title TEXT,
	loc_content TEXT,
	loc_default_content TEXT,
	text_domain TEXT,
	text_dir TEXT,
	args TEXT,
	group_args TEXT,
	flag INTEGER default 0,
	progress_size DOUBLE default 0,
	progress_percentage DOUBLE default 0,
	rowid INTEGER PRIMARY KEY AUTOINCREMENT,
	UNIQUE (caller_app_id, priv_id)
);
INSERT INTO ongoing_list_temp (caller_app_id, launch_app_id, icon_path, group_id, internal_group_id, priv_id, title, content, default_content, loc_title, loc_content, loc_default_content, text_domain, text_dir, args, group_args, flag, progress_size, progress_percentage, rowid) \
SELECT caller_pkgname, launch_pkgname, icon_path, group_id, internal_group_id, priv_id, title, content, default_content, loc_title, loc_content, loc_default_content, text_domain, text_dir, args, group_args, flag, progress_size, progress_percentage, rowid FROM ongoing_list;
DROP TABLE ongoing_list;
ALTER TABLE ongoing_list_temp RENAME TO ongoing_list;


DROP TABLE IF EXISTS noti_template_temp;
CREATE TABLE noti_template_temp (
	type INTEGER NOT NULL,
	layout INTEGER NOT NULL default 0,
	pkg_id TEXT NOT NULL,
	caller_app_id TEXT NOT NULL,
	launch_app_id TEXT,
	app_label TEXT,
	image_path TEXT,
	priv_image_path TEXT,
	group_id INTEGER default 0,
	internal_group_id INTEGER default 0,
	priv_id INTEGER PRIMARY KEY AUTOINCREMENT,
	title_key TEXT,
	b_text TEXT,
	b_key TEXT,
	tag TEXT,
	b_format_args TEXT,
	num_format_args INTEGER default 0,
	text_domain TEXT,
	text_dir TEXT,
	time INTEGER default 0,
	insert_time INTEGER default 0,
	args TEXT,
	group_args TEXT,
	b_execute_option TEXT,
	b_service_responding TEXT,
	b_service_single_launch TEXT,
	b_service_multi_launch TEXT,
	b_event_handler_click_on_button_1 TEXT,
	b_event_handler_click_on_button_2 TEXT,
	b_event_handler_click_on_button_3 TEXT,
	b_event_handler_click_on_button_4 TEXT,
	b_event_handler_click_on_button_5 TEXT,
	b_event_handler_click_on_button_6 TEXT,
	b_event_handler_click_on_icon TEXT,
	b_event_handler_click_on_thumbnail TEXT,
	b_event_handler_click_on_text_input_button TEXT,
	sound_type INTEGER default 0,
	sound_path TEXT,
	priv_sound_path TEXT,
	vibration_type INTEGER default 0,
	vibration_path TEXT,
	priv_vibration_path TEXT,
	led_operation INTEGER default 0,
	led_argb INTEGER default 0,
	led_on_ms INTEGER default -1,
	led_off_ms INTEGER default -1,
	flags_for_property INTEGER default 0,
	flag_simmode INTEGER default 0,
	display_applist INTEGER,
	progress_size DOUBLE default 0,
	progress_percentage DOUBLE default 0,
	ongoing_flag INTEGER default 0,
	ongoing_value_type INTEGER default 0,
	ongoing_current INTEGER default 0,
	ongoing_duration INTEGER default 0,
	auto_remove INTEGER default 1,
	default_button_index INTEGER default 0,
	hide_timeout INTEGER default 0,
	delete_timeout INTEGER default 0,
	text_input_max_length INTEGER default 0,
	event_flag INTEGER default 0,
	extension_image_size INTEGER default 0,
	uid INTEGER,
	template_name TEXT,
	UNIQUE (caller_app_id, template_name)
);
INSERT INTO noti_template_temp (type, layout, caller_app_id, launch_app_id, image_path, group_id, internal_group_id, priv_id, title_key, b_text, b_key, tag, b_format_args, num_format_args, text_domain, text_dir, time, insert_time, args, group_args, b_execute_option, b_service_responding, b_service_single_launch, b_service_multi_launch, b_event_handler_click_on_button_1, b_event_handler_click_on_button_2, b_event_handler_click_on_button_3, b_event_handler_click_on_button_4, b_event_handler_click_on_button_5, b_event_handler_click_on_button_6, b_event_handler_click_on_icon, b_event_handler_click_on_thumbnail, b_event_handler_click_on_text_input_button, sound_type, sound_path, vibration_type, vibration_path, led_operation, led_argb, led_on_ms, led_off_ms, flags_for_property, flag_simmode, display_applist, progress_size, progress_percentage, ongoing_flag, ongoing_value_type, ongoing_current, ongoing_duration, auto_remove, default_button_index, hide_timeout, text_input_max_length, event_flag, uid, template_name, pkg_id) \
SELECT type, layout, caller_pkgname, launch_pkgname, image_path, group_id, internal_group_id, priv_id, title_key, b_text, b_key, tag, b_format_args, num_format_args, text_domain, text_dir, time, insert_time, args, group_args, b_execute_option, b_service_responding, b_service_single_launch, b_service_multi_launch, b_event_handler_click_on_button_1, b_event_handler_click_on_button_2, b_event_handler_click_on_button_3, b_event_handler_click_on_button_4, b_event_handler_click_on_button_5, b_event_handler_click_on_button_6, b_event_handler_click_on_icon, b_event_handler_click_on_thumbnail, b_event_handler_click_on_text_input_button, sound_type, sound_path, vibration_type, vibration_path, led_operation, led_argb, led_on_ms, led_off_ms, flags_for_property, flag_simmode, display_applist, progress_size, progress_percentage, ongoing_flag, ongoing_value_type, ongoing_current, ongoing_duration, auto_remove, default_button_index, timeout, text_input_max_length, event_flag, nl.uid, template_name, COALESCE(package_name, caller_pkgname) FROM noti_template as nl LEFT OUTER JOIN notification_setting as ns ON nl.caller_pkgname=ns.app_id;
DROP TABLE noti_template;
ALTER TABLE noti_template_temp RENAME TO noti_template;
EOF

chown app_fw:app_fw $DB_NOTIFICATION
chown app_fw:app_fw $DB_NOTIFICATION-journal

chsmack -a System $DB_NOTIFICATION
chsmack -a System $DB_NOTIFICATION-journal
