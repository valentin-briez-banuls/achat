-- Crée les bases de données auxiliaires pour Solid Cache, Queue et Cable
-- La base principale (achat_production) est créée par POSTGRES_DB dans docker-compose.yml

CREATE DATABASE achat_production_cache;
CREATE DATABASE achat_production_queue;
CREATE DATABASE achat_production_cable;

GRANT ALL PRIVILEGES ON DATABASE achat_production_cache TO achat;
GRANT ALL PRIVILEGES ON DATABASE achat_production_queue TO achat;
GRANT ALL PRIVILEGES ON DATABASE achat_production_cable TO achat;
