#!/bin/bash

#######################################
#             quitter.sh              #
#      Gestionnaire d'évènements      #
#            Réalisé par :            #
#          SPARTON Alexandre          #
#             MARTIN Hugo             #
#    Publié le 4 janvier 2021 sous    #
#        licence publique GNU         #
#######################################




















BIP='\a'
DATE_PRESENT=$(date +%Y%m%d)
HORAIRE_PRESENT=$DATE_PRESENT$(date +%H%M)
SEPARATEUR="|"
D_CONFIG="${HOME}/.config/quitter"
F_HORAIRES="horaires.db"
F_PID="boucle.pid"
PATH_HORAIRES="$D_CONFIG/$F_HORAIRES"
PATH_PID="$D_CONFIG/$F_PID"

function afficher_aide() {
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
    echo "Utilisation : quitter [[HHMM] | [AAAAMMJJHHMM] Message [+tag1 +tag2]]"
    echo "                      [-a [+tags] [AAAAMMJJHHMM]] [-l [+tags] [AAAAMMJJHHMM]]"
    echo "                      [-r [+tags] [AAAAMMJJHHMM]] [-q] [-h]"
    echo ""
    echo "  ----- Liste des options -----  "
    printf "%-30s" "-a +tags AAAAMMJJHHMM"
    echo "Liste TOUS les rdv avec au moins un des tags et horaires précisés"
    printf "%-30s" "-l +tags AAAAMMJJHHMM"
    echo "Liste les rdv à venir avec au moins un des tags et horaires précisés"
    printf "%-30s" "-r +tags AAAAMMJJHHMM"
    echo "supprime les rdv à venir avec au moins un des tags et horaires précisés"
    printf "%-30s" "-q"
    echo "stop la boucle, et ainsi les notifications des rendez-vous à venir"
    printf "%-30s" "-h"
    echo "Affiche l'aide"
}

# Lance le processus qui alerte des rendez-vous, sauf si celui-ci est déjà en train de tourner
function lancer_boucle() {
    if test -f "$PATH_PID"; then
        pid=$(cat "$PATH_PID")
        if ps -p $pid >/dev/null 2>/dev/null; then
            return 1
        else
            echo "lancement..." >&2
            boucle &
            return 0
        fi
    else
        touch "$PATH_PID" && echo -n "-1" >"$PATH_PID"
        lancer_boucle
    fi
}

# Si l'id du processus est le même, appelle la fonction alerter_rdv et attend la prochaine minute
# Sinon arrête le processus
function boucle() {
    echo "$BASHPID" >"$PATH_PID"
    while [[ $(cat "$PATH_PID") -eq "$BASHPID" ]]; do
        alerter_rdv
        sleep 60
    done
    echo "Boucle arrêtée ! (ID : $BASHPID)"
}

# Teste si l'horaire de chaque rendez-vous est égale à l'horaire courrante
# Si oui, alerte d'un rendez-vous et joue un son
function alerter_rdv() {
    while read ligne; do
        horaire=$(echo $ligne | cut -d"$SEPARATEUR" -f 1)
        if test $horaire -eq $HORAIRE_PRESENT; then
            deserialiser_ligne $ligne
            jouer_son_alerter &
        fi
    done <"$PATH_HORAIRES"
}

# Joue un petit son d'alerte
function jouer_son_alerte() {
    echo -e $BIP
    sleep 0.4
    echo -e $BIP
    sleep 0.8
    echo -e $BIP
    sleep 0.2
    echo -e $BIP
    sleep 0.2
    echo -e $BIP
}

# Stop la boucle en effaçant le PID dans boucle.pid
function arreter_boucle() {
    BOUCLE_PID=$(cat "$PATH_PID")
    if test $BOUCLE_PID -ne "-1"; then
        echo -n "-1" >"$PATH_PID"
        echo "Arrêt de la boucle dans moins d'une minute..."
    else
        echo "Aucune boucle en cours, lancer la boucle ? [O]ui / [N]on"
        read reponse
        case $reponse in
        [Oo][Uu][Ii] | [Oo])
            lancer_boucle &
            return 0
            ;;
        [Nn][Oo][Nn] | [Nn])
            return 0
            ;;
        *)
            "Réponse non reconnue"
            return 1
            ;;
        esac
    fi
}

# Vérifie que la date est un jour existant
function valider_date() {
    jour=$(echo $1 | cut -c7-8)
    mois=$(echo $1 | cut -c5-6)
    annee=$(echo $1 | cut -c1-4)
    date="$mois/$jour/$annee"
    date -d $date &>/dev/null
}

# Vérifie que le nombre d'heures ne dépasse pas 23
function valider_heures() {
    heures=$(echo $1 | cut -c9-10)
    test $heures -le 23
}

# Vérifie que le nombre de minutes ne dépasse pas 59
function valider_minutes() {
    minutes=$(echo $1 | cut -c11-12)
    test $minutes -le 59
}

# Formate un rendez-vous pour le stocker dans horaires.db
function serialiser_ligne() {
    echo "$1$SEPARATEUR$2$SEPARATEUR$3" && return 0
}

# Formate les lignes de rendez-vous pour l'affichage, l'affichage des tags se précise en passant le paramètre --showtags
function deserialiser_ligne() {
    horaire=$(echo $1 | cut -d"$SEPARATEUR" -f 1)
    message=$(echo $1 | cut -d"$SEPARATEUR" -f 2)
    tags=$(echo $1 | cut -d'|' -f 3)
    ligne="$(deserialiser_date $horaire)     $(deserialiser_temps $horaire)     $message"
    test $2 = --showtags && ligne="$ligne     tags : $tags"
    echo "$ligne"
}

# Formate la date pour l'affichage (AAAAMMJJ vers JJ/MM/AAAA)
function deserialiser_date() {
    jour=$(echo $1 | cut -c7-8)
    mois=$(echo $1 | cut -c5-6)
    annee=$(echo $1 | cut -c1-4)
    echo "$jour/$mois/$annee" && return 0
}

# Formate le temps pour l'affichage (HHMM vers HH:MM)
function deserialiser_temps() {
    heures=$(echo $1 | cut -c9-10)
    minutes=$(echo $1 | cut -c11-12)
    echo "$heures:$minutes"
}

# Vérifie qu'une date est située dans le futur.
function rdv_futur() {
    horaire=$1
    test $horaire -gt $HORAIRE_PRESENT && return 0 || echo "Erreur : la date que vous tentez d'ajouter est dans le passé !" && exit 1
}

# Ajoute un rendez-vous avec les horaires , le message et les tags précisés
function ajouter_rdv() {
    horaire=$1 && shift
    tags=""
    message=""
    rdv_futur $horaire && for mot in $@; do
        premier_car=$(echo $mot | cut -c1)
        if test $premier_car = +; then
            tags="$tags$(echo $mot | cut -c2-) "
        else
            message="$message$mot "
        fi
    done
    serialiser_ligne "$horaire" "$message" "$tags" >>$PATH_HORAIRES && echo "Le rendez-vous \"$message\" a été ajouté !" && exit 0 || exit 1
}

# Supprime tous les rendez-vous, ou ceux correspondants aux paramètres.
function supprimer_rdv() {
    while read ligne; do
        for param in $@; do
            premier_car=$(echo $param | cut -c1)
            if test $premier_car = +; then
                tag=$(echo $param | cut -c2-)
                tags=$(echo $ligne | cut -d"$SEPARATEUR" -f 3)
                echo $tags | grep -w $tag &>/dev/null
                if test $? -eq 0; then
                    echo "Rendez-vous supprimé : \"$(echo "$ligne" | cut -d"$SEPARATEUR" -f 2)\""
                    sed -i "/${ligne}/d" $PATH_HORAIRES
                    continue 2 # Passe à la ligne suivante
                fi
            else
                horaire=$(ajuster_date $param)
                marqueur_temps=$(echo $ligne | cut -d"$SEPARATEUR" -f 1)
                valider_date $horaire && valider_heures $horaire && valider_minutes $horaire && echo $marqueur_temps | grep $horaire >/dev/null
                if test $? -eq 0; then
                    echo "Rendez-vous supprimé : \"$(echo "$ligne" | cut -d"$SEPARATEUR" -f 2)\""
                    sed -i "/${ligne}/d" $PATH_HORAIRES
                    continue 2 # Passe à la ligne suivante
                fi
            fi
        done
    done <$PATH_HORAIRES
}

# Transforme une date HHMM en AAAAMMJJHHMM
function ajuster_date() {
    echo $1 | grep '^[0-9][0-9][0-9][0-9]$' &>/dev/null && echo "$DATE_PRESENT$1" || echo $1
}

# Liste tous les rendez-vous, selon les critères passés en paramètre
function lister_tout_rdv() {
    while read ligne; do
        if test $# -eq 0; then
            deserialiser_ligne "$ligne" --showtags
        else
            for param in $@; do
                premier_car=$(echo $param | cut -c1)
                if test $premier_car = +; then
                    tag=$(echo $param | cut -c2-)
                    tags=$(echo $ligne | cut -d"$SEPARATEUR" -f 3)
                    echo $tags | grep -w $tag &>/dev/null
                    if test $? -eq 0; then
                        deserialiser_ligne "$ligne" --showtags
                        continue 2 # Passe à la ligne suivante
                    fi
                else
                    horaire=$(ajuster_date $param)
                    marqueur_temps=$(echo $ligne | cut -d"$SEPARATEUR" -f 1)
                    valider_date $horaire && valider_heures $horaire && valider_minutes $horaire && echo $marqueur_temps | grep $horaire >/dev/null
                    if test $? -eq 0; then
                        deserialiser_ligne "$ligne" --showtags
                        continue 2 # Passe à la ligne suivante
                    fi
                fi
            done
        fi
    done <$PATH_HORAIRES
}

# Liste tous les rendez-vous futurs, selon les critères passés en paramètre
function lister_prochain_rdv() {
    while read ligne; do
        horaire_rdv=$(echo $ligne | cut -d"$SEPARATEUR" -f 1)
        test $horaire_rdv -gt $HORAIRE_PRESENT || continue
        if test $# -eq 0; then
            deserialiser_ligne "$ligne" --showtags
        else
            for param in $@; do
                premier_car=$(echo $param | cut -c1)
                if test $premier_car = +; then
                    tag=$(echo $param | cut -c2-)
                    tags=$(echo $ligne | cut -d"$SEPARATEUR" -f 3)
                    echo $tags | grep -w $tag &>/dev/null
                    if test $? -eq 0; then
                        deserialiser_ligne "$ligne" --showtags
                        continue 2 # Passe à la ligne suivante
                    fi
                else
                    horaire=$(ajuster_date $param)
                    marqueur_temps=$(echo $ligne | cut -d"$SEPARATEUR" -f 1)
                    valider_date $horaire && valider_heures $horaire && valider_minutes $horaire && echo $marqueur_temps | grep $horaire >/dev/null
                    if test $? -eq 0; then
                        deserialiser_ligne "$ligne" --showtags
                        continue 2 # Passe à la ligne suivante
                    fi
                fi
            done
        fi
    done <$PATH_HORAIRES
}

# Regarde le premier paramètre et lance la fonction correspondante
function main() {
    case "$1" in
    [0-9][0-9][0-9][0-9]|[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
        horaire=$(ajuster_date $1)
        valider_date $horaire && valider_heures $horaire && valider_minutes $horaire || (
            echo "Erreur : Horaire inexistant"
            exit 1
        )
        shift
        if test $# -ge 1; then
            lancer_boucle &
            ajouter_rdv $horaire $@
            exit 0
        else
            echo "Erreur : votre rappel n'a pas de contenu ( message [+tags] )"
            exit 1
        fi
        ;;
    -r|--remove)
        shift
        if test $# -ge 1; then
            supprimer_rdv $@
        else
            echo "Vous n'avez pas précisé de critères, souhaitez-vous supprimer tous vos rendez-vous ?"
            read reponse
            case $reponse in
            [Oo][Uu][Ii] | [Oo])
                echo -n "" >$PATH_HORAIRES && echo "Tous vos rendez-vous ont étés supprimés !" && exit 0
                ;;
            *)
                echo "Abandon de l'opération, aucun changement effectué" && exit 0
                ;;
            esac
        fi
        ;;
    -a|--all)
        shift
        lister_tout_rdv $@
        ;;
    -l|--list)
        shift
        lister_prochain_rdv $@
        ;;
    -h|--help)
        afficher_aide
        exit 0
        ;;
    -q|--quit)
        arreter_boucle
        ;;
    *)
        echo "Erreur : option non reconnue"
        ;;
    esac
}

# Vérifie que les dossiers et fichiers de config
# existent, sinon les créé.
function verifier_fichiers() {
    test -d "$D_CONFIG" || mkdir -p "$D_CONFIG"
    test -f "$PATH_HORAIRES" || touch "$PATH_HORAIRES"
    test -f "$PATH_PID" || (touch "$PATH_PID" && echo -n "-1" >"$PATH_PID")
}

# Vérifie que la commande reçoit au moins 1 paramètre
if test $# -ge 1; then
    verifier_fichiers
    main $@
else
    echo "Erreur : Pas d'option, voir l'aide"
    afficher_aide
fi