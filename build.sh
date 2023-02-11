#!/bin/bash

# Generator: Hexo
# Theme: Butterfly

# set -ex
set -e

# Run in unshare mode
if [ "$(id -u)" -ne 0 ]; then
    buildah unshare $0
    exit
fi

container=$(buildah from docker.io/node:alpine)
mnt=$(buildah mount $container)

function safely_exit() {
    echo "Safely exiting."

    buildah unmount $container
    buildah rm $container
}

trap safely_exit EXIT

# Maintainer infomation
buildah config --label maintainer="Jiuh.star jiuh.star@gmail.com" $container

# Working directory
buildah config --workingdir /root/hexo $container

# Install bash
buildah run $container apk add --no-cache bash

# Npm mirror
buildah run $container npm config set registry https://registry.npm.taobao.org

# Install hexo-cli
buildah run $container -- npm install hexo-cli -g

# Initiate hexo blog
buildah run $container hexo init .

# Butterfly dependencies
buildah run $container -- npm install hexo-renderer-pug --save
buildah run $container -- npm install hexo-renderer-stylus --save

# Sitemap for SEO
buildah run $container -- npm install hexo-generator-sitemap --save

# Add nofollow for external link, optimization for SEO
buildah run $container -- npm install hexo-filter-nofollow --save

# Feed
buildah run $container -- npm install hexo-generator-feed --save

# Abbr link for short url
buildah run $container -- npm install hexo-abbrlink --save

# Better Markdown parser
buildah run $container -- npm uninstall hexo-renderer-marked --save
buildah run $container -- npm install hexo-renderer-markdown-it --save
buildah run $container -- npm install katex @renbaoshuo/markdown-it-katex --save
buildah run $container -- npm install markdown-it-todo --save
buildah run $container -- npm install markdown-it-toc-done-right --save
buildah run $container -- npm install markdown-it-anchor --save

# Search support
buildah run $container -- npm install hexo-generator-search --save

# Word count
buildah run $container -- npm install hexo-wordcount --save

# Clean cache
buildah run $container -- npm cache clean -f

# Download Butterfly
git clone --branch master --depth 1 https://github.com/jerryc127/hexo-theme-butterfly.git $mnt/root/hexo/themes/butterfly/

# Make Bufferfly as default theme
buildah run $container -- sed -i "s/landscape/butterfly/g" _config.yml
buildah run $container -- rm _config.landscape.yml
buildah run $container -- rm -r themes/landscape

# For easy update
buildah run $container cp /root/hexo/themes/butterfly/_config.yml /root/hexo/_config.butterfly.yml

# Template and working directories
cp -i -b $mnt/root/hexo/_config.yml $PWD/_config.yml
cp -i -b $mnt/root/hexo/_config.butterfly.yml $PWD/_config.butterfly.yml
cp -i -r $mnt/root/hexo/scaffolds/ $PWD/scaffolds/
cp -i -r $mnt/root/hexo/source/ $PWD/source/

# Expose port and cmd
buildah config --port 4000 $container
buildah config --cmd '/bin/bash' $container

# Done
buildah commit $container hexo-butterfly

