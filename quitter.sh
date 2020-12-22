#!/bin/bash
#######################################
#             quitter.sh              #
#      Gestionnaire d'évènements      #
#            Réalisé par :            #
#          SPARTON Alexandre          #
#             MARTIN Hugo             #
#######################################

# ________  ___  ___  ___  _________  _________  _______   ________      ________  ___  ___
#|\   __  \|\  \|\  \|\  \|\___   ___\\___   ___\\  ___ \ |\   __  \    |\   ____\|\  \|\  \
#\ \  \|\  \ \  \\\  \ \  \|___ \  \_\|___ \  \_\ \   __/|\ \  \|\  \   \ \  \___|\ \  \\\  \
# \ \  \\\  \ \  \\\  \ \  \   \ \  \     \ \  \ \ \  \_|/_\ \   _  _\   \ \_____  \ \   __  \
#  \ \  \\\  \ \  \\\  \ \  \   \ \  \     \ \  \ \ \  \_|\ \ \  \\  \| __\|____|\  \ \  \ \  \
#   \ \_____  \ \_______\ \__\   \ \__\     \ \__\ \ \_______\ \__\\ _\|\__\____\_\  \ \__\ \__\
#    \|___| \__\|_______|\|__|    \|__|      \|__|  \|_______|\|__|\|__\|__|\_________\|__|\|__|
#          \|__|                                                           \|_________|


CONFIG_DIR="~/.config/quitter"
HORAIRES_FILE="horaires.db"
PID_FILE="boucle.pid"


##################################################################
# Cette fonction regarde le premier paramètre pour savoir quelle #
# fonction appeler pour réaliser l'action et renvoie 0, si le    #
# mode n'existe pas, la fonction renvoie l'aide et une erreur (1)#
##################################################################
function trouver_mode()
{
  case "$1" in 
    -q)
      echo "TODO fonction arreter boucle" ;;
    -l)
      echo "TODO fonction lister RDV à venir" ;;
    -a)
      echo "TODO fonction lister tout RDV" ;;
    -r)
      echo "TODO supprimer fonction à l'heure / tag précisée" ;;
    -h)
      echo "TODO afficher aide" ;;
    [0-9][0-9][0-9][0-9] | [0-9]-[0-9]-[0-9]-[0-9]-[0-9]-[0-9]-[0-9]-[0-9]/[0-9][0-9][0-9][0-9])
      echo "TODO fonction ajouter RDV" ;;
    *)
      echo "TODO option non reconnue afficher help" ;;
  esac
}

###################################################################
# Cette fonction affiche le mode d'emploi du programme quitter    #
###################################################################



########################################
# Cette fonction sert à déterminer si  #
# nombre de paramètre est bon, sinon   #
# le programme plante (1) et affiche   #
# l'aide.                              #
########################################

if test "$#" -ge 1 && test "$#" -le 3
then  
  trouver_mode $1
else
  echo "Invalid number of args. help ->"
fi
