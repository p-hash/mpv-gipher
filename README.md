`gipher.lua` is a Lua script for mpv to make Telegram-friendly mp4-"gifs" out of video fragments.

#### Usage

Make sure you have FFmpeg and libx264 installed. Put `gipher.lua` to `~/.config/mpv/scripts/` or `~/.mpv/scripts/` directory to autoload the script or load it manually with `--script=<path>`.

Script provides 4 keybindings:
+ gipher\_mark -- marks start and end position
+ gipher\_audio -- toggles audio capturing (default off)
+ gipher\_preview -- starts looping over selected fragment
+ gipher\_encode -- runs ffmpeg and does the job

You have to manually set these keybindings in your `input.conf` file. I suggest adding following lines to the end of your `input.conf`:

```
alt+c script-binding gipher/gipher_mark
alt+a script-binding gipher/gipher_audio
alt+v script-binding gipher/gipher_preview
alt+x script-binding gipher/gipher_encode
```

You can change output folder and all parameters of the output video by editing your `scripts/gipher.conf`, see [gipher.lua](https://github.com/p-hash/mpv-gipher/blob/master/gipher.lua) for details. 

#### Source

Based on [mpv_slicing](https://github.com/Kagami/mpv_slicing)

#### License

mpv-gipher - Cut mp4-"gifs" with mpv

Written in 2018 by PHash <p-hash@yandex.ru>

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.

You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
