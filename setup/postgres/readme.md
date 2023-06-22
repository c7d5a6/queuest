``` bash
docker run -it --rm -v "$(pwd)/setup/postgres/flyway-migration:/flyway/sql" --network="host" flyway/flyway:7.2.0 -url=jdbc:postgresql://localhost:5432/queuest -user=queuest -password=queuest migrate
```
