namespace SimpleCam {

internal const string APPLICATION_NAME = "simple_cam";
internal const string DATA_FILE_NAME = "cams.xml";

public class Application : Gtk.Application {
    public Application() {
        Object(
            application_id: "org.sshikaree.simple_cam",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate() {
        MainWindow main_window = new MainWindow(this);
        main_window.set_default_size(800, 600);
        main_window.show_all();
    }


}


}