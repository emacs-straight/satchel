[Project](https://sr.ht/~theo/satchel/) | [Git](https://git.sr.ht/~theo/satchel) | [Lists](https://sr.ht/~theo/satchel/lists) | [Tracker](https://todo.sr.ht/~theo/satchel)

![ELPA](https://elpa.gnu.org/packages/satchel.svg)

# Satchel

satchel.el is a small utility to help manage buffers and files on a working
branch.  You can place files in a satchel, which is a file with a list of files
inside:

```elisp
;; satchel is named '~---src---satchel---#master'
(("/home/theo/src/satchel/satchel.el")
 ("/home/theo/src/satchel/README.md"))
```

This file is persisted, then read back in every time it is needed.  The useful
thing with this is that often you struggle with tens, if not a hundred buffers
in your buffer list, and fuzzy finding simply gets slow because you have to
parse the incremental search.  If you manage these satchels manually you can
maintain the 3-5 files that are most important at any given time, thus having a
much less cluttered search space.

## Satchels are separated by git branches
This means that when you switch branches, your satchels are automatically
updated and scoped to the work you are currently focused on.

## Install from ELPA
This package is available from GNU ELPA, so it should be easy to just `M-x
package-install RET satchel RET`

## Development
You are free to send patches to the lists, or add an issue to the tracker, both
of which are listed at the top of this document.
