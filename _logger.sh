#!/bin/bash 

color_reset=$(tput sgr0)
color_red=$(tput setaf 1)
color_green=$(tput setaf 2)
color_yellow=$(tput setaf 3)
color_blue=$(tput setaf 4)

e_failure() {
  printf "${color_red}🔴  %s${color_reset}" "$@"
  printf "\n"
}

e_pending() {
  printf "${color_yellow}⏳  %s...${color_reset}" "$@"
  printf "\n"
}

e_success() {
  printf "${color_green}🟢  %s${color_reset}" "$@"
  printf "\n"
}

e_message() {
  printf "\n"
  printf "${color_blue}✨  %s${color_reset}" "$@"
  printf "\n"
}
