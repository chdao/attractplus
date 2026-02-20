//////////////////////////////////////////////////
//
// Attract-Mode Frontend - Enhanced intro layout
//
// Based on original intro script, updated by Chris Van Graas
//
///////////////////////////////////////////////////

// Signal MarqueeDisplay that frontend has started (runs before plugins load)
local _cfg = FeConfigDirectory;
// Workaround: path_expand("[config]") and some configs can leave literal "[config]" in path
local _idx = _cfg.find("[config]");
if (_idx >= 0) _cfg = _cfg.slice(0, _idx) + _cfg.slice(_idx + 8);
if (_cfg.len() > 0) {
	local _ps = (_cfg.find("\\") >= 0) ? "\\" : "/";
	local _lead = (_cfg.slice(-1) == "/" || _cfg.slice(-1) == "\\") ? "" : _ps;
	local _dir = _cfg + _lead + "plugins" + _ps + "MarqueeDisplay";
	local _out = _dir + _ps;
	local _json = "{\"marquee_path\":null,\"game\":\"intro\",\"title\":\"intro\",\"state\":\"idle\"}";
	try {
		if (!fe.path_test(_dir, PathTest.IsDirectory))
			system("mkdir \"" + _dir + "\"");
		local _f = file(_out + "current.json", "w");
		local _b = blob(_json.len());
		for (local i = 0; i < _json.len(); i++) _b.writen(_json[i], 'b');
		_f.writeblob(_b);
		print("[intro] Wrote current.json to " + _out + "current.json (video=intro)\n");
	} catch (e) {
		print("[intro] Could not write current.json: " + e + "\n");
	}
}

class UserConfig
{
    </ label="Play intro", help="Toggle playback of intro video when Attract-Mode starts", options="Yes,No", order=1 />
    play_intro = "Yes";

    </ label="Detect aspect ratio", help="Toggle detection of aspect ratio (if disabled, default video will play)", options="Yes,No", order=2 />
    detect_aspect = "Yes";

    </ label="Default video", help="Default video to play at startup. Used if aspect ratio detection failed or disabled", order=4 />
    video_default = "intro.mp4"

    </ label="16:9 video", help="Video to play at startup when 16:9 aspect ratio is detected", order=5 />
    video_16x9 = "intro.mp4"

    </ label="4:3 video", help="Video to play at startup when 4:3 aspect ratio is detected", order=6 />
    video_4x3 = "intro_4x3.mp4"

    </ label="9:16 video", help="Video to play at startup when 9:16 aspect ratio is detected", order=7 />
    video_9x16 = "intro_9x16.mp4"

    </ label="3:4 video", help="Video to play at startup when 3:4 aspect ratio is detected", order=8 />
    video_3x4 = "intro_3x4.mp4"
}

// any signal will cause intro mode to exit
function exit()
{
    fe.signal("select");
}

local config = fe.get_config();

local layout_width = null;
local layout_height = null;
local layout_aspect = "default";
local vid = null;
local Aspect = [ "16x9", "4x3", "9x16", "3x4" ];
local exit_intro = false;

layout_width = fe.layout.width
layout_height = fe.layout.height

switch (config["play_intro"])
{
    case "No":
        exit_intro = true;
    case "Yes":
    default:
        if (config["detect_aspect"] == "Yes")
        {
            local _layout_ar = layout_width / layout_height.tofloat();
            local _best_ar = 0.0;
            foreach (_ratio in Aspect)
            {
                local _x = split(_ratio, "x");
                local _try_ar = _x[0].tofloat()/_x[1].tofloat();

                if (!(_best_ar != 0.0 && fabs(_layout_ar - _best_ar) < fabs(_layout_ar - _try_ar)))
                {
                    _best_ar = _try_ar;
                    layout_aspect = _ratio;
                }
            }
        }

        vid = fe.add_image(config["video_" + layout_aspect], 0, 0, layout_width, layout_height);
        if (vid.file_name.len() == 0 && layout_aspect != "default")
        {
            vid.file_name = config["video_default"];
        }

        if (vid.file_name.len() == 0)
        {
            exit_intro = true;
        }
        fe.add_ticks_callback("intro_tick");
        break;
}

function intro_tick(ttime)
{
    // check if the video has stopped yet
    //
    if (exit_intro == true) exit();
    if (vid.video_playing == false) exit();
    return false;
}
