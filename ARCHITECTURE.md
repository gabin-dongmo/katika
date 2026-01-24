# Architecture

This document describes the current application architecture for the Katika
codebase.

## Table of contents
1. [Overview](#overview)
2. [Runtime architecture](#runtime-architecture)
3. [Data layer](#data-layer)
4. [API layer](#api-layer)
5. [Main apps](#main-apps)
6. [Per-app breakdown (models, APIs, templates)](#per-app-breakdown-models-apis-templates)
7. [Infrastructure and dev setup](#infrastructure-and-dev-setup)
8. [Cross-cutting concerns](#cross-cutting-concerns)
9. [Key configuration files](#key-configuration-files)

## Overview
- Monolithic Django application built on top of Mezzanine CMS.
- Multiple domain apps live in this repo and are wired through a single Django
  project (`katika`).
- Database is PostgreSQL with PostGIS via GeoDjango.
- API layer is provided by Django REST Framework (DRF) with app-level routers
  and viewsets.
- Frontend is primarily server-rendered templates with shared static assets;
  AngularJS is used in the Incident app and Plotly in the Budget app.

## Runtime architecture
- Entry points:
  - `manage.py` for management commands and dev server.
  - `katika/wsgi.py` for WSGI deployments.
- Routing:
  - `katika/urls.py` composes routes from all domain apps and Mezzanine.
  - Mezzanine URLs are included last to avoid the catch-all page handler
    shadowing custom routes.
- Templates and static assets:
  - Templates are loaded from `templates/` and app template directories.
  - Static files are served from `static/` in development and collected to
    `STATIC_ROOT` in production.

## Data layer
- PostgreSQL + PostGIS configured in `katika/settings.py`.
- GeoDjango is enabled via `django.contrib.gis`.
- Spatial features use `anycluster` and GeoDjango models (see
  `ANYCLUSTER_GEODJANGO_MODEL` in settings).

## API layer
- DRF is installed globally (`rest_framework`) with app-level routers.
- Viewsets and serializers are typically defined inside the app packages:
  - `incident`, `tender`, `jailed` expose REST endpoints.
  - Pagination helpers live in `paginateur`.

## Main apps
Core apps (non-exhaustive):
- `incident`: incidents and geo features, AngularJS frontend.
- `tender`: public contracts and related data.
- `jailed`: incarceration records.
- `budget`: budget data and Plotly charts.
- `covid19`, `transcribe`, `kblog`, `person`, plus support modules such as
  `anycluster` and `paginateur`.

## Per-app breakdown (models, APIs, templates)
### incident
- Models: `IncidentType`, `Tag`, `KeySource`, `Incident` (GeoDjango `PointField`).
- APIs: DRF viewsets at `/incident/api/type` and `/incident/api`.
- Templates: `incident/templates/incident.html`, `incident/templates/add_incident.html`,
  `incident/templates/anybase.html`.
**Features:**
- Incident registry with geo coordinates, dates, descriptions, sources, and impact counts.
- Tagging and incident type taxonomy, plus key source tracking.
- Map-oriented outputs: GeoJSON export, clustering, and aggregation/statistics.
- Admin data entry/editing workflows.

### tender
- Models: `TenderOwner`, `ArmpEntry`, `CDI_CRI`, `Exercice`, `Entreprise`,
  `EntrepriseChange`, `ArmpContract`, `WBProject`, `WBSupplier`, `WBContract`.
- APIs: DRF viewsets at `/tender/api/tenders`, `/tender/api/tender_owners`,
  `/tender/api/contribuables`.
- Templates: `tender/templates/tender/armpentry_list.html`,
  `tender/templates/tender/armpcontract_list.html`,
  `tender/templates/tender/tenderowner_list.html`,
  `tender/templates/tender/entreprise_list.html`,
  `tender/templates/tender/wbcontract_list.html`,
  `tender/templates/titulaire_stats.html`,
  `tender/templates/get_entreprise.html`.  
**Features:**
- Procurement notices directory with full-text search, filters (type/region/year), and sorting.
- Tender owners directory with analytics (counts by owner/region/year).
- Contract tracking and titulaire statistics.
- Tax/enterprise registry (NIU) with change tracking and search.
- World Bank projects and contracts tracking with suppliers.

### jailed
- Models: `Prison`, `IncarcerationTag`, `Judge`, `Incarceration`.
- APIs: DRF viewset at `/jailed/api/incarcerations`.
- Templates: `jailed/templates/jailed.html`, `jailed/templates/add_incarceration.html`.  
**Features:**
- Incarceration registry with dates, prisons, judges, sources, and status flags.
- Tag-based classification and filtering.
- Search, filter, and CSV export of incarceration records.
- Restricted data entry for new records.

### budget
- Models: `Chapitre`, `AnnualEntry`, `BudgetProgramme`.
- APIs: none (server-rendered views only).
- Templates: `budget/templates/budget-global.html`,
  `budget/templates/budget-programme.html`,
  `budget/templates/general.html`,
  `budget/templates/by-department.html`,
  `budget/templates/add_budgetprogramme.html`.  
**Features:**
- Budget exploration by year, region, chapter, and program.
- Aggregated views and visualizations (time series, treemaps, regional breakdowns).
- Admin entry for budget programmes.

### covid19
- Models: `CovidCategory`, `CovidProducer`, `CovidInitiative`, `CovidFund`.
- APIs: none (class-based list/create/update views).
- Templates: `covid19/templates/covid19.html`,
  `covid19/templates/producers.html`,
  `covid19/templates/initiatives.html`,
  `covid19/templates/funds.html`,
  `covid19/templates/update_producer.html`,
  `covid19/templates/update_initiative.html`,
  `covid19/templates/update_fund.html`.  
**Features:**
- Catalog of COVID‑19 producers (products, contacts, regions).
- Registry of initiatives and funds with metadata and dates.
- CRUD workflows for authorized users.

### transcribe
- Models: `Transcript` (Mezzanine `Displayable` + `RichText`).
- APIs: none.
- Templates: `transcribe/templates/transcribe/transcript_list.html`,
  `transcribe/templates/transcript_detail.html`.  
**Features:**
- Publish and browse transcripts with rich content and source links.
- Detail page per transcript.

### kblog
- Models: none local; uses `mezzanine.blog.models.BlogPost`.
- APIs: none.
- Templates: `kblog/templates/blog_index.html`,
  `kblog/templates/blog_detail.html`.  
**Features:**
- Blog listing and detail pages powered by Mezzanine blog posts.

### person
- Models: abstract `Person` base model, used by `jailed`.
- APIs/Templates: none.  
**Features:**
- Shared person schema (names, alias, sex, image) for reuse across apps.

### anycluster
- Models: none local; clustering uses GeoDjango model from settings.
- APIs: `/anycluster/grid/...`, `/anycluster/kmeans/...`,
  `/anycluster/getClusterContent/...`, `/anycluster/getAreaContent/...`.
- Templates: `anycluster/templates/anycluster/clusterPopup.html`.  
**Features:**
- Map clustering services for GeoDjango data (grid, k-means, and cluster details).

### paginateur
- Models: `Pagination` (custom DRF pagination).
- APIs/Templates: none.  
**Features:**
- Shared DRF pagination response format used by API viewsets.

## Infrastructure and dev setup
- Vagrant:
  - `Vagrantfile` provisions an Ubuntu VM, forwards port 8000 -> 8002, and
    runs `install.sh` for dependencies and setup.
- Docker / Docker Compose:
  - `docker-compose.yml` defines `web` (Django) and `db` (PostGIS).
  - `docker-entrypoint.sh` waits for DB, enables PostGIS, runs migrations, and
    optionally populates sample data.
  - `Dockerfile` installs system geo dependencies (GDAL/GEOS/PROJ), Python
    dependencies, and applies a GeoDjango compatibility patch.

## Cross-cutting concerns
- Auth: Django auth + Mezzanine backend, with social OAuth via `social_django`.
- Logging: file-based logging configured in `katika/settings.py`.
- Admin: standard Django admin and Mezzanine admin.

## Key configuration files
- `katika/settings.py`: Django/Mezzanine settings, apps, middleware, DB, DRF.
- `katika/urls.py`: route composition and app inclusion order.
- `Dockerfile`, `docker-compose.yml`, `docker-entrypoint.sh`, `Vagrantfile`.
