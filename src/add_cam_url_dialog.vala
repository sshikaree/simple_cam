namespace SimpleCam {

[GtkTemplate (ui = "/ui/add_cam_url_dialog.ui")]
public class AddCamUrlDialog : Gtk.Dialog {
    [GtkChild] private Gtk.ComboBoxText cam_group_combo;
    private string _cam_group;
    //  [GtkChild] private Gtk.Entry cam_group_entry;
    [GtkChild] private Gtk.Entry cam_name_entry;
    [GtkChild] private Gtk.Entry url_entry;

    public string url {
        get {return url_entry.text;}
    }
    public string cam_name {
        get {return cam_name_entry.text;}
    }
    public string cam_group {
        get {
            _cam_group = cam_group_combo.get_active_text();
            return _cam_group;
        }
    }

    public AddCamUrlDialog(Gtk.TreeStore cam_tree_store) {
        title = "Add new camera";
        destroy_with_parent = true;
        modal = true;
        //  cam_tree_store.get_iter_from_string(out iter, "0");
        //  cam_group_combo.append_text("Backyard");

        /* Fill up combo from cam_tree_store Group column */
        Gtk.TreeIter iter;
        for (
            bool valid = cam_tree_store.get_iter_first(out iter);
            valid == true;
            valid = cam_tree_store.iter_next(ref iter)
        ) {
                string group_name;
                cam_tree_store.get(iter, CamTreeColumns.GROUP, out group_name, -1);
                //  message(group_name);
                cam_group_combo.append_text(group_name);
        }
        cam_group_combo.set_active(0);
        //  cam_group_combo.set_model(cam_tree_store);
    }
}




}