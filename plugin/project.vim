"=============================================================================
" File:        project.vim
" Author:      Aric Blumer (Aric.Blumer@marconi.com)
" Last Change: Thu 18 Oct 2001 01:02:07 PM EDT
" Version:     1.0pre4
"=============================================================================
" See documentation in accompanying help file

if exists('loaded_project') || &cp
  finish
endif
let loaded_project=1

function! s:Project(filename) " <<<
    " Initialization <<<
    if exists("g:proj_running")
        let filename=bufname(g:proj_running)
    else
        if strlen(a:filename) == 0
            " Default project filename
            let filename ='~/.vimprojects'
        else
            let filename = a:filename
        endif
    endif
    if !exists('g:proj_window_width')
        " Default project window width
        let g:proj_window_width=24
    endif
    if !exists('g:proj_window_increment')
        " Project Window width increment
        let g:proj_window_increment=100
    endif
    if !exists('g:proj_flags')
        " Project default flags
        let g:proj_flags='imst'
    endif
    " Open the Project Window
    if !exists("g:proj_running") || (bufwinnr(g:proj_running) == -1)
        exec 'silent vertical new '.filename
        silent! wincmd H
        exec 'vertical resize '.g:proj_window_width
        let b:maxwinheight = winheight('.')
    else
        silent! 99wincmd h
        return
    endif
    " Process the flags
    let b:proj_cd_cmd='cd'
    if match(g:proj_flags, '\Cl') != -1
        let b:proj_cd_cmd = 'lcd'
    endif
    ">>>------------------------------------------------------------------
    " ProjFoldText() <<<
    "   The foldtext function for displaying just the description.
    function! ProjFoldText()
        let line=substitute(getline(v:foldstart),'^[ \t#]*\([^=]*\).*', '\1', '')
        let line=strpart('                                     ', 0, (v:foldlevel - 1)).substitute(line,'\s*{\+\s*', '', '')
        return line
    endfunction
    ">>>------------------------------------------------------------------
    " s:DoSetup() <<<
    "   Ensure everything is set up
    function! s:DoSetup()
        setlocal foldmethod=marker
        setlocal foldmarker={,}
        setlocal commentstring=%s
        setlocal foldcolumn=0
        setlocal nonumber
        setlocal noswapfile
        setlocal shiftwidth=1
        setlocal foldtext=ProjFoldText()
        setlocal nobuflisted
        setlocal nowrap
    endfunction
    ">>>------------------------------------------------------------------
    call s:DoSetup()
    " Syntax Stuff <<<
    if match(g:proj_flags, '\Cs')!=-1 && has('syntax') && exists('g:syntax_on') && !has('syntax_items')
        syntax match projectDescriptionDir '^\s*\S.\{-}=\s*\(\f\|:\)\+'        contains=projectDescription,projectWhiteError
        syntax match projectDescription    '\S[^=]\{-}\S='he=e-1,me=e-1 contained nextgroup=projectDirectory,projectWhiteError
        syntax match projectDescription    '{\|}'
        syntax match projectDirectory      '=\(\f\|:\)\+'                      contained
        syntax match projectScriptinout    '\<in='he=e-1,me=e-1         nextgroup=projectDirectory,projectWhiteError
        syntax match projectScriptinout    '\<out='he=e-1,me=e-1        nextgroup=projectDirectory,projectWhiteError
        syntax match projectComment        '#.*'
        syntax match projectCD             '\<CD\s*=\s*\(\f\|:\)\+'            contains=projectDescription,projectWhiteError
        syntax match projectFilterEntry    '\<filter\s*=.*"'            contains=projectWhiteError,projectFilterError,projectFilter,projectFilterRegexp
        syntax match projectFilter         '\<filter='he=e-1,me=e-1     contained nextgroup=projectFilterRegexp,projectFilterError,projectWhiteError
        syntax match projectFlagsEntry     '\<flags\s*=\( \|[^ ]*\)'    contains=projectFlags,projectWhiteError
        syntax match projectFlags          '\<flags'                    contained nextgroup=projectFlagsValues,projectWhiteError
        syntax match projectFlagsValues    '=[^ ]* 'me=e-1              contained contains=projectFlagsError
        syntax match projectFlagsError     '[^rtTsSwl= ]\+'             contained
        syntax match projectWhiteError     '=\s\+'hs=s+1                contained
        syntax match projectWhiteError     '\s\+='he=e-1                contained
        syntax match projectFilterError    '=[^"]'hs=s+1                contained
        syntax match projectFilterRegexp   '=".*"'hs=s+1                contained
        syntax match projectFoldText       '^[^=]\+{'

        highlight def link projectDescription  Identifier
        highlight def link projectScriptinout  Identifier
        highlight def link projectFoldText     Identifier
        highlight def link projectComment      Comment
        highlight def link projectFilter       Identifier
        highlight def link projectFlags        Identifier
        highlight def link projectDirectory    Constant
        highlight def link projectFilterRegexp String
        highlight def link projectFlagsValues  String
        highlight def link projectWhiteError   Error
        highlight def link projectFlagsError   Error
        highlight def link projectFilterError  Error
    endif
    ">>>------------------------------------------------------------------
    " s:SortR(start, end) <<<
    " Sort lines.  SortR() is called recursively.
    "  from ":help eval-examples" by Robert Webb, slightly modified
    function! s:SortR(start, end)
        if (a:start >= a:end)
            return
        endif
        let partition = a:start - 1
        let middle = partition
        let partStr = getline((a:start + a:end) / 2)
        let i = a:start
        while (i <= a:end)
            let str = getline(i)
            if str < partStr
                let result = -1
            elseif str > partStr
                let result = 1
            else
                let result = 0
            endif
            if (result <= 0)
                let partition = partition + 1
                if (result == 0)
                    let middle = partition
                endif
                if (i != partition)
                    let str2 = getline(partition)
                    call setline(i, str2)
                    call setline(partition, str)
                endif
            endif
            let i = i + 1
        endwhile
        if (middle != partition)
            let str = getline(middle)
            let str2 = getline(partition)
            call setline(middle, str2)
            call setline(partition, str)
        endif
        call s:SortR(a:start, partition - 1)
        call s:SortR(partition + 1, a:end)
    endfunc
    ">>>
    " s:IsAbsolutePath(path) <<<
    "   Returns true if filename has an absolute path.
    function! s:IsAbsolutePath(path)
        if a:path[0] == '/' || a:path[0] == '~' || a:path[0] == '\\' || a:path[1] == ':'
            return 1
        endif
        if a:path =~ '^ftp:' || a:path =~ '^rcp:' || a:path =~ '^scp:' || a:path =~ '^http:'
            return 2
        endif
        return 0;
    endfunction
    " >>>
    " s:DoSetupAndSplit() <<<
    "   Call DoSetup to ensure the settings are correct.  Split to the next
    "   file.
    function! s:DoSetupAndSplit()
        " Ensure that all the settings are right
        call s:DoSetup()
        " Determine if there is a CTRL_W-p window
        let n = winnr()
        silent! wincmd p
        if n == winnr()
            silent! wincmd l
        endif
        if n == winnr()
            " If n == winnr(), then there is no CTRL_W-p window
            " So we have to create a new one
            exec 'silent vertical new '.bufname('#')
            " Go back to the Project Window and ensire it is the right width
            wincmd p
            silent! wincmd H
            exec 'vertical resize '.g:proj_window_width
            wincmd p
        endif
    endfunction
    ">>>------------------------------------------------------------------
    " s:RecursivelyConstructDirectives(lineno) <<<
    "   Construct the inherited directives
    function! s:RecursivelyConstructDirectives(lineno)
        let lineno=s:FindFoldTop(a:lineno)
        let foldlineno = lineno
        let foldlev=foldlevel(lineno)
        if foldlev > 1
            " Go to parent fold
            while foldlevel(lineno) >= foldlev
                let lineno = lineno - 1
            endwhile
            let parent_infoline = s:RecursivelyConstructDirectives(lineno)
            let parent_home = substitute(parent_infoline, '^[^=]*=\(\(\f\|:\)\+\).*', '\1', '')
            let parent_c_d = substitute(parent_infoline, '.*\<CD=\(\(\f\|:\)\+\).*', '\1', '')
            if strlen(parent_c_d) == strlen(parent_infoline)
                let parent_c_d = ""
            endif
            let parent_scriptin = substitute(parent_infoline, '.*\<in=\(\(\f\|:\)\+\).*', '\1', '')
            if strlen(parent_scriptin) == strlen(parent_infoline)
                let parent_scriptin = ""
            endif
            let parent_scriptout = substitute(parent_infoline, '.*\<out=\(\(\f\|:\)\+\).*', '\1', '')
            if strlen(parent_scriptout) == strlen(parent_infoline)
                let parent_scriptout = ""
            endif
            let parent_filter = substitute(parent_infoline, '.*\<filter="\([^"]*\).*', '\1', '')
            if strlen(parent_filter) == strlen(parent_infoline)
                " If there is no filter, we assume *
                let parent_filter = "*"
            endif
        else
            let parent_home = ""
            let parent_c_d = ""
            let parent_filter = "*"
            let parent_scriptin = ""
            let parent_scriptout = ""
        endif

        let infoline = getline(foldlineno)
        " Extract the home directory of this fold
        let home=substitute(infoline, '^[^=]*=\(\(\f\|:\)\+\).*', '\1', '')
        if strlen(home) == strlen(infoline)
            let home=""
        else
            if home=='.'
                let home=parent_home
            endif
            if foldlevel(foldlineno) == 1
                " Top fold
                if !s:IsAbsolutePath(home)
                    call confirm('Outermost Project Fold must have absolute path!', "&OK", 1)
                    let home = '~'  " Some 'reasonable' value
                endif
            endif
        endif
        if s:IsAbsolutePath(home) || (strlen(parent_home) == 0)
            let parent_home=home
        else
            if strlen(home) != 0
                let parent_home=parent_home.'/'.home
            endif
        endif
        " Extract any CD information
        let c_d = substitute(infoline, '.*CD=\(\(\f\|:\)\+\).*', '\1', '')
        if strlen(c_d) == strlen(infoline)
            let c_d=""
        else
            " Translate 'CD=.' to the home directory for the fold
            if c_d == '.'
                let c_d = parent_home
            endif
            if foldlevel(foldlineno) == 1
                " Top fold
                if !s:IsAbsolutePath(c_d)
                    call confirm('Outermost Project Fold must have absolute CD path!', "&OK", 1)
                    let c_d = '.'  " Some 'reasonable' value
                endif
            endif
        endif
        if strlen(c_d) != 0
            if s:IsAbsolutePath(c_d) || (strlen(parent_c_d) == 0)
                let parent_c_d=c_d
            else
                let parent_c_d=parent_c_d.'/'.c_d
            endif
        endif

        " Extract scriptin
        let scriptin = substitute(infoline, '.*\<in=\(\(\f\|:\)\+\).*', '\1', '')
        if strlen(scriptin) == strlen(infoline)
            let scriptin = ""
        else
            if !s:IsAbsolutePath(scriptin)
                let scriptin=parent_home.'/'.scriptin
            endif
            let parent_scriptin = scriptin
        endif

        " Extract scriptout
        let scriptout = substitute(infoline, '.*\<out=\(\(\f\|:\)\+\).*', '\1', '')
        if strlen(scriptout) == strlen(infoline)
            let scriptout = ""
        else
            if !s:IsAbsolutePath(scriptout)
                let scriptout=parent_home.'/'.scriptout
            endif
            let parent_scriptout = scriptout
        endif

        let filter = substitute(infoline, '.*\<filter="\([^"]*\).*', '\1', '')
        if strlen(filter) == strlen(infoline)
            " If there is no filter, we assume *
            let filter = parent_filter
        endif

        let retval='Directory='.parent_home
        if strlen(parent_c_d) != 0
            let retval=retval.' CD='.parent_c_d
        endif
        if strlen(parent_scriptin) != 0
            let retval=retval.' in='.parent_scriptin
        endif
        if strlen(parent_scriptout) != 0
            let retval=retval.' out='.parent_scriptout
        endif
        if strlen(filter) != 0
            let retval=retval.' filter="'.filter.'"'
        endif
        return retval
    endfunction
    ">>>------------------------------------------------------------------
    " s:DoSetupAndSplit_au() <<<
    "   Same as above but ensure that the Project window is the current
    "   window.  Only called from an autocommand
    function! s:DoSetupAndSplit_au()
        call s:DoSetupAndSplit()
        silent! wincmd p
    endfunction
    ">>>------------------------------------------------------------------
    " s:OpenEntry(line, precmd, editcmd, buffcmd) <<<
    "   Get the filename under the cursor, and open a window with it.
    function! s:OpenEntry(line, precmd, editcmd, buffcmd)
        let savelz=&lz
        set lz
        silent exec a:precmd
        " Ensure the window is the right width
        exec 'vertical resize '.g:proj_window_width
        if foldlevel(a:line) == 0
            " If we're outside a fold, do nothing
            return 0
        endif
        " Get rid of comments
        let fname=substitute(getline(a:line), '#.*', '', '')
        " Get rid of leading whitespace
        let fname=substitute(fname, '^\s*\(.*\)', '\1', '')
        if strlen(fname) == 0
            " The line is blank. Do nothing.
            return 0
        endif
        let infoline = s:RecursivelyConstructDirectives(a:line)
        " Extract the home directory of this fold
        let home=substitute(infoline, '^[^=]*=\(\(\f\|:\)\+\).*', '\1', '').'/'
        "Save the cd command
        let cd_cmd = b:proj_cd_cmd
        call s:DoSetupAndSplit()
        " If it is an absolute path, don't prepend home
        if !s:IsAbsolutePath(fname)
            let fname=home.fname
        endif
        if bufnr(fname) == -1
            " The buffer doesn't exist. Execute the editcmd on the filename to
            " load the buffer.
            if s:IsAbsolutePath(fname) == 2
                exec a:editcmd.' '.fname
            else
                silent exec a:editcmd.' '.fname
            endif
        else
            " The buffer does exist. Just use the buffcmd on the buffer to
            " display it.
            if s:IsAbsolutePath(fname) == 2
                exec a:buffcmd.' '.fname
            else
                silent exec a:buffcmd.' '.fname
            endif
        endif
        " Extract any CD information
        if infoline =~ 'CD='
            let c_d = substitute(infoline, '.*\<CD=\(\(\f\|:\)\+\).*', '\1', '')
            if match(g:proj_flags, '\CL') != -1
                call s:SetupAutoCommand(c_d)
            endif
            " Translate 'CD=.' to the home directory for the fold
            if c_d == '.'
                let c_d = home
            endif
            if !isdirectory(glob(c_d))
                call confirm("From this fold's entry,\n".'"'.c_d.'" is not a valid directory.', "&OK", 1)
            else
                silent exec cd_cmd.' '.c_d
            endif
        endif
        " Extract any scriptin information
        if infoline =~ '\<in='
            let scriptin = substitute(infoline, '.*\<in=\(\(\f\|:\)\+\).*', '\1', '')
            if strlen(scriptin) != strlen(infoline)
                if !s:IsAbsolutePath(scriptin)
                    let scriptin=home.'/'.scriptin
                endif
                if !filereadable(glob(scriptin))
                    call confirm('"'.scriptin.'" not found. Ignoring.', "&OK", 1)
                else
                    call s:SetupScriptAutoCommand('BufEnter', scriptin)
                    exec 'source '.scriptin
                endif
            endif
        endif
        if infoline =~ '\<out='
            let scriptout = substitute(infoline, '.*\<out=\(\(\f\|:\)\+\).*', '\1', '')
            if strlen(scriptout) != strlen(infoline)
                if !s:IsAbsolutePath(scriptout)
                    let scriptout=home.'/'.scriptout
                endif
                if !filereadable(glob(scriptout))
                    call confirm('"'.scriptout.'" not found. Ignoring.', "&OK", 1)
                else
                    call s:SetupScriptAutoCommand('BufLeave', scriptout)
                endif
            endif
        endif
        let &lz=savelz
        call s:DisplayInfo()
        return 1
    endfunction
    ">>>------------------------------------------------------------------
    " s:DoFoldOrOpenEntry(cmd0, cmd1, cmd2) <<<
    "   Used for double clicking. If the mouse is on a fold, open/close it. If
    "   not, try to open the file.
    function! s:DoFoldOrOpenEntry(cmd0, cmd1, cmd2)
        if getline('.')=~'{\|}' || foldclosed('.') != -1
            normal! za
        else
            call s:OpenEntry(line('.'), a:cmd0, a:cmd1, a:cmd2)
        endif
    endfunction
    ">>>------------------------------------------------------------------
    " s:VimDirListing(filter, padding, sort) <<<
    function! s:VimDirListing(filter, padding, sort)
        let end = 0
        let files=''
        let filter = a:filter
        " Chop up the filter
        "   Apparently glob() cannot take something like this: glob('*.c *.h')
        let while_var = 1
        while while_var
            let end = stridx(filter, ' ')
            if end == -1
                let end = strlen(filter)
                let while_var = 0
            endif
            let single=glob(strpart(filter, 0, end))
            if strlen(single) != 0
                let files = files.single."\n"
            endif
            let filter = strpart(filter, end + 1)
        endwhile
        " files now contains a list of everything in the directory. We need to
        " weed out the directories.
        put =files
        let line=getline('.')
        let startline=line('.')
        " This 'while' loop looks at each directory entry and deletes the line
        " to the black hole register if it is a directory name.  When we reach
        " a fold boundary marked by { or }, exit the loop
        while line !~ '\({\|}\)'
            if isdirectory(glob(line))
                d _
            else
                " It is not a directory, so prepend the padding
                " (Skip comments)
                if line !~ '^\s*#'
                    call setline('.', a:padding.line)
                endif
                normal! j
            endif
            " Get the next line
            let line=getline('.')
        endwhile
        if a:sort
            call s:SortR(startline, line('.')-1)
        endif
    endfunction
    ">>>------------------------------------------------------------------
    " s:DoEntryFromDir(line, name, absolute_dir, dir, c_d, filter_directive, filter, foldlev, sort) <<<
    "   Places a fold in the buffer consisting of files from the given
    "   directory. The indention is controlled by foldlev.
    function! s:DoEntryFromDir(line, name, absolute_dir, dir, c_d, filter_directive, filter, foldlev, sort)
        " Calculate the number of spaces for the indent
        let spaces=strpart('                                     ', 0, a:foldlev)
        " Put in the fold with two append()
        call append(a:line, spaces.'}')
        if strlen(a:c_d) > 0
            let c_d='CD='.a:c_d.' '
        else
            let c_d=''
        endif
        if strlen(a:filter_directive) > 0
            let c_d=c_d.'filter="'.a:filter_directive.'" '
        endif
        call append(a:line, spaces.a:name.'='.a:dir.' '.c_d.'{')
        " Move down one line and open the fold
        normal! jzo
        " Save the current working directory
        let cwd=getcwd()
        " Change to the dir specified
        exec 'cd '.a:absolute_dir
        " Get the files from Vim glob()
        call s:VimDirListing(a:filter, spaces.' ', a:sort)
        " Go to the top of the fold and close it
        normal! [zzc
        " Restore the previous directory. This can be simplified with a :cd -
        exec 'cd '.cwd
    endfunction
    ">>>------------------------------------------------------------------
    " s:CreateEntriesFromDir() <<<
    "   Prompts user for information and then calls s:DoEntryFromDir()
    function! s:CreateEntriesFromDir()
        " Save a mark for the current cursor position
        normal! mk
        let line=line('.')
        let name = inputdialog('Enter the Name of the Entry: ')
        if strlen(name) == 0
            return
        endif
        let foldlev=foldlevel(line)
        if (foldclosed(line) != -1) || (getline(line) =~ '}')
            let foldlev=foldlev - 1
        endif
        if foldlev <= 0
            let absolute = 'Absolute '
        else
            let absolute = ''
        endif
        let home=""
        let filter="*"
        if has('browse') && !has('win32')
            " Note that browse() is inconsistent: On Win32 you can't select a
            " directory, and it gives you a relative path.
            let dir = browse(0, 'Enter the '.absolute.'Directory to Load: ', '', '')
        else
            let dir = inputdialog('Enter the '.absolute.'Directory to Load: ', '')
        endif
        if (dir[strlen(dir)-1] == '/') || (dir[strlen(dir)-1] == '\\')
            let dir=strpart(dir, 0, strlen(dir)-1)
        endif
        if (foldlev > 0)
            " Cursor is now on the parent's fold
            let parent_directive=s:RecursivelyConstructDirectives(line('.'))
            let filter = substitute(parent_directive, '.*\<filter="\([^"]*\).*', '\1', '')
            let home=substitute(parent_directive, '^[^=]*=\(\(\f\|:\)\+\).*', '\1', '')
            if strlen(home) == strlen(parent_directive)
                let home=""
            elseif home[strlen(home)-1] != '/' && home[strlen(home)-1] != '\\'
                let home=home.'/'
            endif
            unlet parent_directive

            if !s:IsAbsolutePath(dir)
                " It is not a relative path  Try to make it relative
                " Recurse the hierarchy
                let hend=matchend(glob(dir), '\C'.glob(home))
                if hend != -1
                    " The directory can be a realtive path
                    let dir=strpart(dir, hend)
                else
                    let home=""
                endif
            endif
        endif
        if strlen(home.dir) == 0
            return
        endif
        if !isdirectory(glob(home.dir))
            if has("unix")
                silent exec '!mkdir '.home.dir.' > /dev/null'
            else
                call confirm('"'.home.dir.'" is not a valid directory.', "&OK", 1)
                return
            endif
        endif
        let c_d = inputdialog('Enter the CD parameter: ', '')
        let filter_directive = inputdialog('Enter the File Filter: ', '')
        if strlen(filter_directive) != 0
            let filter = filter_directive
        endif
        " If I'm on a closed fold, go to the bottom of it
        if foldclosedend(line) != -1
            let line = foldclosedend(line)
        endif
        let foldlev = foldlevel(line)
        " If we're at the end of a fold . . .
        if getline(line) =~ '}'
            " . . . decrease the indentation by 1.
            let foldlev = foldlev - 1
        endif
        " Do the work
        call s:DoEntryFromDir(line, name, home.dir, dir, c_d, filter_directive, filter, foldlev, 0)
        " Restore the cursor position
        normal! `k
    endfunction
    ">>>------------------------------------------------------------------
    " s:RefreshEntriesFromDir(recursive) <<<
    "   Finds metadata at the top of the fold, and then replaces all files
    "   with the contents of the directory.  Works recursively if recursive is
    "   1.
    function! s:RefreshEntriesFromDir(recursive)
        " Open the fold.  The ]z[z guarantees that we are on the first line of
        " the fold. The [z is not sufficient because it can jump to the
        " beginning of the previous fold if the cursor is on the first line of
        " a fold already.
        normal! zo]z[z
        let just_a_fold=0
        let infoline = s:RecursivelyConstructDirectives(line('.'))
        let immediate_infoline = getline('.')
        " Extract the home directory of the fold
        let dir = substitute(infoline, '[^=]*=\(\(\f\|:\)*\).*', '\1', '')
        if strlen(substitute(immediate_infoline, '[^=]*=\(\(\f\|:\)*\).*', '\1', '')) == strlen(immediate_infoline)
            let just_a_fold = 1
        endif
        if strlen(dir) == strlen(infoline)
            " No Match.  This means that this is just a label with no
            " directory entry.
            if a:recursive == 0
                " We're done--nothing to do
                return
            endif
            " Mark that it is just a fold, so later we don't delete filenames
            " that aren't there.
            let just_a_fold = 1
        endif
        if just_a_fold == 0
            " Extract the filter between quotes (we don't care what CD is).
            let filter = substitute(infoline, '.*\<filter="\([^"]*\).*', '\1', '')
            if strlen(filter) == strlen(infoline)
                " If there is no filter, we assume *
                let filter = '*'
            endif
            " Extract the description (name) of the fold
            let name = substitute(infoline, '^[#\t ]*\([^=]*\)=.*', '\1', '')
            if strlen(name) == strlen(infoline)
                " If there's no name, we're done.
                return
            endif
            if strlen(dir) == 0 || strlen(name) == 0
                return
            endif
            " Extract the flags
            let flags = substitute(immediate_infoline, '.*\<flags=\([^ {]*\).*', '\1', '')
            if match(g:proj_flags, '\CS') != -1
                let sort = 1
            else
                let sort = 0
            endif
            if strlen(flags) != strlen(immediate_infoline)
                if match(flags, '\Cr') != -1
                    " If the flags do not contain r (refresh), then treat it just
                    " like a fold
                    let just_a_fold = 1
                endif
                if match(flags, '\CS') != -1
                    let sort = 1
                endif
                if match(flags, '\Cs') != -1
                    let sort = 0
                endif
            else
                let flags=''
            endif
        endif
        " Move to the first non-fold boundary line
        normal! j
        " Delete filenames until we reach the end of the fold
        while getline('.') !~ '}'
            if getline('.') !~ '{'
                " We haven't reached a sub-fold, so delete what's there.
                if just_a_fold == 0 && getline('.') !~ '^\s*#'
                    d _
                else
                    " Skip lines only in a fold and comment lines
                    normal! j
                endif
            else
                " We have reached a sub-fold. If we're doing recursive, then
                " call this function again. If not, find the end of the fold.
                if a:recursive == 1
                    call s:RefreshEntriesFromDir(1)
                    normal! ]zj
                else
                    if foldclosed('.') == -1
                        normal! zc
                    endif
                    normal! j
                endif
            endif
        endwhile
        if just_a_fold == 0
            " We're not just in a fold, and we have deleted all the filenames.
            " Now it is time to regenerate what is in the directory.
            if !isdirectory(glob(dir))
                call confirm('"'.dir.'" is not a valid directory.', "&OK", 1)
            else
                let foldlev=foldlevel('.')
                " T flag.  Thanks Tomas Z.
                if (match(flags, '\Ct') != -1) || ((match(g:proj_flags, '\CT') == -1) && (match(flags, '\CT') == -1))
                    " Go to the top of the fold (force other folds to the
                    " bottom)
                    normal! [z
                    normal! j
                    " Skip any comments
                    while getline('.') =~ '^\s*#'
                        normal! j
                    endwhile
                endif
                normal! k
                let cwd=getcwd()
                let spaces=strpart('                                     ', 0, foldlev)
                exec 'cd '.dir
                call s:VimDirListing(filter, spaces, sort)
                exec 'cd '.cwd
            endif
        endif
        " Go to the top of the refreshed fold.
        normal! [z
    endfunction
    ">>>------------------------------------------------------------------
    " s:MoveUp() <<<
    "   Moves the entity under the cursor up a line.
    function! s:MoveUp()
        let lineno=line('.')
        if lineno == 1
            return
        endif
        let fc=foldclosed('.')
        let a_reg=@a
        if lineno == line('$')
            normal! "add"aP
        else
            normal! "addk"aP
        endif
        let @a=a_reg
        if fc != -1
            normal! zc
        endif
    endfunction
    ">>>------------------------------------------------------------------
    " s:MoveDown() <<<
    "   Moves the entity under the cursor down a line.
    function! s:MoveDown()
        let fc=foldclosed('.')
        let a_reg=@a
        normal! "add"ap
        let @a=a_reg
        if fc != -1
            if foldclosed('.') == -1
                normal! zc
            endif
        endif
    endfunction " >>>
    " s:DisplayInfo() <<<
    "   Displays filename and current working directory when i (info) is in
    "   the flags.
    function! s:DisplayInfo()
        if match(g:proj_flags, '\Ci') != -1
            echo 'file: '.expand('%').', cwd: '.getcwd().', lines: '.line('$')
        endif
    endfunction
    " >>>
    " s:SetupAutoCommand(cwd) <<<
    "   Sets up an autocommand to ensure that the cwd is set to the one
    "   desired for the fold regardless.  :lcd only does this on a per-window
    "   basis, not a per-buffer basis.
    function! s:SetupAutoCommand(cwd)
        if !exists("b:proj_has_autocommand")
            let b:proj_cwd_save = getcwd()
            let b:proj_has_autocommand = 1
            let bufname=substitute(expand('%:p', 0), '\\', '/', 'g')
            exec 'au BufEnter '.bufname.' let b:proj_cwd_save=getcwd() | cd '.a:cwd
            exec 'au BufLeave '.bufname.' exec "cd ".b:proj_cwd_save'
        endif
    endfunction
    ">>>
    " s:SetupScriptAutoCommand(inout, script) <<<
    "   Sets up an autocommand to run the scriptin script.
    function! s:SetupScriptAutoCommand(inout, script)
        if !exists("b:proj_has_".a:inout)
            let b:proj_has_{a:inout} = 1
            exec 'au '.a:inout.' '.substitute(expand('%:p', 0), '\\', '/', 'g').' source '.a:script
        endif
    endfunction
    " >>>
    " s:DoEnsurePlacementSize_au() <<<
    "   Ensure that the Project window is on the left of the window and has
    "   the correct size. Only called from an autocommand
    function! s:DoEnsurePlacementSize_au()
        if exists("g:proj_doinghelp")
            if g:proj_doinghelp > 0
                let g:proj_doinghelp = g:proj_doinghelp - 1
                return
            endif
            unlet g:proj_doinghelp
            return
        endif
        if (winnr() != 1) || (winheight('.') != b:maxwinheight)
            " This if statement avoids the flicker when wincmd H is executed
            " (set lz doesn't help with this flicker)
            silent! wincmd H
        endif
        exec 'vertical resize ' . g:proj_window_width
    endfunction
    ">>>------------------------------------------------------------------
    " s:Spawn(number) <<<
    "   Spawn an external command on the file
    function! s:Spawn(number)
        if exists("g:proj_run".a:number)
            let fname=getline('.')
            if fname!~'{\|}'
                let fname=substitute(fname, '#.*', '', '')
                let fname=substitute(fname, '^\s*\(.*\)\s*', '\1', '')
                if strlen(fname) == 0
                    " The line is blank. Do nothing.
                    return
                endif
                let parent_infoline = s:RecursivelyConstructDirectives(line('.'))
                let parent_home = substitute(parent_infoline, '^[^=]*=\(\(\f\|:\)\+\).*', '\1', '')
                exec substitute(g:proj_run{a:number}, '%s', parent_home.'/'.fname, 'g')
            endif
        endif
    endfunction
    ">>>------------------------------------------------------------------
    " s:ListSpawn(varnamesegment) <<<
    "   List external commands
    function! s:ListSpawn(varnamesegment)
        let number = 1
        while number < 10
            if exists("g:proj_run".a:varnamesegment.number)
                echohl LineNr | echo number.':' | echohl None | echon ' '.g:proj_run{a:varnamesegment}{number}
            else
                echohl LineNr | echo number.':' | echohl None
            endif
            let number=number + 1
        endwhile
    endfunction
    ">>>------------------------------------------------------------------
    " s:FindFoldTop(line) <<<
    "   Return the line number of the directive line
    function! s:FindFoldTop(line)
        let lineno=a:line
        while getline(lineno) !~ '{' && lineno > 1
            if getline(lineno) =~ '}'
                let lineno=s:FindFoldTop(lineno - 1)
            endif
            let lineno = lineno - 1
        endwhile
        return lineno
    endfunction
    ">>>------------------------------------------------------------------
    " s:FindFoldBottom(line) <<<
    "   Return the line number of the directive line
    function! s:FindFoldBottom(line)
        let lineno=a:line
        if getline(lineno) =~ '{'
            let lineno=lineno + 1
        endif
        while getline(lineno) !~ '}' && lineno < line('$')
            if getline(lineno) =~ '{'
                let lineno=s:FindFoldBottom(lineno)
            endif
            let lineno = lineno + 1
        endwhile
        return lineno
    endfunction
    ">>>------------------------------------------------------------------
    " s:LoadAll(recurse, line) <<<
    "   Load all files in a project
    function! s:LoadAll(recurse, line)
        let lineno=s:FindFoldTop(a:line) + 1
        while getline(lineno) !~ '}'
            if getline(lineno) =~ '{'
                if a:recurse
                    let flags = substitute(getline(lineno), '.*\<flags=\([^ {]*\).*', '\1', '')
                    if strlen(flags) == strlen(getline(lineno)) || match(flags, '\Cl') == -1
                        let lineno = s:LoadAll(1, lineno)
                    else
                        let lineno = s:FindFoldBottom(lineno)
                    endif
                else
                    let lineno = s:FindFoldBottom(lineno)
                endif
            else
                if s:OpenEntry(lineno, '', 'e', 'bu')
                    wincmd p
                endif
            endif
            let lineno = lineno + 1
        endwhile
        return lineno
    endfunction
    ">>>------------------------------------------------------------------
    " s:WipeAll(recurse, line) <<<
    "   Wipe all files in a project
    function! s:WipeAll(recurse, line)
        let lineno=s:FindFoldTop(a:line) + 1
        let home=s:RecursivelyConstructDirectives(lineno)
        let home=substitute(home, '^[^=]*=\(\(\f\|:\)\+\).*', '\1', '')
        if strlen(home) != 0
            let home=home.'/'
        endif
        while getline(lineno) !~ '}'
            if getline(lineno) =~ '{'
                if a:recurse
                    let flags = substitute(getline(lineno), '.*\<flags=\([^ {]*\).*', '\1', '')
                    if strlen(flags) == strlen(getline(lineno)) || match(flags, '\Cw') == -1
                        let lineno = s:WipeAll(1, lineno)
                    else
                        let lineno = s:FindFoldBottom(lineno)
                    endif
                else
                    let lineno = s:FindFoldBottom(lineno)
                endif
            else
                " Get rid of comments
                let fname=substitute(getline(lineno), '#.*', '', '')
                " Get rid of leading whitespace
                let fname=substitute(fname, '^\s*\(.*\)', '\1', '')
                if strlen(fname) != 0
                    if !s:IsAbsolutePath(fname)
                        let fname=home.fname
                    endif
                    if s:IsAbsolutePath(fname) != 2
                        let fname=glob(fname)
                    endif
                    if bufloaded(fname)
                        if getbufvar(fname, '&modified') == 1
                            exec 'sb '.fname
                            wincmd L
                            w
                            wincmd p
                        endif
                        exec 'bwipe! '.fname
                    endif
                endif
            endif
            let lineno = lineno + 1
        endwhile
        return lineno
    endfunction
    ">>>------------------------------------------------------------------
    " s:GrepAll(recurse, lineno, pattern) <<<
    "   Grep all files in a project, optionally recursively
    function! s:GrepAll(recurse, lineno, pattern)
        if strlen(a:pattern) == 0
            let pattern=input("GREP Pattern: ")
        else
            let pattern=a:pattern
        endif
        let fnames=Project_GetAllFnames(a:recurse, a:lineno, ' ')
        cclose " Make sure grep window is closed
        call s:DoSetupAndSplit()
        silent! exec 'silent! grep '.pattern.' '.fnames
        copen
    endfunction
    ">>>
    " Project_GetAllFnames(recurse, lineno, separator) <<<
    "   Grep all files in a project, optionally recursively
    function! Project_GetAllFnames(recurse, lineno, separator)
        let home=s:RecursivelyConstructDirectives(a:lineno)
        let home=substitute(home, '^[^=]*=\(\(\f\|:\)\+\).*', '\1', '')
        if strlen(home) != 0
            let home=home.'/'
        endif
        let lineno=s:FindFoldTop(a:lineno) + 1
        let curline=getline(lineno)
        let retval=""
        while curline !~ '}' && curline < line('$')
            if curline =~ '{'
                if a:recurse
                    if retval != ""
                        let retval=retval.a:separator.Project_GetAllFnames(a:recurse+1, lineno, a:separator)
                    else
                        let retval=Project_GetAllFnames(a:recurse+1, lineno, a:separator)
                    endif
                endif
                let lineno = s:FindFoldBottom(lineno)
            else
                let fname=substitute(curline, '#.*', '', '')
                let fname=substitute(fname, '^\s*\(.*\)', '\1', '')
                if strlen(fname) != strlen(curline) && strlen(fname) > 0
                    if !s:IsAbsolutePath(fname)
                        let fname=home.fname
                    endif
                    if retval != ""
                        let retval=retval.a:separator.fname
                    else
                        let retval=fname
                    endif
                endif
            endif
            let lineno=lineno + 1
            let curline=getline(lineno)
        endwhile
        return retval
    endfunction
    ">>>------------------------------------------------------------------
    " s:SpawnAll(recurse, number) <<<
    "   Spawn an external command on the files of a project
    function! s:SpawnAll(recurse, number)
        if exists("g:proj_run_fold".a:number)
            if g:proj_run_fold{a:number}[0] == '*'
                let fnames=Project_GetAllFnames(a:recurse, line('.'), "\010")."\010"
                while strlen(fnames) > 0
                    let fname = substitute(fnames,  '\(\(\f\|:\)*\).*', '\1', '')
                    let fnames = substitute(fnames, '\(\f\|:\)*.\(.*\)', '\2', '')
                    exec substitute(strpart(g:proj_run_fold{a:number}, 1), '%s', fname, 'g')
                endwhile
            else
                let fnames=Project_GetAllFnames(a:recurse, line('.'), ' ')
                exec substitute(g:proj_run_fold{a:number}, '%s', fnames, 'g')
            endif
        endif
    endfunction
    ">>>------------------------------------------------------------------

    if !exists("g:proj_running")
        " Mappings <<<
        nnoremap <buffer> <silent> <Return>   \|:call <SID>DoFoldOrOpenEntry('', 'e', 'bu')<CR>
        nnoremap <buffer> <silent> <S-Return> \|:call <SID>DoFoldOrOpenEntry('', 'sp', 'sbu')<CR>
        nnoremap <buffer> <silent> <C-Return> \|:call <SID>DoFoldOrOpenEntry('silent! only', 'e', 'bu')<CR>
        nmap     <buffer> <silent> <LocalLeader>s <S-Return>
        nmap     <buffer> <silent> <LocalLeader>o <C-Return>
        nmap     <buffer> <silent> <LocalLeader>i :echo <SID>RecursivelyConstructDirectives(line('.'))<CR>
        nmap     <buffer> <silent> <M-CR> <Return><C-W>p
        nmap     <buffer> <silent> <LocalLeader>v <M-CR>
        nmap     <buffer> <silent> <LocalLeader>l \|:call <SID>LoadAll(0, line('.'))<CR>
        nmap     <buffer> <silent> <LocalLeader>L \|:call <SID>LoadAll(1, line('.'))<CR>
        nmap     <buffer> <silent> <LocalLeader>w \|:silent call <SID>WipeAll(0, line('.'))<CR>
        nmap     <buffer> <silent> <LocalLeader>W \|:silent call <SID>WipeAll(1, line('.'))<CR>
        nmap     <buffer> <silent> <LocalLeader>g \|:call <SID>GrepAll(0, line('.'), "")<CR>
        nmap     <buffer> <silent> <LocalLeader>G \|:call <SID>GrepAll(1, line('.'), "")<CR>
        nnoremap <buffer> <silent> <2-LeftMouse>   \|:call <SID>DoFoldOrOpenEntry('', 'e', 'bu')<CR>
        nnoremap <buffer> <silent> <S-2-LeftMouse> \|:call <SID>DoFoldOrOpenEntry('', 'sp', 'sbu')<CR>
        nnoremap <buffer> <silent> <M-2-LeftMouse> <M-CR>
        nnoremap <buffer> <silent> <S-LeftMouse>   <LeftMouse>
        nmap     <buffer> <silent> <C-2-LeftMouse> <C-Return>
        nnoremap <buffer> <silent> <C-LeftMouse>   <LeftMouse>
        nnoremap <buffer> <silent> <3-LeftMouse>  \|
        nmap     <buffer> <silent> <RightMouse>   <space>
        nmap     <buffer> <silent> <2-RightMouse> <space>
        nmap     <buffer> <silent> <3-RightMouse> <space>
        nmap     <buffer> <silent> <4-RightMouse> <space>
        nnoremap <buffer> <silent> <space>  \|:silent exec 'vertical resize '.(match(g:proj_flags, '\Ct')!=-1 && winwidth('.') > g:proj_window_width?(g:proj_window_width):(winwidth('.') + g:proj_window_increment))<CR>
        nnoremap <buffer> <silent> <C-Up>   \|:silent call <SID>MoveUp()<CR>
        nnoremap <buffer> <silent> <C-Down> \|:silent call <SID>MoveDown()<CR>
        nmap     <buffer> <silent> <LocalLeader><Up> <C-Up>
        nmap     <buffer> <silent> <LocalLeader><Down> <C-Down>
        let k=1
        while k < 10
            exec 'nmap <buffer> <LocalLeader>'.k.'  \|:call <SID>Spawn('.k.')<CR>'
            exec 'nmap <buffer> <LocalLeader>f'.k.' \|:call <SID>SpawnAll(0, '.k.')<CR>'
            exec 'nmap <buffer> <LocalLeader>F'.k.' \|:call <SID>SpawnAll(1, '.k.')<CR>'
            let k=k+1
        endwhile
        nmap     <buffer>          <LocalLeader>0 \|:call <SID>ListSpawn("")<CR>
        nmap     <buffer>          <LocalLeader>f0 \|:call <SID>ListSpawn("_fold")<CR>
        nmap     <buffer>          <LocalLeader>F0 \|:call <SID>ListSpawn("_fold")<CR>
        nnoremap <buffer> <silent> <LocalLeader>c :call <SID>CreateEntriesFromDir()<CR>
        nnoremap <buffer> <silent> <LocalLeader>r :call <SID>RefreshEntriesFromDir(0)<CR>
        nnoremap <buffer> <silent> <LocalLeader>R :call <SID>RefreshEntriesFromDir(1)<CR>
        " The :help command stomps on the Project Window.  Try to avoid that.
        " This is not perfect, but it is alot better than without the
        " mappings.
        cnoremap <buffer> help let g:proj_doinghelp = 1<CR>:help
        nnoremap <buffer> <F1> :let g:proj_doinghelp = 1<CR><F1>
        " This is to avoid changing the buffer, but it is not fool-proof.
        nnoremap <buffer> <silent> <C-^> \|
        if match(g:proj_flags, '\Cm') != -1
            nnoremap <silent> <C-W>o :let lzsave=&lz<CR>:set lz<CR><C-W>o:Project<CR>:silent! wincmd p<CR>:let &lz=lzsave<CR>:unlet lzsave<CR>
            nmap     <silent> <C-W><C-O> <C-W>o
        endif " >>>
        " Autocommands <<<
        " Autocommands to clean up if we do a buffer wipe
        " These don't work unless we substitute \ for / for Windows
        let bufname=substitute(expand('%:p', 0), '\\', '/', 'g')
        exec 'au BufWipeout '.bufname.' au! * '.bufname
        exec 'au BufWipeout '.bufname.' unlet g:proj_running'
        " Autocommands to keep the window the specified size
        exec 'au WinEnter,WinLeave '.bufname.' call s:DoEnsurePlacementSize_au()'
        exec 'au BufWinEnter '.bufname.' call s:DoSetupAndSplit_au()'
        " >>>
        setlocal buflisted
        let g:proj_running = bufnr(bufname)
        if g:proj_running == -1
            call confirm('Project/Vim error. Please Enter :Project again and report this bug.', "&OK", 1)
            unlet g:proj_running
        endif
        setlocal nobuflisted
    endif
endfunction " >>>

if !exists(':Project')
    command -nargs=? -complete=file Project call <SID>Project('<args>')
endif
finish

" vim600: set foldmethod=marker foldmarker=<<<,>>> foldlevel=1:
