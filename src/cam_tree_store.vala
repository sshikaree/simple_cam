namespace SimpleCam {

public class CamTreeStore : Gtk.TreeStore {
    public CamTreeStore() {
        GLib.Type[] column_types = {Type.STRING, Type.STRING, Type.STRING, Type.BOOLEAN, Type.OBJECT};
        set_column_types(column_types);

        load_data();

    }

    public void load_data() {
        var path = GLib.Path.build_filename(
            GLib.Environment.get_user_data_dir(), APPLICATION_NAME, DATA_FILE_NAME
        );

        Xml.Doc* doc = Xml.Parser.parse_file(path);
        if (doc == null) {
            message("Error parsing datafile");
            return;
        }
        Xml.Node* root = doc->get_root_element();
        if (root == null) {
            message("Datafile is empty");
            delete doc;
            return;
        }
        Gtk.TreeIter group_iter = {0};
        Gtk.TreeIter cam_iter;

        // Iterate over groups
        for (Xml.Node* group = root->children; group != null; group = group->next) {
            string current_group = "";
            // Spaces between tags are nodes too, so discard them
            if (group->type != Xml.ElementType.ELEMENT_NODE || group->name != "group") {
                continue;
            }
            for (Xml.Attr* group_prop = group->properties; group_prop != null; group_prop = group_prop->next) {
                string group_prop_name = group_prop->name;
                if (group_prop_name == "name") {
                    current_group = group_prop->children->content;
                    // Append group to the TreeStore
                    this.append(out group_iter, null);
                    this.set(
                        group_iter, 
                        CamTreeColumns.GROUP, current_group,
                        -1
                    );
                    message("Group: %s", current_group);
                }
            }
            // Iterate over cams
            for (Xml.Node* cam = group->children; cam != null; cam = cam->next) {
                // Spaces between tags are nodes too, so discard them
                if (cam->type != Xml.ElementType.ELEMENT_NODE || cam->name != "cam") {
                    continue;
                }
                string cam_name = "";
                string cam_url = "";
                for (Xml.Attr* cam_prop = cam->properties; cam_prop != null; cam_prop = cam_prop->next) {
                    string cam_prop_name = cam_prop->name;
                    switch (cam_prop_name){
                        case "name":
                            cam_name = cam_prop->children->content;
                            message("Cam name %s", cam_name);
                            break;
                        case "url":
                        cam_url = cam_prop->children->content;
                        message("Cam url %s", cam_url);
                            break;
                        default:
                            message("Unknown cam property");
                            break;
                    }
                }
                if (current_group != "") {
                    this.append(out cam_iter, group_iter);
                } else {
                    this.append(out cam_iter, null);
                }
                this.set(
                    cam_iter,
                    CamTreeColumns.NAME, cam_name,
                    CamTreeColumns.URL, cam_url,
                    -1
                );
            }

        }

        delete doc;
    }

    public void save_data() {
        var path = GLib.Path.build_filename(
            GLib.Environment.get_user_data_dir(), APPLICATION_NAME, DATA_FILE_NAME
        );

        Xml.Doc* doc = new Xml.Doc("1.0");
        Xml.Node* root = new Xml.Node(null, "cams");
        doc->set_root_element(root);

        //Iterate over groups
        Gtk.TreeIter group_iter;
        for (
            bool valid = this.get_iter_first(out group_iter);
            valid == true;
            valid = this.iter_next(ref group_iter)
        ) {
                string group_name;
                this.get(group_iter, CamTreeColumns.GROUP, out group_name, -1);
                Xml.Node* group = root->new_child(null, "group");
                group->new_prop("name", group_name);

                // Iterate over cams
                Gtk.TreeIter cam_iter;
                for (
                    bool valid2 = this.iter_children(out cam_iter, group_iter);
                    valid2 == true;
                    valid2 = this.iter_next(ref cam_iter)
                ) {
                    string cam_name;
                    this.get(cam_iter, CamTreeColumns.NAME, out cam_name, -1);
                    string cam_url;
                    this.get(cam_iter, CamTreeColumns.URL, out cam_url, -1);
                    Xml.Node* cam = group->new_child(null, "cam");
                    cam->new_prop("name", cam_name);
                    cam->new_prop("url", cam_url);
                }
        }

        //  string xmlstring;
        //  doc->dump_memory_format(out xmlstring);
        //  message(xmlstring);
        if (doc->save_format_file(path, 1) < 0) {
            message("Error saving data");
        }

        delete doc;
    }



}





}