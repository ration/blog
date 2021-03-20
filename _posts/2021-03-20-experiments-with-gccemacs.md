---
layout: post
title:  Experiments with GccEmacs
date:   2021-03-20 11:40:01 +0200
tags:   [emacs]
---

As an active user of [vterm](https://github.com/akermu/emacs-libvterm), I've compiled my own version of Emacs for a
while to have the required submodules support. That said, I've also been on the bleeding edge native compiled
[GccEmacs](https://www.google.com/search?channel=fs&client=ubuntu&q=emacs+nativecomp) branch of Emacs just to see it's
performance promises. While not 100% functional compared to its more stable counterparts, it still has been an
worthwhile experiment. It promises natively compiled elisp, which in turn should result in faster Emacs. Once it reaches
feature parity, I suppose it's a direction Emacs will take.

## Was it worth it?

For me, no. I didn't do any benchmarks other than observed that the initial package load time was shaved a couple
seconds (7->4s, 145 packages). If this is meaningful to you, check it out. The subjective experience is all that matters
to me in this regard and any speedup must be considerably faster if the price is something breaking. And in day to day
usage, I noticed next to nothing.

Performance wise the biggest pain points for me are JSON, which I have to deal with a lot, and
[lsp-mode](https://github.com/emacs-lsp/lsp-mode). Emacs 27, which I use if I'm not on the nativecomp branch, has better
JSON performance already compared to 26, but sadly lsp-mode is as unusable (for Typescript) in both branches. If there's
something that can be done to improve the performance of it, the solution is not GccEmacs.

## Observed breakages

Here is a short list of things that were broken on my setup:
- ~~[straight.el](https://github.com/raxod502/straight.el) sometimes did not recompile broken versions I was stuck with
  a broken version of some package.~~ This persisted on 27, either this is a problem with straight.el or my own skills
  since it was my own package [chore.el](https://github.com/ration/chore.el). Nevertheless fixed the offending change
  from that (something about dash.el not working through the package).
- magit branch deletion didn't know how to do it also on the remote. The prompt never came up.
- [org-journal](https://github.com/bastibe/org-journal) didn't work. Didn't really ever debug this further (emacs 28
  thing in general or not).

But recently (March 2021) it seems that now the pace of changes on 28 itself has exceeded the pace package maintainers
have been able to fix the breaking changes. When even straight.el gave up, it's time to go back Emacs 27.

## Going back to Emacs 27

Just to have a clean enviroment I removed all installed packages and reinstalled them. Org mode prohibited me from
exiting Emacs 27 due to some deprecated function alias removal:

```elisp
(unless (boundp 'org-clocking-buffer)
  (defalias 'org-clocking-buffer #'org-clock-is-active))
```

I'm not sure whether this is an artifact of packaged org mode and the natively included on or some incompatibility with
Emacs 27. I'm back to a function org-journal again.
