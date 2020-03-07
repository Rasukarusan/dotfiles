" $XDEBUG_REMOTE_PATH, $XDEBUG_LOCAL_PATHは.zshrc.localで設定する
let g:vdebug_options= {
\    "port" : 9001,
\    "timeout" : 20,
\    "on_close" : 'detach',
\    "break_on_open" : 0,
\    "debug_window_level" : 0,
\    "debug_file_level" : 0,
\    "debug_file" : "",
\    'watch_window_style' : 'expanded',
\    'marker_default' : '⬦',
\    'marker_closed_tree' : '▸',
\    'marker_open_tree' : '▾',
\    'sign_breakpoint' : '▷',
\    'sign_current' : '▶',
\    'sign_disabled':'>',
\    'continuous_mode'  : 1,
\    'simplified_status': 1,
\    'layout': 'vertical',
\    "path_maps" : {
\       $XDEBUG_REMOTE_PATH : $XDEBUG_LOCAL_PATH
\    },
\}

let g:vdebug_keymap = {
\    "run" : "<F5>",
\    "run_to_cursor" : "<F9>",
\    "step_over" : "<F2>",
\    "step_into" : "<F3>",
\    "step_out" : "<F4>",
\    "close" : "<F6>",
\    "detach" : "<F7>",
\    "set_breakpoint" : "<F10>",
\    "get_context" : "<F11>",
\    "eval_under_cursor" : "<F12>",
\}
