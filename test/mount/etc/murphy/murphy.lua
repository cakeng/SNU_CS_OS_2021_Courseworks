m = murphy.get()

-- load the dlog plugin
m:try_load_plugin('dlog')

-- load the console plugin
m:try_load_plugin('console')

-- load the dbus plugin
if m:plugin_exists('dbus') then
    m:load_plugin('dbus')
end

-- load the native resource plugin
if m:plugin_exists('resource-native') then
    m:load_plugin('resource-native')
    m:info("native resource plugin loaded")
else
    m:info("No native resource plugin found...")
end

-- load the dbus resource plugin
m:try_load_plugin('resource-dbus', {
    dbus_bus = "system",
    dbus_service = "org.Murphy",
    dbus_track = true,
    default_zone = "driver",
    default_class = "implicit"
})

-- load the domain control plugin
if m:plugin_exists('domain-control') then
    m:load_plugin('domain-control')
else
    m:info("No domain-control plugin found...")
end

if m:plugin_exists('glib') then
    m:load_plugin('glib')
else
    m:info("No glib plugin found...")
end

-- define application classes
application_class {
    name     = "interrupt",
    priority = 99,
    modal    = false,
    share    = false,
    order    = "fifo"
}

application_class {
    name     = "media",
    priority = 10,
    modal    = false,
    share    = false,
    order    = "lifo"
}

-- define zone attributes
zone.attributes {
    type = {mdb.string, "common", "rw"},
    location = {mdb.string, "anywhere", "rw"}
}

-- define zones
zone {
     name = "driver",
     attributes = {
         type = "common",
         location = "front-left"
     }
}

-- define resource classes
resource.class {
     name = "video_overlay",
     shareable = false,
     sync_release = true
}

resource.class {
     name = "video_decoder",
     shareable = false,
     sync_release = true
}

resource.class {
     name = "video_encoder",
     shareable = false,
     sync_release = true
}

resource.class {
     name = "camera",
     shareable = false,
     sync_release = true
}
