local msg = require "mp.msg"
local utils = require "mp.utils"
local options = require "mp.options"

local startpos = nil
local endpos = nil
local copy_audio = false
local copy_subs = false
local previewing = false
local o = {
    target_dir = "~",
    vcodec = "libx264",
    acodec = "pcm_s16le",
    vf = "scale=800:-2",
    opts = "-pix_fmt yuv420p -b:v 500K -maxrate 700K -bufsize 700K",
    ext = "mp4",
    command_template = [[
        ffmpeg -v warning -y -stats
        -ss $startpos -i '$in' -t $duration
        -c:v $vcodec -c:a $acodec $audio $subs
        -vf $vf $opts '$out.$ext'
    ]],
}
options.read_options(o)

function timestamp(duration)
    local hours = duration / 3600
    local minutes = duration % 3600 / 60
    local seconds = duration % 60
    return string.format("%02d:%02d:%02.03f", hours, minutes, seconds)
end

function osd(str)
    return mp.osd_message(str, 3)
end

function log(str)
    local logpath = string.format("%s/%s",
        o.target_dir:gsub("~", os.getenv("HOME")),
        "mpv_slicing.log")
    f = io.open(logpath, "a")
    f:write(string.format("# %s\n%s\n",
        os.date("%Y-%m-%d %H:%M:%S"),
        str))
    f:close()
end

function escape(str)
    return str:gsub("\\", "\\\\"):gsub("'", "'\\''")
end

function trim(str)
    return str:gsub("^%s+", ""):gsub("%s+$", "")
end

function get_csp()
    local csp = mp.get_property("colormatrix")
    if csp == "bt.601" then return "bt601"
        elseif csp == "bt.709" then return "bt709"
        elseif csp == "smpte-240m" then return "smpte240m"
        else
            local err = "Unknown colorspace: " .. csp
            osd(err)
            error(err)
    end
end

function get_outname(startpos, endpos)
    local name = mp.get_property("filename")
    local dotidx = name:reverse():find(".", 1, true)
    if dotidx then name = name:sub(1, -dotidx-1) end
    name = name:gsub(" ", "_")
    name = name .. string.format(".%s-%s", timestamp(startpos), timestamp(endpos))
    return name
end

function selected()
    if startpos == nil or endpos == nil then
        osd("No fragment selected")
        return false
    end
    return true
end

function cut()
    if not selected() then return end

    local cmd = trim(o.command_template:gsub("%s+", " "))
    local inpath = escape(utils.join_path(
        utils.getcwd(),
        mp.get_property("stream-path")))
    -- TODO: Windows?
    local outpath = escape(string.format("%s/%s",
        o.target_dir:gsub("~", os.getenv("HOME")),
        get_outname(startpos, endpos)))

    cmd = cmd:gsub("$startpos", startpos)
    cmd = cmd:gsub("$duration", endpos - startpos)
    cmd = cmd:gsub("$vcodec", o.vcodec)
    cmd = cmd:gsub("$acodec", o.acodec)
    cmd = cmd:gsub("$audio", copy_audio and "" or "-an")
    cmd = cmd:gsub("$subs", copy_subs and "" or "-sn")
    cmd = cmd:gsub("$vf", o.vf)
    cmd = cmd:gsub("$matrix", get_csp())
    cmd = cmd:gsub("$opts", o.opts)
    -- Beware that input/out filename may contain replacing patterns.
    cmd = cmd:gsub("$ext", o.ext)
    cmd = cmd:gsub("$out", outpath)
    cmd = cmd:gsub("$in", inpath, 1)

    msg.info(cmd)
    log(cmd)
    os.execute(cmd)
    osd("%s.%s saved", outpath, o.ext)
end

function toggle_mark()
    local pos = mp.get_property_number("time-pos")

    if endpos then
        startpos = nil
        endpos = nil
        osd("Cancelled fragment selection")
        return 
    end

    if startpos then
        endpos = pos
        if startpos > endpos then
            startpos, endpos = endpos, startpos
        end
        if startpos == endpos then
            osd("Cut fragment is empty")
            endpos = nil
        else
            osd(string.format("Fragment selected: %s - %s",
                timestamp(startpos),
                timestamp(endpos)))
        end
    else
        startpos = pos
        osd(string.format("Marked %s as start position", timestamp(pos)))
    end
end

function toggle_audio()
    copy_audio = not copy_audio
    osd("Audio capturing is " .. (copy_audio and "enabled" or "disabled"))
end

function preview()
    if previewing then
        previewing = false
    else
        if not selected() then return end
        previewing = true
        loop_preview()
    end
end

function loop_preview() 
    if not previewing then return end
    if not selected() then return end

    osd('Previewing... press again to stop')
	mp.set_property_native("pause", false)
	mp.set_property_native("time-pos", startpos)
    mp.add_timeout(endpos - startpos, loop_preview)
end

mp.add_key_binding(nil, "gipher_mark", toggle_mark)
mp.add_key_binding(nil, "gipher_audio", toggle_audio)
mp.add_key_binding(nil, "gipher_preview", preview)
mp.add_key_binding(nil, "gipher_encode", cut)
