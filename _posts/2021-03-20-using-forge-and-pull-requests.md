---
layout: post
title:  Using Magit Forge with Github Pull Requests
date:   2020-08-11 18:45:30 +0300
tags:   [emacs, github]
---

My git tool of choice is of course [Magit](https://github.com/magit/magit). It has an extension called
[Forge](https://github.com/magit/forge) that can interact with tools like GitHub or Gitlab. While this support is
incomplete (most notably reading and responding to PR comments), it's still very convenient to list,, view and checkout
pull requests.

The setup process for getting the OAuth token setup for forge is a bit tedious, but tl;dr is that create a file `~/.authinfo` with a following row:
```
machine api.github.com login USERNAME^forge password TOKEN
```
Where USERNAME is your user name and TOKEN is your OAuth token created in your Github developer settings page.

Then you can use the Forge menu (or `forge-pull`) in Magit to pull all pull requests, see the required changes and do a
checkout in it if you wish. Full comment support is lacking that I could do the full PR process from it, but maybe one day.

## Why I can only see the pull request headlines, not the changes?

The [RTFM](https://magit.vc/manual/forge.html) says this:

> The first time forge-pull is run in a repository, an entry for that repository is added to the database and a new
> value is added to the Git variable remote.<remote>.fetch, which fetches all
> pull-requests. (+refs/pull/*/head:refs/pullreqs/* for Github)

I'm not sure what step I seem to be missing, but sometimes it doesn't do this for me and I'm left with a neutered /Pull
Requests/ view. It shows the headlines but not the changesets. So if you have this issue, make sure `fetch =
+refs/pull/*/head:refs/pullreqs/*` is in your git config on the remote section.
