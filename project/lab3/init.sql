kubectl exec -it -n postgresql postgresql-0 -- bash

PGPASSWORD=<pg-password> psql -U postgres -c "CREATE DATABASE lab2;"

PGPASSWORD=<pg-password> psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE lab2 TO postgres;"