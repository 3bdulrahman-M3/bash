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

create_db() {
  read -p "Enter DB name: " name
  if [[ -d "$DB_DIR/$name" ]]; then
    echo "Database already exists."
  else
    mkdir "$DB_DIR/$name"
    echo "Database '$name' created."
  fi
  pause
}

list_dbs() {
  echo "Databases:"
  ls "$DB_DIR"
  pause
}

drop_db() {
  read -p "Enter DB to delete: " name
  if [[ -d "$DB_DIR/$name" ]]; then
    rm -r "$DB_DIR/$name"
    echo "Deleted $name."
  else
    echo "Database not found."
  fi
  pause
}

connect_db() {
  read -p "Enter DB to connect: " name
  if [[ -d "$DB_DIR/$name" ]]; then
    table_menu "$DB_DIR/$name"
  else
    echo "Database not found."
    pause
  fi
}

table_menu() {
  local db="$1"
  selected=0
  while true; do
    show_menu "${table_menu_items[@]}"
    handle_input ${#table_menu_items[@]} && {
      case $selected in
        0) create_table "$db" ;;
        1) list_tables "$db" ;;
        2) drop_table "$db" ;;
        3) insert_row "$db" ;;
        4) select_data "$db" ;;
        5) delete_row "$db" ;;
        6) update_row "$db" ;;
        7) break ;;
      esac
    }
  done
}

create_table() {
  read -p "Table name: " tname
  tfile="$1/$tname.table"
  if [[ -f "$tfile" ]]; then
    echo "Table already exists!"
    return
  fi
  read -p "Columns (e.g. id:name:email): " cols
  echo "$cols" > "$tfile"
  touch "$1/$tname.data"
  read -p "Primary key column: " pk
  echo "$pk" >> "$tfile"
  echo "Table '$tname' created."
  pause
}

list_tables() {
  echo "Tables:"
  for f in "$1"/*.table; do
    [[ -e "$f" ]] && basename "$f" .table
  done
  pause
}

drop_table() {
  read -p "Table to delete: " t
  rm -f "$1/$t.table" "$1/$t.data" && echo "Deleted $t" || echo "Not found."
  pause
}

insert_row() {
  read -p "Table name: " t
  tfile="$1/$t.table"
  dfile="$1/$t.data"
  if [[ ! -f "$tfile" ]]; then
    echo "Table not found."
    return
  fi
  cols=$(head -n1 "$tfile")
  pk=$(tail -n1 "$tfile")
  IFS=":" read -ra col_arr <<< "$cols"
  read -p "Values ($cols): " input
  IFS=":" read -ra val_arr <<< "$input"
  if [[ ${#col_arr[@]} -ne ${#val_arr[@]} ]]; then
    echo "Column count mismatch!"
    return
  fi

  pk_idx=$(get_index "$pk" "${col_arr[@]}")
  pk_val="${val_arr[$pk_idx]}"

  if grep -q "^$pk_val:" "$dfile"; then
    echo "Primary key value already exists!"
    return
  fi

  echo "$input" >> "$dfile"
  echo "Row inserted."
  pause
}
