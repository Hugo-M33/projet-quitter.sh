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

set -e

CONFIG_DIR="${HOME}/.config/quitter"
HORAIRES_FILE="horaires.db"
PID_FILE="boucle.pid"
DATE_PRESENT=$(date +%Y%m%d)

function alterter_rdv() {
        marqueur_present=$(date +%Y%m%d_%H%M)
        while read ligne
        do
        marqueur_temps=$(echo $ligne | cut -d'|' -f 1)
        if [ "${marqueur_temps:0:8}" -eq "${marqueur_present:0:8}" ] && [ "${marqueur_temps:9:4}" -eq "${marqueur_present:9:4}" ]
        then
          echo "ALERTE $(echo $ligne | cut -d'|' -f 2)"
        fi
        done <"${CONFIG_DIR}"/${HORAIRES_FILE}
}

function boucle() {
  echo "$$">"$1"
  while [[ $(head -n 1 "$1") -eq $$ ]]
  do
    echo "tour de boucle..." >&2
    alterter_rdv
    sleep 30
  done
}

function lancer_boucle() {
  fichier_boucle="${CONFIG_DIR}/${PID_FILE}"
  if [[ -f "$CONFIG_DIR"/"$PID_FILE" ]]
  then
    pid=$(cat "$fichier_boucle")
    if ps -p $pid > /dev/null
    then
      return 1
    else
      echo "lancement..." >&2
      boucle "$fichier_boucle" &
      return 0
    fi
  else
    touch "$fichier_boucle"
    lancer_boucle
  fi
    
}




function deserialiser_date() {
  date=$(echo "$1" | cut -d'_' -f 1)
  numero_mois=${date:4:2}
  case "$numero_mois" in
  01)
    mois="Janvier"
    ;;
  02)
    mois="Février"
    ;;
  03)
    mois="Mars"
    ;;
  04)
    mois="Avril"
    ;;
  05)
    mois="Mai"
    ;;
  06)
    mois="Juin"
    ;;
  07)
    mois="Juillet"
    ;;
  08)
    mois="Août"
    ;;
  09)
    mois="Septembre"
    ;;
  10)
    mois="Octobre"
    ;;
  11)
    mois="Novembre"
    ;;
  12)
    mois="Décembre"
    ;;
  esac
  echo "${date:6:2} ${mois} ${date:0:4}  "
}

function serialiser_temps() {
  case "$1" in
  #format 1245 = aujourd'hui 12h45
  [0-2][0-9][0-5][0-9])
    marqueur_temps="${DATE_PRESENT}_${1}"
    echo $marqueur_temps
    return 0
    ;;
  #format 24-05-2017/1445 ou 24052017/1445 = 24 mai 2017 14h45
  *)
    marqueur_temps=$(echo ${1} | sed 's/-//g')
    jour=${marqueur_temps:0:2}
    mois=${marqueur_temps:2:2}
    annee=${marqueur_temps:4:4}
    temps=${marqueur_temps:9:4}
    marqueur_temps="${annee}${mois}${jour}_${temps}"
    date_a_tester="${mois}/${jour}/${annee}"
    date -d "$date_a_tester" 1>/dev/null 2>/dev/null
    if [[ "$?" -eq 0 ]]; then
      echo $marqueur_temps
      return 0
    else
      echo "Date incorrecte" 1>&1
      exit 1
    fi
    ;;
  esac
}

function ajouter_rdv() {
  marqueur_temps=$(serialiser_temps "$1")
  shift
  echo "${marqueur_temps}|${*}" >>"${CONFIG_DIR}"/${HORAIRES_FILE}

}

function rdv_existant() {
  if [[ -s "${CONFIG_DIR}"/"${HORAIRES_FILE}" ]]; then
    return 0
  else
    return 1
  fi
}

function heures_valide() {
  if [[ $1 -ge 24 ]]; then
    return 1
  else
    return 0
  fi
}

function minutes_valide() {
  if [[ $1 -ge 60 ]]; then
    return 1
  else
    return 0
  fi
}

function deserialiser_temps() {
  echo "${1:9:2} heures ${1:11:2} minutes"

}

function lister_rdv() {
  if rdv_existant -eq 0; then
    echo "###############################"
    echo "###     Vos rendez-vous     ###"
    echo "###############################"
    while read ligne; do
      timestamp=$(echo ${ligne} | cut -d'|' -f 1)
      date=$(deserialiser_date ${timestamp})
      temps=$(deserialiser_temps ${timestamp})
      echo "${date} ${temps}     $(echo ${ligne} | cut -d'|' -f 2)"
    done <"${CONFIG_DIR}"/"${HORAIRES_FILE}"
  else
    echo "Vous n'avez pas de rendez-vous"
  fi
}

function lister_prochain_rdv() {
  marqueur_present=$(date +%Y%m%d%H%M)
  rdv_trouve=false
  if rdv_existant -eq 0; then
    while read ligne; do
      timestamp=$(echo ${ligne} | cut -d'|' -f 1 | sed 's/_//')
      if [[ $timestamp -ge $marqueur_present ]]
      then
        if [[ $rdv_trouve == false ]]; then
          echo "###############################"
          echo "### Vos rendez-vous a venir ###"
          echo "###############################"
          rdv_trouve=true
        fi
        affichage_temps=$(printf "%-20s %-25s" "$(deserialiser_date ${timestamp})" "$(deserialiser_temps ${timestamp})")
        contenu=$(echo ${ligne} | cut -d'|' -f 2)
        printf "%-45s|%50s\n" "$affichage_temps" "$contenu" 
        #echo "${date} ${temps}     $(echo ${ligne} | cut -d'|' -f 2)"
      fi

    done <"${CONFIG_DIR}"/"${HORAIRES_FILE}"
    if [[ $rdv_trouve == false ]]; then
      echo "Vous n'avez pas de rendez-vous à venir"
    fi
  else
    echo "Vous n'avez pas de rendez-vous"
  fi
}

function supprimer_rdv() {
  shift
  while [[ $# -ge 1 ]]; do
    if [[ $1 == \+* ]]
    then
    grep "${1}" "${CONFIG_DIR}"/${HORAIRES_FILE} || echo "Pas de rdv correspondant au tag \"$1\""
    sed -i "/${1}/d" "${CONFIG_DIR}"/${HORAIRES_FILE}
    elif [[ $1 =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}_[0-9]{4} ]]
    then 
    marqueur_temps=$(serialiser_temps $1)
    grep "${marqueur_temps}" "${CONFIG_DIR}"/${HORAIRES_FILE} || echo "Pas de rdv correspondant à cette date \"$1\""
    sed -i "/${marqueur_temps}/d" "${CONFIG_DIR}"/${HORAIRES_FILE}
    else
    echo "\"$1\" n'est pas un tag ou une date valide" >&2
    fi
    shift
  done
}

##################################################################
# Cette fonction regarde le premier paramètre pour savoir quelle #
# fonction appeler pour réaliser l'action et renvoie 0, si le    #
# mode n'existe pas, la fonction renvoie l'aide et une erreur (1)#
##################################################################
function trouver_mode() {
  case "$1" in
  -q)
    echo "TODO fonction arreter boucle"
    ;;
  -l)
    lister_prochain_rdv
    ;;
  -a)
    lister_rdv
    ;;
  -r)
    supprimer_rdv "$@"
    ;;
  -h)
    echo "TODO afficher aide"
    ;;
  [0-2][0-9][0-6][0-9] | [0-3][0-9]-[0-1][0-9]-[0-9][0-9][0-9][0-9]_[0-2][0-9][0-6][0-9])
    ajouter_rdv "$@"
    lancer_boucle &
     exit 0
    ;;
  *)
    echo "TODO option non reconnue afficher help"
    ;;
  esac
}

# Cette fonction sert à créer le dossier s'il n'existe pas

function creer_arborescence() {
  if [[ -d "${CONFIG_DIR}" ]]; then
    return 0
  else
    mkdir -p "${CONFIG_DIR}"
  fi
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

if [[ "$#" -ge 1 ]]; then
  creer_arborescence
  trouver_mode "$@"
else
  echo "Invalid number of args. help ->"
fi
