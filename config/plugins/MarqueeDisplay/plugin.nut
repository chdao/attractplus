///////////////////////////////////////////////////
//
// AttractMode plugin - MarqueeDisplay
// Writes current game name and marquee artwork path to current.json
// for the MarqueeDisplay application (external marquee/secondary display).
//
///////////////////////////////////////////////////

class UserConfig </ help="Sends game name and marquee artwork path to MarqueeDisplay" /> {
	</ label="MarqueeDisplay folder", help="Optional. Leave empty to use plugin folder (when MarqueeDisplay is in plugins/MarqueeDisplay/). Override if installed elsewhere.", order=1 />
	output_path="";

	</ label="Artwork type", help="Artwork label to send (marquee, snap, flyer, wheel, fanart). Use 'marquee' for cabinet marquees.", order=2 />
	artwork_label="marquee";
}

local config = fe.get_config();
print("[MarqueeDisplay] Plugin init, output_path=" + config["output_path"].tostring() + "\n");

// Strip literal "[config]" from path (workaround for path_expand/config issues)
function strip_config_token(p) {
	local i = p.find("[config]");
	return (i >= 0) ? (p.slice(0, i) + p.slice(i + 8)) : p;
}
// Plugin directory: fe.script_dir when loaded as plugin, else config/plugins/MarqueeDisplay/
local plugin_dir = fe.script_dir;
if (plugin_dir.len() == 0 || !fe.path_test(plugin_dir + "plugin.nut", PathTest.IsFile)) {
	plugin_dir = strip_config_token(FeConfigDirectory);
	if (plugin_dir.len() > 0) {
		plugin_dir = plugin_dir + (plugin_dir.slice(-1) == "/" || plugin_dir.slice(-1) == "\\" ? "" : "/") + "plugins/MarqueeDisplay/";
	}
}

// Append a line to plugin debug log - tries plugin dir first (most reliable), then config
function plugin_log(msg) {
	try {
		foreach (logPath in [plugin_dir, strip_config_token(FeConfigDirectory)]) {
			if (logPath == null || logPath.len() == 0) continue;
			local sep = (logPath.slice(-1) == "/" || logPath.slice(-1) == "\\" ? "" : "/");
			local f = logPath + sep + "marquee-plugin-debug.txt";
			system("cmd /c echo [MarqueeDisplay] " + msg + " >> \"" + f + "\"");
			return;
		}
	} catch (e) {}
}
plugin_log("Plugin loaded");

// JSON-escape a string for use in JSON
function json_escape(s) {
	if (s == null || s == "") return "";
	local out = "";
	for (local i = 0; i < s.len(); i++) {
		local c = s.slice(i, i + 1);
		if (c == "\\") out += "\\\\";
		else if (c == "\"") out += "\\\"";
		else if (c == "\n") out += "\\n";
		else if (c == "\r") out += "\\r";
		else if (c == "\t") out += "\\t";
		else out += c;
	}
	return out;
}

// Write current.json directly (no MarqueeWrite.exe needed)
function write_json(outputPath, marqueePath, game, title) {
	local state = (marqueePath != null && marqueePath.len() > 0) ? "browsing" : "idle";
	local mp = (marqueePath != null && marqueePath.len() > 0) ? ("\"" + json_escape(marqueePath) + "\"") : "null";
	local line = "{\"marquee_path\":" + mp + ",\"game\":\"" + json_escape(game) + "\",\"title\":\"" + json_escape(title) + "\",\"state\":\"" + state + "\"}";
	try {
		local dir = outputPath.slice(0, -1);  // remove trailing /
		if (dir.len() > 0 && !fe.path_test(dir, PathTest.IsDirectory))
			system("mkdir \"" + dir + "\"");
		local f = file(outputPath + "current.json", "w");
		local b = blob(line.len());
		for (local i = 0; i < line.len(); i++) b.writen(line[i], 'b');
		f.writeblob(b);
	} catch (e) {
		plugin_log("write failed: " + e);
	}
}

function write_current() {
	plugin_log("write_current called");
	local outputPath = config["output_path"].tostring();
	if (outputPath.len() == 0) {
		outputPath = plugin_dir;
	} else {
		outputPath = strip_config_token(fe.path_expand(outputPath));
	}
	if (outputPath.len() == 0) {
		plugin_log("skip: could not determine output path");
		return;
	}
	if (outputPath.slice(-1) != "/" && outputPath.slice(-1) != "\\")
		outputPath += "/";

	// Get artwork paths (Art.FullList returns semicolon-separated when multiple configured)
	local artPaths = fe.get_art(config["artwork_label"], 0, 0, Art.FullList);
	local game = fe.game_info(Info.Name);
	local title = fe.game_info(Info.Title);
	if (title.len() == 0) title = game;

	// Extract directory paths from file paths; deduplicate (skip archive paths with |)
	local dirs = {};
	if (artPaths.len() > 0) {
		local parts = split(artPaths, ";");
		foreach (p in parts) {
			local s = strip(p);
			if (s.len() == 0 || s.find("|") >= 0) continue;  // skip archives
			local last = -1;
			for (local i = 0; i < s.len(); i++) {
				local c = s.slice(i, i + 1);
				if (c == "/" || c == "\\") last = i;
			}
			if (last >= 0) {
				local dir = s.slice(0, last);
				if (dir.len() > 0 && !dirs.rawin(dir)) dirs[dir] <- true;
			}
		}
	}

	// Build semicolon-separated directory list
	local marqueePath = "";
	foreach (dir, _ in dirs) {
		if (marqueePath.len() > 0) marqueePath += ";";
		marqueePath += dir;
	}

	plugin_log("game=" + game);
	write_json(outputPath, marqueePath, game, title);
}

// Debounce: wait for scroll to settle before sending (avoids flooding when scrolling fast)
local lastIndex = -1;
local lastDisplay = -1;
local pendingIdx = -1;
local pendingDisp = -1;
local debounceTicks = 0;
const DEBOUNCE_FRAMES = 3;  // ~50ms at 60fps

function on_tick(ttime) {
	local idx = fe.list.index;
	local disp = fe.list.display_index;
	// Initialize on first run (lastIndex -1 would cause endless reset)
	if (lastIndex < 0) {
		lastIndex = idx;
		lastDisplay = disp;
	}
	// Reset debounce only when selection changed from what we're waiting for
	if (idx != pendingIdx || disp != pendingDisp) {
		pendingIdx = idx;
		pendingDisp = disp;
		debounceTicks = 0;
	}
	if (pendingIdx >= 0 && (pendingIdx != lastIndex || pendingDisp != lastDisplay)) {
		debounceTicks++;
		if (debounceTicks >= DEBOUNCE_FRAMES) {
			lastIndex = pendingIdx;
			lastDisplay = pendingDisp;
			pendingIdx = -1;
			write_current();
		}
	}
}

function on_transition(ttype, var, transition_time) {
	if (ttype == Transition.StartLayout || ttype == Transition.FromGame || ttype == Transition.ToNewList) {
		lastIndex = fe.list.index;
		lastDisplay = fe.list.display_index;
		pendingIdx = -1;
		write_current();
	}
	return false;
}

fe.add_transition_callback("on_transition");
fe.add_ticks_callback("on_tick");
print("[MarqueeDisplay] Plugin loaded - check marquee-plugin-debug.txt in AttractMode config folder for diagnostics\n");

// Register plugin (required for AttractMode to load it; no menu UI)
class MarqueeDisplayPlugin {
	constructor() {}
}
fe.plugin["MarqueeDisplay"] <- MarqueeDisplayPlugin();
