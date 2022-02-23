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
