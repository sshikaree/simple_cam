//  extern const string GETTEXT_PACKAGE; 

public static int main(string[] args) {

	Gst.init(ref args);

	var app = new SimpleCam.Application();
	var res = app.run(args);

	Gst.deinit();

	return res;
}

