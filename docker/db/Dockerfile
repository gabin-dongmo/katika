FROM postgis/postgis:13-3.1

# Debian 11 / PGDG en fin de vie (nov. 2026) :
# - bullseye-pgdg déplacé vers apt-archive.postgresql.org (HTTPS, d'où ca-certificates d'abord) ;
# - bullseye-security : index présent mais .deb supprimés (404) → source retirée,
#   tout vient de bullseye main.
# - with_llvm=no : PGXS attend clang-11 (celui du build du serveur) pour le bitcode JIT,
#   absent ici ; le .so suffit pour exécuter kmeans().
RUN sed -i 's|apt.postgresql.org|apt-archive.postgresql.org|' /etc/apt/sources.list.d/pgdg.list \
 && sed -i '/bullseye-security/d' /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && apt-get update \
 && apt-get install -y --no-install-recommends build-essential git postgresql-server-dev-13 \
 && git clone --depth 1 https://github.com/umitanuki/kmeans-postgresql.git /tmp/kmeans \
 && make -C /tmp/kmeans with_llvm=no \
 && make -C /tmp/kmeans with_llvm=no install \
 && apt-get purge -y --auto-remove build-essential git postgresql-server-dev-13 \
 && rm -rf /tmp/kmeans /var/lib/apt/lists/*