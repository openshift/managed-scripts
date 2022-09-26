This guide provides in broad strokes a set of Bash best practices that are expected to be adhered to.

### Best practices and tips

- Include a one-line comment description at the top of the script explaining what the script does.
- Always deference variables with double quotes. Ex: `"$variable"`
- Declare all global variables as `readonly`.
- Global variables always have UPPER_CASE naming.
- Always use local when setting variables, unless there is reason to use declare.
- All local variables should have lowercase naming.
- Always have a `main()` function for runnable scripts, called with `main` or `main "$@"`.
- Modularize code into functions as much as possible. All code goes into functions.
- Always use `set -euo pipefail`, fail fast and be aware of exit codes.
- Define functions as `myfunc() { ... }`, not `function myfun {...}`.
- Prefer absolute paths (leverage `$PWD`), always qualify relative paths with `./.`.
- Always use `[[` instead of `[`.
- Always validate input.
- Use `.sh` extension if a file is meant to be included or sourced.

### Good references

- Google's Bash styleguide [http://google-styleguide.googlecode.com/svn/trunk/shell.xml](http://google-styleguide.googlecode.com/svn/trunk/shell.xml)
