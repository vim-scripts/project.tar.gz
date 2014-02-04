## README

This is a mirror of http://www.vim.org/scripts/script.php?script_id=69

You can use this plugin's basic functionality to set up a list of
frequently-accessed files for easy navigation. The list of files
will be displayed in a window on the left side of the Vim
window, and you can press <Return> or double-click on
filenames in the list to open the files. This is similar to how
some IDEs I've used work. I find this easier to use than
having to navigate a directory hierarchy with the file-explorer.
It also obviates the need for a buffer explorer because you
have your list of files on the left of the Vim Window.


But there's much, much more . . . .

You can also instruct the Plugin to change to a directory and
to run scripts when you select a file. These scripts can, for
example, modify the environment to include compilers in
$PATH. This makes it very easy to use quickfix with multiple
projects that use different environments. I give examples in
the documentation.

Other features include:
    o Loading/Unloading all the files in a Project (\l, \L, \w, and \W)
    o Grepping all the files in a Project (\g and \G)
    o Running a user-specified script on a file (can be used
      to launch an external program on the file) (\1 through \9)
    o Running a user-specified script on all the files in a Project
      (\f1-\f9 and \F1-\F9)
    o Also works with the netrw plugin using directory
      names like ftp://remotehost
             (Good for webpage maintenance.)
    o Support for custom mappings for version control
      integration (example of perforce in the documentation).
    o I also give an example in the documentation on how to
      set up a custom launcher based on extension. The
      example launches *.jpg files in a viewer. I have also set
      up viewers for PDF (acroread) and HTML files (mozilla)
      for my own use.

This plugin is known to work on Linux, Solaris, and Windows.
I cannot test it on Windows, though, so please let me know if
you run into any problems. If you use it on other platforms,
let me know.

(Let me know if you need a .zip file)

## Using project based project files

This is a fork of <https://github.com/vim-scripts/project.tar.gz.git>
which lets the project get invoked using a `g:proj_file` if no file
path is passed.

That makes sense if you use project based `.vimrc` files and want to
have separate project files rather than one global project file over
all projects.

In your project's `.vimrc` you can define the variable like this:

    " init project environment variables
    let g:proj_path=expand("`pwd`")
    let g:proj_file=expand(g:proj_path.".vimproject")

The `ToogleProject()` function will than invoke the project with the
file defined for that project only.
