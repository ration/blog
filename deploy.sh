#!/bin/bash
JEKYLL_ENV=production bundle exec jekyll build
rsync -crvz --rsh='ssh -p22' --delete-after --delete --exclude "tt" --exclude "other" _site/ blog_host:~/www/
