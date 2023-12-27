#!/bin/bash

# Configuration
max_description_length=50
loader_delay=0.1

# Fonction pour afficher un loader
function show_loader() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while ps a | awk '{print $1}' | grep -q "$pid"; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# Fonction pour afficher le nombre de caractères
function show_char_count() {
  local input="$1"
  local char_count="${#input}"
  printf "\033[36mCaractères saisis : $char_count/$max_description_length \n\033[0m"
}

# Vérifier s'il y a des modifications à commit
if [ -n "$(git status --porcelain)" ]; then
  # Il y a des modifications

  # Récupérer la branche actuelle
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  echo -e "\n\033[33m🟠 Branche actuelle : $current_branch\033[0m"

  # Définir le prompt de sélection (PS3) pour avoir chaque choix sur une ligne
  PS3=$'\033[32m🟢 Choisissez le type de commit 1/2/3/4/5/6 :\033[0m '

  # Liste des types de commit
  commit_types=(
    '✨ feature'
    '📝 feedback'
    '🧰 bugfix'
    '📛 chore'
    '🔋 dep'
    '📘 documentation'
  )

  # Initialisation de la variable pour la boucle
  selected_commit_type=""

  # Boucle pour demander à l'utilisateur de choisir un type de commit
  while [ -z "$selected_commit_type" ]; do
    # Afficher chaque choix sur une nouvelle ligne
    select commit_type in "${commit_types[@]}"
    do
      selected_commit_type="$commit_type"
      break
    done

    # Vérifier si la sélection est valide
    if [ -z "$selected_commit_type" ]; then
      echo -e "\033[31m❌ Veuillez sélectionner un type de commit valide.\033[0m"
    fi
  done

  # Saisie de la description du commit (limitée à max_description_length caractères)
  while true; do
    echo -e "\033[32m🟢 Entrez la description du commit (max $max_description_length caractères) :\033[0m"
    read -r commit_description

    # Afficher le nombre de caractères
    show_char_count "$commit_description"

    # Vérifier la longueur de la description
    if [ ${#commit_description} -gt $max_description_length ]; then
      echo -e "\033[31m❌ La description du commit dépasse la limite de $max_description_length caractères. Veuillez réessayer.\033[0m"
    else
      break
    fi
  done

  # Ajouter les modifications
  git add .

  # Construire le message de commit
  commit_message="[$selected_commit_type] $commit_description"

  # Afficher le message de commit
  echo -e "\033[33m🟠 Message de commit : $commit_message\033[0m"

  # Proposer de faire un commit
  read -p $'\033[32m🟢 Voulez-vous effectuer le commit ? (o/n) : \033[0m' commit_choice

  if [ "$commit_choice" == "o" ]; then
    # Effectuer le commit
    git commit -m "$commit_message" &
    show_loader $!

    # Proposer de pousser
    read -p $'\033[32m🟢 Voulez-vous pousser la branche ? (o/n) : \033[0m' push_choice
    if [ "$push_choice" == "o" ]; then
      # Essayer de pousser
      git push &
      show_loader $!
    else
      echo -e "\033[33m🟠 Le commit a été effectué, mais la branche n'a pas été poussée.\033[0m"
    fi
  else
    echo -e "\033[31m❌ Le commit a été annulé. ❌\033[0m"
  fi
else
  # Aucune modification à commit
  echo -e "\033[31m🔴 Aucune modification à commit\033[0m"
fi
