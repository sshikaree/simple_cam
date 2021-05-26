namespace SimpleCam {

enum CamTreeColumns {
    GROUP,
    NAME,
    URL,
    IS_ACTIVE,
    WIDGET_OBJECT,
    N_COLUMNS;

    public string to_string() {
        switch(this) {
            case GROUP:
                return _("Group");
            case NAME:
                return _("Name");
            case URL:
                return "URL";
            case IS_ACTIVE:
                return _("Is active");
            default:
                return "";
        }
    }
}

[GtkTemplate (ui = "/ui/main_window.ui")]
public class MainWindow : Gtk.ApplicationWindow {
    [GtkChild] protected Gtk.HeaderBar  header_bar;
    [GtkChild] internal  Gtk.Button     add_cam_btn;
    //  [GtkChild] internal  Gtk.MenuButton menu_btn;
    [GtkChild] protected Gtk.Statusbar  status_bar;
    [GtkChild] protected Gtk.Paned      paned;
    [GtkChild] protected Gtk.TreeView   cam_tree_view;
    [GtkChild] protected Gtk.Grid       cam_grid;

    private CamTreeStore cam_tree_store;
    protected unowned Gtk.TreeSelection selection;

    private int grid_row = -1;
    private int grid_column = -1;


    public MainWindow(Gtk.Application app) {
        base.application = app;
        add_cam_btn.clicked.connect(on_add_cam_clicked);

        //  cam_tree_store = new Gtk.TreeStore(
        //      CamTreeColumns.N_COLUMNS, Type.STRING, Type.STRING, Type.STRING, Type.BOOLEAN, Type.OBJECT
        //  );
        cam_tree_store = new CamTreeStore();
        
        cam_tree_view.set_model(cam_tree_store);
        cam_tree_view.headers_visible = true;

        /* Add Group column */
        var group_renderer = new Gtk.CellRendererText();
        var group_column = new Gtk.TreeViewColumn.with_attributes(
            CamTreeColumns.GROUP.to_string(), group_renderer, "text", CamTreeColumns.GROUP, null
        );
        cam_tree_view.append_column(group_column);

        /* Add Name column */
        var name_renderer = new Gtk.CellRendererText();
        var name_column = new Gtk.TreeViewColumn.with_attributes(
            CamTreeColumns.NAME.to_string(), name_renderer, "text", CamTreeColumns.NAME, null
        );
        cam_tree_view.append_column(name_column);

        /* Add Active column */
        var active_renderer = new Gtk.CellRendererToggle();
        active_renderer.toggled.connect(on_active_toggled);
        var active_column = new Gtk.TreeViewColumn.with_attributes(
            CamTreeColumns.IS_ACTIVE.to_string(), active_renderer, "active", CamTreeColumns.IS_ACTIVE, null
        );
        cam_tree_view.append_column(active_column);
        //  unowned Gtk.TreeSelection sel = cam_tree_view.get_selection();
        selection = cam_tree_view.get_selection();
        selection.set_mode(Gtk.SelectionMode.MULTIPLE);

        // Disable group selection
        selection.set_select_function((sel, model, path) => {
           return path.get_depth() != 1;
        });

        // Right click TreeView context menu
        cam_tree_view.button_release_event.connect((event) => {
            // get selected path
            unowned Gtk.TreeModel model;
            GLib.List<Gtk.TreePath> paths = selection.get_selected_rows(out model);
            foreach (var path in paths) {
                message(path.to_string());
            }
            if (event.button == Gdk.BUTTON_SECONDARY && paths != null) {
                var menu = new Gtk.Menu();
                // delete cam item
                Gtk.MenuItem delete_item = new Gtk.MenuItem.with_label(_("Delete camera"));
                delete_item.activate.connect(delete_cam);
                menu.add(delete_item);

                // edit cam item
                Gtk.MenuItem edit_item = new Gtk.MenuItem.with_label(_("Edit camera"));
                edit_item.activate.connect(edit_cam);
                menu.add(edit_item);

                menu.show_all();
                menu.popup_at_pointer(null);
            }

            return false;
        });
    }

    /* Show adding camera dialog */
    private void on_add_cam_clicked() {
        var dialog = new AddCamUrlDialog(cam_tree_store);
        var res = dialog.run();
        if (res != Gtk.ResponseType.OK) {
            dialog.destroy();
            return;
        }
        
        /* 
        *   Find matching Group and add camera.
        *   cam_tree_store.foreach() can be used here.
        *   Example:
        *   cam_tree_store.foreach((model, path, iter) => {
        *       message(path.to_string());
        *       return false; // true for top level only
        *   });
        */
        Gtk.TreeIter group_iter;
        for (
            bool valid = cam_tree_store.get_iter_first(out group_iter);
            valid == true;
            valid = cam_tree_store.iter_next(ref group_iter)
        ) {
            string group_name;
            cam_tree_store.get(group_iter, CamTreeColumns.GROUP, out group_name, -1);
            if (group_name == dialog.cam_group) {
                Gtk.TreeIter cam_iter;
                cam_tree_store.append(out cam_iter, group_iter);
                cam_tree_store.set(
                    cam_iter,
                    CamTreeColumns.NAME, dialog.cam_name,
                    CamTreeColumns.URL, dialog.url,
                    -1
                );
                break;
            }
        }
        cam_tree_store.save_data();

        dialog.destroy();
    }

    /* TODO
    *   - Implement whole group selection change (or disable group toggle)
    */
    private void on_active_toggled(string path) {
        Gtk.TreeIter iter;
        var tree_path = new Gtk.TreePath.from_string(path);
        //  message("Path :%s  Toggled!", path);
        //  message("Path depth: %d", tree_path.get_depth());
        GLib.Value selected;
        cam_tree_store.get_iter_from_string(out iter, path);
        cam_tree_store.get_value(iter, CamTreeColumns.IS_ACTIVE, out selected);
        selected.set_boolean(!selected.get_boolean());
        cam_tree_store.set_value(iter, CamTreeColumns.IS_ACTIVE, selected);
        // Return if Group was toggled
        if (tree_path.get_depth() < 2) {
            return;
        }

        /* CamWidget section */
        if (selected.get_boolean() == true) {
            // create widget
            GLib.Value url;
            cam_tree_store.get_value(iter, CamTreeColumns.URL, out url);
            var cam_widget = new CamWidget(url.get_string());
            cam_tree_store.set_value(iter, CamTreeColumns.WIDGET_OBJECT, cam_widget);
            grid_row++;
            cam_grid.attach(cam_widget, grid_column, grid_row, 1, 1);
            url.unset();
        } else {
            // destroy widget
            GLib.Value cam_widget_value;
            cam_tree_store.get_value(iter, CamTreeColumns.WIDGET_OBJECT, out cam_widget_value);
            var cam_widget = cam_widget_value.get_object() as CamWidget;
            if (cam_widget == null) {
                message("cam_widget is null");
                return;
            }
            cam_widget.pipeline.set_state(Gst.State.NULL);
            cam_widget.destroy();
            grid_row--;
            cam_widget_value.unset();
        }
    }

    // Removes camera from cam_tree_store
    private void delete_cam() {
        // TODO:
        // 1. Check cam_tree_store.save_data() for an error
        unowned Gtk.TreeModel model;
        GLib.List<Gtk.TreePath> paths = selection.get_selected_rows(out model);
        foreach (var path in paths) {
            Gtk.TreeIter iter;
            var ok = model.get_iter_from_string(out iter, path.to_string());
            GLib.Value cam_name, cam_url;
            if (ok == true) {
                // get cam name
                cam_tree_store.get_value(iter, CamTreeColumns.NAME, out cam_name);
                cam_tree_store.get_value(iter, CamTreeColumns.URL, out cam_url);
                debug("Delete cam " + cam_name.get_string() + " with path " + path.to_string());
                Gtk.MessageDialog dialog = new Gtk.MessageDialog(
                    this,
                    Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                    Gtk.MessageType.WARNING,
                    Gtk.ButtonsType.OK_CANCEL,
                    _("Delete camera %s?"),
                    cam_name.get_string()
                );
                dialog.format_secondary_text("Camera URL: %s", cam_url.get_string());
                var res = dialog.run();
                if (res == Gtk.ResponseType.OK) {
                    cam_tree_store.remove(ref iter);
                    cam_tree_store.save_data();
                }
                dialog.close();       
            }
        }
    }

    // Show edit camera dialog
    private void edit_cam() {
        message("Edit cam");
        // TODO:
        // 1. Open edit dialog
        // 2. Save changes to data file
        // 3. Reload data file
    }
    
    
}




}