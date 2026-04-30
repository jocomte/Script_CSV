#!/bin/bash

# Initialisation des variables
NOTE=0
MAX_NOTE=20
NOM_DOSSIER=$(basename "$PWD")
NOM=$(echo $NOM_DOSSIER | cut -d'_' -f1)
PRENOM=$(echo $NOM_DOSSIER | cut -d'_' -f2)

# 1. Vérification de la compilation
make > /dev/null 2>&1
if [ -f "factorielle" ]; then
    NOTE=$((NOTE + 2))
else
    # Si la compilation échoue, la note est de 0
    echo "$NOM,$PRENOM,0" >> note.csv
    exit 0
fi

# 2. Factorielles 1 à 10
CHANCE=1
for i in {1..10}; do
    EXPECTED=$(fact=$i; res=1; while [ $fact -gt 1 ]; do res=$((res * fact)); fact=$((fact - 1)); done; echo $res)
    RESULT=$(./factorielle $i)
    if [ "$RESULT" != "$EXPECTED" ]; then
        CHANCE=0
    fi
done
[ $CHANCE -eq 1 ] && NOTE=$((NOTE + 5))

# 3. Cas particulier : factorielle de 0 
if [ "$(./factorielle 0)" == "1" ]; then
    NOTE=$((NOTE + 3))
fi

# 4. Vérification de la signature exacte 
if grep -q "int factorielle( int number)" main.c; then
    NOTE=$((NOTE + 2))
fi

# 5. Gestion des erreurs de paramètres 
if [ "$(./factorielle)" == "Erreur: Mauvais nombre de parametres" ]; then
    NOTE=$((NOTE + 4))
fi

# 6. Gestion des nombres négatifs 
if [ "$(./factorielle -5)" == "Erreur: nombre negatif" ]; then
    NOTE=$((NOTE + 4))
fi

# --- GESTION DES MALUS ---

# Malus Lignes > 80 caractères 
if grep -q ".\{81,\}" main.c || grep -q ".\{81,\}" header.h; then
    NOTE=$((NOTE - 2))
fi

# Malus Indentation (2 espaces + accolades à la ligne) 

if grep -qE "^ +[^ ]" main.c | grep -qvE "^(  )+"; then
    NOTE=$((NOTE - 2))
fi

# Malus Make clean 
make clean > /dev/null 2>&1
if [ -f "factorielle" ]; then
    NOTE=$((NOTE - 2))
fi

# Malus Fichier Header manquant 
if [ ! -f "header.h" ]; then
    NOTE=$((NOTE - 2))
fi

# Sécurité pour ne pas avoir de note négative
if [ $NOTE -lt 0 ]; then NOTE=0; fi

# 7. Génération du fichier CSV
if [ ! -f "note.csv" ]; then
    echo "Nom, Prénom, Note" > note.csv
fi

# Ajout de la note (on utilise les guillemets simples comme demandé)
echo "'$NOM','$PRENOM', $NOTE" >> note.csv

echo "Correction terminée pour $PRENOM $NOM. Note: $NOTE/20"