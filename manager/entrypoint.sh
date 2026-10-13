#!/bin/sh

set -e


echo "=========================================="
echo "TIME MANAGER - BACKEND"
echo "=========================================="


echo ""
echo "Configuration PostgreSQL :"
echo "PGHOST=$PGHOST"
echo "PGPORT=$PGPORT"
echo "PGDATABASE=$PGDATABASE"
echo "PGUSER=$PGUSER"
echo ""

echo "Attente de PostgreSQL..."


until pg_isready \
  -h "$PGHOST" \
  -p "$PGPORT" \
  -U "$PGUSER" \
  -d "$PGDATABASE"
do

  echo "PostgreSQL n'est pas encore disponible..."

  sleep 2

done


echo "PostgreSQL est disponible."


echo "Préparation de la base de données..."


mix ecto.create


echo "Application des migrations..."


mix ecto.migrate


echo "Application des seeds (rôles, admin)..."


mix run priv/repo/seeds.exs


echo "=========================================="
echo "Démarrage de Phoenix..."
echo "=========================================="


mix phx.server