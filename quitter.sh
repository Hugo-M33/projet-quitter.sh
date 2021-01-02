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
BOUCLE_PID=$(touch "$CONFIG_DIR"/${PID_FILE} && cat ${CONFIG_DIR}/${PID_FILE})
DATE_PRESENT=$(date +%Y%m%d)

function affiche_aide() {
  echo ""
  echo ' ________  ___  ___  ___  _________  _________  _______   ________      ________  ___  ___ '
  echo '|\   __  \|\  \|\  \|\  \|\___   ___\\___   ___\\  ___ \ |\   __  \    |\   ____\|\  \|\  \ '
  echo '\ \  \|\  \ \  \\\  \ \  \|___ \  \_\|___ \  \_\ \   __/|\ \  \|\  \   \ \  \___|\ \  \\\  \ '
  echo ' \ \  \\\  \ \  \\\  \ \  \   \ \  \     \ \  \ \ \  \_|/_\ \   _  _\   \ \_____  \ \   __  \ '
  echo '  \ \  \\\  \ \  \\\  \ \  \   \ \  \     \ \  \ \ \  \_|\ \ \  \\  \| __\|____|\  \ \  \ \  \ '
  echo '   \ \_____  \ \_______\ \__\   \ \__\     \ \__\ \ \_______\ \__\\ _\|\__\____\_\  \ \__\ \__\ '
  echo '    \|___| \__\|_______|\|__|    \|__|      \|__|  \|_______|\|__|\|__\|__|\_________\|__|\|__| '
  echo '          \|__|                                                           \|_________| '
  echo ""
  echo -e "Quitter est un outil de gestion d'emploi du temps, permettant d'ajouter des rendez-vous\net d'être prévenu 5 minutes avant ainsi qu'à l'heure et la date spécifiée"
  echo ""
  echo "Utilisation : quitter [[HHMM] | [JJ-MM-AAAA_HHMM] Message [+tag1 +tag2]]"
  echo "                      [-a [+tags] [JJ-MM-AAAA_HHMM]] [-l [+tags] [JJ-MM-AAAA_HHMM]]" 
  echo "                      [-r [+tags] [JJ-MM-AAAA_HHMM]] [-q] [-h]"
  echo ""
  echo "  ----- Liste des options -----  "
  printf "%-30s" "-a +tags JJ-MM-AAAA_HHMM"; echo "Liste TOUS les rdv avec au moins un des tags et horaires précisés"
  printf "%-30s" "-l +tags JJ-MM-AAAA_HHMM"; echo "Liste les rdv à venir avec au moins un des tags et horaires précisés"
  printf "%-30s" "-r +tags JJ-MM-AAAA_HHMM"; echo "supprime les rdv à venir avec au moins un des tags et horaires précisés"
  printf "%-30s" "-q"; echo "stop la boucle, et ainsi les notifications des rendez-vous à venir"
  printf "%-30s" "-h"; echo "Affiche l'aide"
}

function arreter_boucle() {
  if [[ $BOUCLE_PID -ne -1 ]]
  then
    echo "-1">"${CONFIG_DIR}"/${PID_FILE}
    echo "Arrêt de la boucle dans moins d'une minute..."
  else
    echo "Aucune boucle en cours, lancer la boucle ? [O]ui / [N]on"
    read reponse
    case $reponse in
    o | O | OUI | oui | Oui)
      lancer_boucle &
      return 0
      ;;
    n | non | N | NON | Non)
      return 0
      ;;
    *)
      "Réponse non reconnue"
      return 1
    esac
  fi
}

function deserialiser_ligne() {
  date=$(deserialiser_date $1)
  temps=$(deserialiser_temps $1)
  chaine_temps="$date $temps"
  message="$2"
  if [[ $# -eq 3 ]]
  then
    tags="$3"
    printf "%35s" "$chaine_temps     "; echo "$message"; echo "        Tags : $tags"; echo " " && return 0
  else
    printf "%35s" "$chaine_temps     "; echo "$message" && return 0
  fi
  
}

function alterter_rdv() {
        marqueur_present=$(date +%Y%m%d_%H%M)
        while read ligne
        do
        marqueur_temps=$(echo $ligne | cut -d'|' -f 1)
        date=${marqueur_temps:0:8}
        temps=${marqueur_temps:9:4}
        let temps_prevenir=$temps-5
        if [[ $date -eq "${marqueur_present:0:8}" ]] && [[ $temps -eq "${marqueur_present:9:4}" ]]
        then
          echo "ALERTE $(echo $ligne | cut -d'|' -f 2)"
          echo -e "\a"
        elif [[ $date -eq "${marqueur_present:0:8}" ]] && [[ $temps_prevenir -eq ${marqueur_present:9:4} ]]
        then
          echo "ATTENTION : \"$(echo $ligne | cut -d'|' -f 2)\" dans 5 minutes"
          echo -e "\a"
        fi
        done <"${CONFIG_DIR}"/${HORAIRES_FILE}
}

function boucle() {
  echo "$BASHPID">"$1"
  while [[ $(head -n 1 "$1") -eq $BASHPID ]]
  do
    alterter_rdv
    sleep 60
  done
  echo "Boucle arrêtée ! (ID : $BASHPID)"
}

function lancer_boucle() {
  fichier_boucle="${CONFIG_DIR}/${PID_FILE}"
  if [[ -f "$CONFIG_DIR"/"$PID_FILE" ]]
  then
    pid=$(cat "$fichier_boucle")
    if ps -p $pid > /dev/null 2> /dev/null
    then
      return 1
    else
      echo "lancement..." >&2
      boucle "$fichier_boucle" &
      return 0
    fi
  else
    touch "$fichier_boucle" && echo "-1">"$fichier_boucle"
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
  echo "${date:6:2} ${mois} ${date:0:4}"
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
  date=${marqueur_temps:0:8}
  temps=${marqueur_temps:9:4}
  temps_present=$(date +%H%M)
  tags=""
  if [ $date -gt $DATE_PRESENT ] || [[ ( $date -eq $DATE_PRESENT ) && ( $temps -gt $temps_present ) ]]
  then
    fichier_horaires="${CONFIG_DIR}"/${HORAIRES_FILE}
    shift
    while [ $# -ge 1 ]
    do
      if [ ${1:0:1} = "+" ]
      then
        tags+="${1:1} "
      else
        message+="$1 "
      fi
      shift
    done
    echo "${marqueur_temps}|${message}|${tags}">>$fichier_horaires
    sort -ro $fichier_horaires $fichier_horaires
    return 0
    
  else
    echo "Erreur, la date est dans le passé." >&2
    return 1
  fi

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
      message="$(echo ${ligne} | cut -d'|' -f 2)"
      tags=$(echo ${ligne} | cut -d'|' -f 3)
      echo "$(deserialiser_ligne $timestamp "$message" "$tags")"
    done <"${CONFIG_DIR}"/"${HORAIRES_FILE}"
  else
    echo "Vous n'avez pas de rendez-vous"
  fi
}

function lister_prochain_rdv() {
  shift
  marqueur_present=$(date +%Y%m%d%H%M)
  rdv_trouve=false
  regex_tag="^\+.*"
  timestamp_regex="[0-3][0-9]-[0-1][0-9]-[0-9]{4}_[0-2][0-9][0-5][0-9]"

  if rdv_existant
  then
    while read ligne
    do
      timestamp=$(echo $ligne | cut -d'|' -f 1)
      message=$(echo $ligne | cut -d'|' -f 2)
      tags=$(echo $ligne | cut -d'|' -f 3)
      if [[ $(echo $timestamp | sed 's/_//') -le $marqueur_present ]]; then continue; fi
      if [ $# -ge 1 ] 
      then
        for critere in $@
        do
          if [[ $critere =~ $regex_tag ]]
          then
            echo "$tags" | grep "${critere:1}" > /dev/null && echo "$(deserialiser_ligne "$timestamp" "$message")" && continue 2
          elif [[ $critere =~ $timestamp_regex ]]
          then
            critere=$(serialiser_temps $critere | sed 's/_//')
            echo "$timestamp" | sed 's/_//' |  grep "$critere" > /dev/null && echo "$(deserialiser_ligne "$timestamp" "$message")" && continue 2
          else
            echo "format $critere non reconnu"
            continue 2
          fi
        done
      else
        echo "$ligne"
      fi
  done <"${CONFIG_DIR}"/"${HORAIRES_FILE}"
  else
    echo "Vous n'avez pas de rendez-vous"
    return 1
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
  -q | --quit)
    arreter_boucle
    ;;
  -l | --list)
    lister_prochain_rdv $@
    ;;
  -a | --all)
    lister_rdv
    ;;
  -r | --remove)
    supprimer_rdv $@
    ;;
  -h | --help)
    affiche_aide
    ;;
  [0-2][0-9][0-6][0-9] | [0-3][0-9]-[0-1][0-9]-[0-9][0-9][0-9][0-9]_[0-2][0-9][0-6][0-9])
    ajouter_rdv $@
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

function main() {
  if [[ "$#" -ge 1 ]]; then
    creer_arborescence
    trouver_mode $@
  else
    echo "Invalid number of args. help ->"
    return 1
  fi
}

main $@
