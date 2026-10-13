FROM elixir:1.17.3-otp-27

ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}


RUN apt-get update && \
    apt-get install -y \
        postgresql-client \
        nodejs \
        npm \
        inotify-tools \
        && \
    rm -rf /var/lib/apt/lists/*


RUN mix local.hex --force && \
    mix local.rebar --force



WORKDIR /app



COPY mix.exs mix.lock ./
COPY config config



RUN mix deps.get --only ${MIX_ENV} && \
    mix deps.compile



COPY . .


RUN mix compile && \
    chmod +x /app/entrypoint.sh



EXPOSE 4000


ENTRYPOINT ["/app/entrypoint.sh"]