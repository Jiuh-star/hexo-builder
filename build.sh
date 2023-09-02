#!/bin/bash

echo
echo "This is a buildah script to build my blog image."
echo "You can check code for details."
echo

set -ex


# Run in unshare mode
if [ "$(id -u)" -ne 0 ]; then
    buildah unshare $0
    exit
fi

# It's not recommended to build image from alpine since there are some python binary wheel
container=$(buildah from docker.io/node:slim)
mnt=$(buildah mount $container)

function safely_exit() {
    echo "Safely exiting."

    buildah unmount $container
    buildah rm $container
}

trap safely_exit EXIT


########################
# Prepare and Settings #
########################

# Maintainer infomation
buildah config --label maintainer="Jiuh.star jiuh.star@gmail.com" $container

# Install python3
buildah run $container -- apt update
buildah run $container -- apt install -y --no-install-recommends python3-minimal python3-pip python3-venv
buildah run $container -- rm -vrf /var/lib/apt/lists/*

# Optional npm mirror if server host in Mainland China
# buildah run $container npm config set registry https://registry.npm.taobao.org


#####################
# Hexo Dependencies #
#####################

# Working directory
buildah config --workingdir /root/hexo $container

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


###########################
# Install Theme Butterfly #
###########################

# Download Butterfly
git clone --branch master --depth 1 https://github.com/jerryc127/hexo-theme-butterfly.git $mnt/root/hexo/themes/butterfly/
buildah run $container -- ls themes/butterfly

# Make Bufferfly as default theme
buildah run $container -- sed -i "s/landscape/butterfly/g" _config.yml
buildah run $container -- rm -f _config.landscape.yml
buildah run $container -- rm -rf themes/landscape

# For easy config manage
buildah run $container cp /root/hexo/themes/butterfly/_config.yml /root/hexo/_config.butterfly.yml

# Template and working directories
mkdir -p hexo
cp -i -b $mnt/root/hexo/_config.yml $PWD/hexo/_config.yml
cp -i -b $mnt/root/hexo/_config.butterfly.yml $PWD/hexo/_config.butterfly.yml
cp -i -r $mnt/root/hexo/scaffolds/ $PWD/hexo/scaffolds/
cp -i -r $mnt/root/hexo/source/ $PWD/hexo/source/


########################
# Install Manager Qexo #
########################

# Working Directory
buildah config --workingdir /root/qexo $container

# Download Qexo
git clone --branch master --depth 1 https://github.com/Qexo/Qexo.git $mnt/root/qexo/
buildah run $container -- ls

# Create virtual environment since Debian doesn't like we directly pip install
buildah run $container -- python3 -m venv venv

# Hot fix PyYAML=6.0.0 build failed with cython~=3.0
buildah run $container -- venv/bin/pip3 install 'Cython<3.0' PyYAML --no-build-isolation

# Hot fix for missing configs.py
buildah copy $container hotfix/configs.py

# Install dependencies (Hot fix: name mysql -> msyql)
buildah run $container -- venv/bin/pip3 install -r requirements_withoutmsyql.txt

# Make migrations
buildah run $container -- venv/bin/python3 manage.py makemigrations
buildah run $container -- venv/bin/python3 manage.py migrate

# Persistent database
mkdir -p qexo
cp -i -b $mnt/root/qexo/db.sqlite3 $PWD/qexo/db.sqlite3

# Clean cache
buildah run $container -- venv/bin/pip3 cache purge


#################################
# Install Comment Server Twikoo #
#################################

buildah config --workingdir /root/twikoo $container

# Download Twikoo
buildah run $container -- npm install --omit=dev tkserver@latest --save

# Create data directory
buildah run $container -- mkdir -p data
mkdir -p twikoo

# Clear cache
buildah run $container -- npm cache clean -f


################
# Build Finish #
################

# Expose port and cmd
buildah config --workingdir /root $container
buildah config --cmd '/bin/bash' $container

# Done
buildah commit $container hexo-blog

