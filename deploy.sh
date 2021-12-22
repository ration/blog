#!/bin/bash
export JEKYLL_ENV=production bundle exec jekyll build
rsync -crvz --rsh='ssh -p22' --delete-after --delete-excluded  _site/ blog_host:~/www/
