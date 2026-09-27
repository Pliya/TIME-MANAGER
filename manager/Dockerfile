FROM elixir:1.17.3-otp-27

# ==========================================
# Variables
# ==========================================

ENV MIX_ENV=dev

# ==========================================
# Installer les outils nécessaires
# ==========================================

RUN apt-get update && \
    apt-get install -y \
        postgresql-client \
        nodejs \
        npm \
        inotify-tools \
        && \
    rm -rf /var/lib/apt/lists/*


# ==========================================
# Installer Hex et Rebar
# ==========================================

RUN mix local.hex --force && \
    mix local.rebar --force


# ==========================================
# Dossier de travail
# ==========================================

WORKDIR /app


# ==========================================
# Copier les fichiers de dépendances
# ==========================================

COPY mix.exs mix.lock ./


# ==========================================
# Télécharger les dépendances Elixir
# ==========================================

RUN mix deps.get


# ==========================================
# Copier le reste du projet
# ==========================================

COPY . .


# ==========================================
# Préparer l'entrypoint
# ==========================================

RUN chmod +x /app/entrypoint.sh


# ==========================================
# Port Phoenix
# ==========================================

EXPOSE 4000


# ==========================================
# Lancer l'application
# ==========================================

ENTRYPOINT ["/app/entrypoint.sh"]