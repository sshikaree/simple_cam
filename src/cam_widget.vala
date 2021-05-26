namespace SimpleCam {

public class CamWidget : Gtk.Box {
    public   Gst.Element	video_src {get; set;}
	public   Gst.Element	video_sink {get; set;}
	public   Gst.Pipeline	pipeline {get; set;}
	internal Gst.Bus	    bus;
	
    private  Gtk.Widget     _video_area;
	public   Gtk.Widget		video_area {
        get {return _video_area;}
    }

	public string	        stream_uri {get; set;}
	private Gst.Element		rtph264depay; 

	public CamWidget(string stream_uri) {
        orientation = Gtk.Orientation.VERTICAL;
        spacing = 2;
		/*
		* Gstreamer setup
		*/
        this.stream_uri = stream_uri;
		video_src = Gst.ElementFactory.make("rtspsrc", "source");
		assert (video_src != null);
		video_src["location"] = stream_uri;
		video_src.pad_added.connect(on_pad_added);
		rtph264depay = Gst.ElementFactory.make("rtph264depay", "rtph264depay");
		assert (rtph264depay != null);
		var h264parse = Gst.ElementFactory.make("h264parse", "h264parse");
		assert (h264parse != null);
		//  var mp4mux = Gst.ElementFactory.make("mp4mux", "mp4mux");
		//  assert(mp4mux != null);
		var avdec_h264 = Gst.ElementFactory.make("avdec_h264", "avdec_h264");
		assert (avdec_h264 != null);
		var videoconvert = Gst.ElementFactory.make("videoconvert", "videoconvert");
		assert (videoconvert != null);
		video_sink = Gst.ElementFactory.make("gtksink", "gtksink");
		assert (video_sink != null);

		pipeline = new Gst.Pipeline("pipeline");
		assert (pipeline != null);
		//  var caps1 = new Gst.Caps.simple(
		//  	"application/x-rtp",
		//  	"media", Type.STRING, "video",
		//  	"encoding-name", Type.STRING, "H264"
		//  );
		var caps2 = new Gst.Caps.simple(
			"video/x-h264",
			//  "width", GLib.Type.INT, 640,
			//  "height", GLib.Type.INT, 480,
			"format", GLib.Type.STRING, "byte-stream"
		);
		var caps3 = new Gst.Caps.simple(
			"video/x-raw",
			//  "width", GLib.Type.INT, 640,
			//  "height", GLib.Type.INT, 480,
			"format", GLib.Type.STRING, "BGRA"
		);
		pipeline.add_many(video_src, rtph264depay, h264parse, avdec_h264, videoconvert, video_sink);

		/* video_src will be linked dynamically */
		
		if (rtph264depay.link_filtered(h264parse, caps2) != true ) {
			error("Link failed");
		}
		if (h264parse.link(avdec_h264) != true ) {
			error("Link failed");
		}
		if (avdec_h264.link(videoconvert) != true ) {
			error("Link failed");
		}
		if (videoconvert.link_filtered(video_sink, caps3) != true ) {
			error("Link failed");
		}
		video_sink.get("widget", out _video_area);
		assert (_video_area != null);
        this.pack_start(_video_area);

        _video_area.realize.connect(on_realize);
        _video_area.destroy.connect(on_destroy);

		/* BUS setup */
		bus = pipeline.get_bus();
		//  bus.enable_sync_message_emission();
		bus.add_signal_watch();
		bus.message.connect(on_bus_message);

		/*
		*  UI setup
		 */
        show_all();
    
	}

//  //		playbin["uri"] = "https://www.w3schools.com/html/mov_bbb.mp4";

	//  private void on_play() {
	//  	pipeline.set_state(Gst.State.PLAYING);
	//  }

	//  private void on_stop() {
	//  	print("Stream closed\n");
	//  	pipeline.set_state(Gst.State.READY);
	//  }

	private void on_destroy() {
		pipeline.set_state(Gst.State.NULL);
	}

	private void on_realize() {
		pipeline.set_state(Gst.State.PLAYING);
	}

	void on_bus_message(Gst.Message msg) {
		//  print("Got message!\n");
		// Parse message:
		if (msg != null) {
			switch (msg.type) {
			case Gst.MessageType.ERROR:
				GLib.Error err;
				string debug_info;

				msg.parse_error (out err, out debug_info);
				stderr.printf ("Error received from element %s: %s\n", msg.src.name, err.message);
				stderr.printf ("Debugging information: %s\n", (debug_info != null)? debug_info : "none");
				break;

			case Gst.MessageType.EOS:
				print ("End-Of-Stream reached.\n");
				break;

			default:
				//  print(@"$(msg.type)\n");
				break;
			}
		}
	}

	void on_pad_added(Gst.Pad pad) {
  		/* We can now link this pad with the rtsp-decoder sink pad */
		Gst.Pad sinkpad = rtph264depay.get_static_pad("sink");
		pad.link(sinkpad);
	}

}


}