FROM python:3.6-slim-buster

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Debian buster is EOL; point apt at the archive to avoid 404s.
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list \
  && sed -i 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list \
  && sed -i '/buster-updates/d' /etc/apt/sources.list \
  && apt-get -o Acquire::Check-Valid-Until=false update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    gettext \
    gdal-bin \
    libgdal-dev \
    libgeos-dev \
    libjpeg-dev \
    libpq-dev \
    libproj-dev \
    proj-bin \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/
RUN pip install --upgrade "pip<21" "setuptools<58" wheel \
  && pip install -r requirements.txt

# Django 1.11 expects an older GEOS version string format.
RUN sed -i "s/( r\\\\d.*/.*$'/" /usr/local/lib/python3.6/site-packages/django/contrib/gis/geos/libgeos.py

COPY . /app/

ENV GDAL_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/libgdal.so
ENV GEOS_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/libgeos_c.so

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
