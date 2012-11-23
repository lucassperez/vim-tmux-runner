" Function: s:initVariable() function {{{2
" This function is used to initialise a given variable to a given value. The
" variable is only initialised if it does not exist prior
"
" Args:
" var: the name of the var to be initialised
" value: the value to initialise var to
"
" Returns:
" 1 if the var is set, 0 otherwise
function! s:InitVariable(var, value)
    if !exists(a:var)
        let escaped_value = substitute(a:value, "'", "''", "g")
        exec 'let ' . a:var . ' = ' . "'" . escaped_value . "'"
        return 1
    endif
    return 0
endfunction

function! s:InitializeVariables()
    call s:InitVariable("g:VtrPercentage", 20)
    call s:InitVariable("g:VtrOrientation", "v")
endfunction
call s:InitializeVariables()

function! s:OpenRunnerPane()
    let s:vim_pane = s:ActiveTmuxPaneNumber()
    let cmd = join(["split-window -p", g:VtrPercentage, "-".g:VtrOrientation])
    call s:SendTmuxCommand(cmd)
    let s:runner_pane = s:ActiveTmuxPaneNumber()
    call s:FocusVimPane()
endfunction

function! s:KillRunnerPane()
    let targeted_cmd = s:TargetedTmuxCommand("kill-pane", s:runner_pane)
    call s:SendTmuxCommand(targeted_cmd)
    unlet s:runner_pane
endfunction

function! s:ActiveTmuxPaneNumber()
    for pane_title in s:TmuxPanes()
        if pane_title =~ '\(active\)'
            return pane_title[0]
        endif
    endfor
endfunction

function! s:TmuxPanes()
    let panes = s:SendTmuxCommand("list-panes")
    return split(panes, '\n')
endfunction

function! s:FocusTmuxPane(pane_number)
    let targeted_cmd = s:TargetedTmuxCommand("select-pane", a:pane_number)
    call s:SendTmuxCommand(targeted_cmd)
endfunction

function! s:FocusRunnerPane()
    call s:FocusTmuxPane(s:runner_pane)
endfunction

function! s:SendTmuxCommand(command)
    let prefixed_command = "tmux " . a:command
    return system(prefixed_command)
endfunction

function! s:TargetedTmuxCommand(command, target_pane)
    return a:command . " -t " . a:target_pane
endfunction

function! s:SendEnterSequence()
    let targeted_cmd = s:TargetedTmuxCommand("send-keys", s:runner_pane)
    let enter_sequence = targeted_cmd . " Enter"
    call s:SendTmuxCommand(enter_sequence)
endfunction

function! s:SendClearSequence()
    let targeted_cmd = s:TargetedTmuxCommand("send-keys", s:runner_pane)
    let enter_sequence = targeted_cmd . " clear"
    call s:SendTmuxCommand(enter_sequence)
    call s:SendEnterSequence()
    sleep 50m
endfunction

function! s:FocusVimPane()
    call s:FocusTmuxPane(s:vim_pane)
endfunction

function! s:TempWindowNumber()
    return split(s:SendTmuxCommand("list-windows"), '\n')[-1][0]
endfunction

function! s:BreakRunnerPaneToTempWindow()
    let targeted_cmd = s:TargetedTmuxCommand("break-pane", s:runner_pane)
    let full_command = join([targeted_cmd, "-d"])
    call s:SendTmuxCommand(full_command)
    return s:TempWindowNumber()
endfunction

function! s:ToggleOrientationVariable()
    let g:VtrOrientation = (g:VtrOrientation == "v" ? "h" : "v")
endfunction

function! s:RotateRunner()
    let temp_window = s:BreakRunnerPaneToTempWindow()
    call s:ToggleOrientationVariable()
    let join_cmd = join(["join-pane", "-s", ":".temp_window.".0", "-p", g:VtrPercentage, "-".g:VtrOrientation])
    echom join_cmd
    call s:SendTmuxCommand(join_cmd)
    call s:FocusVimPane()
endfunction

function! s:SendCommandToRunner()
    echohl String
    let user_command = shellescape(input("Command to run: "))
    let targeted_cmd = s:TargetedTmuxCommand("send-keys", s:runner_pane)
    let full_command = join([targeted_cmd, user_command])
    call s:SendClearSequence()
    call s:SendTmuxCommand(full_command)
    call s:SendEnterSequence()
endfunction

command! VTROpenRunner :call s:OpenRunnerPane()
command! VTRKillRunner :call s:KillRunnerPane()
command! VTRFocusRunnerPane :call s:FocusRunnerPane()
command! VTRSendCommandToRunner :call s:SendCommandToRunner()
command! VTRRotateRunner :call s:RotateRunner()
nmap ,rr :VTRRotateRunner<cr>
nmap ,sc :VTRSendCommandToRunner<cr>
nmap ,or :VTROpenRunner<cr>
nmap ,kr :VTRKillRunner<cr>
nmap ,fr :VTRFocusRunnerPane<cr>
