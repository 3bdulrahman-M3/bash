#!/bin/bash

DB_DIR="./databases"
mkdir -p "$DB_DIR"

main_menu_items=("Create Database" "List Databases" "Connect To Database" "Drop Database" "Exit")
table_menu_items=("Create Table" "List Tables" "Drop Table" "Insert Data" "Select Data" "Delete Row" "Update Row" "Back")

selected=0

show_menu() {
  local items=("$@")
  clear
  echo "=== Bash DBMS ==="
  for i in "${!items[@]}"; do
    if [[ $i -eq $selected ]]; then
      echo -e "> \e[7m${items[$i]}\e[0m"
    else
      echo "  ${items[$i]}"
    fi
  done
}

handle_input() {
  read -rsn1 input
  if [[ $input == $'\x1b' ]]; then
    read -rsn2 -t 0.1 input
    [[ $input == "[A" ]] && ((selected = (selected - 1 + $1) % $1))
    [[ $input == "[B" ]] && ((selected = (selected + 1) % $1))
  elif [[ $input == "" ]]; then
    return 0
  fi
  return 1
}

pause() {
  read -n1 -p "Press any key to continue..."
}

