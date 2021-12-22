---
layout: post
title:  2021-12-22-org-capture-templates
date:   2021-12-22 10:26:03 +0200
title:  Org Capture Templates with Org Files
tags:   [emacs,org-mode]
---

I fiddle with my org mode captures templates a lot. This usually involves customizing (or setting)
[org-capture-templates](https://orgmode.org/manual/Capture-templates.html). I found it hard to visualize the end result
the traditional customize-view, so I wrote a small package that allows you to create an org file that contains all
the templates. [capture-org-template](https://github.com/ration/capture-org-template.el). Allows you to do the following:

```
* Generic TODO
  :PROPERTIES:
  :DESCRIPTION: Generic TODO item in the Inbox
  :KEY:      t
  :TYPE:     entry
  :TARGET:   file+headline "~/Org/todo.org" "Inbox"
  :END:
** TODO %?
* TODO Email
  :PROPERTIES:
  :DESCRIPTION: TODO mu4e emails with a deadline in two days
  :KEY:      P
  :TARGET:   file+olp "~/Org/todo.org" "Inbox"
  :OPTIONS: :empty-lines 1
  :END:
** TODO %:fromname: %a %?
   DEADLINE: %(org-insert-time-stamp (org-read-date nil t "+2d"))
* Add new capture template
  :PROPERTIES:
  :KEY:      M
  :TARGET:   file "~/Org/capture.org"
  :DESCRIPTION: Add new capture template. Prompt for key and description
  :END:
** %^{Capture name}
  %^{KEY}p%^{TARGET|file "~/Org/todo.org"}p%^{DESCRIPTION}p
*** %?
```

This configuration creates 3 templates (main level), "Generic TODO", "TODO Email" and "Add new capture template". The
last one can be used to add more capture templates for example.

While this format should be rather self evident for anyone familiar with capture templates, here is an explanation:
- Root level determines a new template.
- Any levels under the root is the *template* parameter *moved one level up*. Inside the template all [template
  extensions](https://orgmode.org/manual/Template-expansion.html) are freely available.
- *KEY* Property determines capture key.
- *TYPE* Defaults to entry, capture type parameters.
- *TARGET* The [target](https://orgmode.org/manual/Template-elements.html) element.
- *OPTIONS* The properties parameter in org templates.
- *DESCRIPTION* Is just for the org file and discarded.


