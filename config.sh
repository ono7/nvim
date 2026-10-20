#!/usr/bin/env bash

echo ">>>>>>>> removing old neovim configuration files"
rm -rf ~/.config/nvim

echo ">>>>>>>> deploy new neovim configuration"
git clone https://github.com/ono7/nvim.git ~/.config/nvim

echo ">>>>>>>> configure ctags"
rm -rf ~/.ctags.d && ln -sfnv ~/.config/nvim/ctags.d ~/.ctags.d
