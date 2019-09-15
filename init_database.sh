docker-compose up -d db
until psql -h localhost -U postgres -c "\q" &>/dev/null;
do
    echo "Waiting db to come online"
    sleep 1
done
psql -U postgres -h localhost -f ./sql/create_database.sql
psql -U postgres -h localhost study -f ./sql/models.sql


