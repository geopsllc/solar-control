#/usr/bin/env bash

ccontrol_completions () {

  local cur prev

  COMPREPLY=()
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}

  if [ $COMP_CWORD -eq 1 ]; then
    COMPREPLY=( $(compgen -W "install reinstall update remove secret start restart stop status logs snapshot system config rollback" -- $cur) )
  elif [ $COMP_CWORD -eq 2 ]; then
    case "$prev" in
      "install")
        COMPREPLY=( $(compgen -W "core" -- $cur) )
        ;;
      "reinstall")
        COMPREPLY=( $(compgen -W "core" -- $cur) )
        ;;
      "update")
        COMPREPLY=( $(compgen -W "core self check" -- $cur) )
        ;;
      "remove")
        COMPREPLY=( $(compgen -W "core self" -- $cur) )
        ;;
      "secret")
        COMPREPLY=( $(compgen -W "set clear" -- $cur) )
        ;;
      "start"|"stop"|"status"|"logs")
        COMPREPLY=( $(compgen -W "relay forger all" -- $cur) )
        ;;
      "restart")
        COMPREPLY=( $(compgen -W "relay forger all safe" -- $cur) )
        ;;
      "snapshot")
        COMPREPLY=( $(compgen -W "create restore" -- $cur) )
        ;;
      "system")
        COMPREPLY=( $(compgen -W "info update" -- $cur) )
        ;;
      "config")
        COMPREPLY=( $(compgen -W "reset" -- $cur) )
        ;;
      *)
        ;;
    esac
  fi

  return 0

}

complete -F ccontrol_completions ccontrol
