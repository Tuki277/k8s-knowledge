kubectl exec -it -n postgresql postgresql-0 -- bash

PGPASSWORD=U2sUQ06H2zS09vZ8 psql -U postgres -c "CREATE DATABASE lab2;"

PGPASSWORD=U2sUQ06H2zS09vZ8 psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE lab2 TO postgres;"