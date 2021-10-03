attrs :
{
    bcdUSB = 0x200;
    bDeviceClass = 0x0;
    bDeviceSubClass = 0x0;
    bDeviceProtocol = 0x0;
    bMaxPacketSize0 = 0x40;
    idVendor = 0x1D6B;
    idProduct = 0x104;
    bcdDevice = 0x1;
};
strings = (
    {
        lang = 0x409;
        manufacturer = "Foo Inc.";
        product = "Bar Gadget";
        serialnumber = "0123456789";
    } );
functions :
{
    ffs_instance1 :
    {
        instance = "usb-host-test";
        type = "ffs";
        attrs :
        {
        };
    };
};
configs = (
    {
        id = 1;
        name = "The only one";
        attrs :
        {
            bmAttributes = 0x80;
            bMaxPower = 0x2;
        };
        strings = (
            {
                lang = 0x409;
                configuration = "usb host API test config";
            } );
        functions = (
            {
                name = "some_name_here";
                function = "ffs_instance1";
            });
    } );
