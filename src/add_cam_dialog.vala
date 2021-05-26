namespace SimpleCam {

[GtkTemplate (ui = "/ui/add_cam_dialog.ui")]
public class AddCamDialog : Gtk.Dialog {
    [GtkChild] private Gtk.Entry ip_entry;
    [GtkChild] private Gtk.Entry port_entry;
    [GtkChild] private Gtk.Entry username_entry;
    [GtkChild] private Gtk.Entry password_entry;
    //  [GtkChild] private Gtk.Entry stream_entry;
    [GtkChild] private Gtk.ComboBox stream_combo;

    public string ip_address {
        get {return ip_entry.text;}
    }
    public string port {
        get {return port_entry.text;}
    }
    public string username {
        get {return username_entry.text;}
    }
    public string password {
        get {return password_entry.text;}
    }
    public int stream_id {
        get {return stream_combo.active;}
    }

    public AddCamDialog() {
        title = "Add new camera";
        destroy_with_parent = true;
        modal = true;

        //  add_button(_("Add"), Gtk.ResponseType.OK);
        //  add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
    }
}




}