#install dependencies
sudo apt-get install pwgen

#set vagrant db password
RAND_PW=$(pwgen -s 16 1)
sudo -u postgres psql -c "alter user vagrant with password '$RAND_PW';"

#download osmosis binary
if [ ! -f bin/osmosis ]; then
    mkdir -p $HOME/bin
    if [ ! -f osmosis-latest.tgz ]; then
      wget --quiet http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.tgz
    fi
    mkdir -p $HOME/bin/osmosis_src
    tar -zxf osmosis-latest.tgz -C $HOME/bin/osmosis_src
    ln -s $HOME/bin/osmosis_src/bin/osmosis $HOME/bin/osmosis
fi

#download the data
if [ ! -f haiti-and-domrep-latest.osm.pbf ]; then
    wget http://download.geofabrik.de/central-america/haiti-and-domrep-latest.osm.pbf
fi

#truncate the api db
osmosis --truncate-apidb host="localhost" database="openstreetmap" \
user="vagrant" password="$RAND_PW" validateSchemaVersion="no"

#load into api db
bin/osmosis --read-pbf haiti-and-domrep-latest.osm.pbf \
--write-apidb host="localhost" database="openstreetmap" user="vagrant" \
password="$RAND_PW" validateSchemaVersion="no"

#update db sequences
psql -d openstreetmap -c "SELECT setval('current_nodes_id_seq', (SELECT max(id) from current_nodes)); SELECT setval('current_ways_id_seq', (SELECT max(id) from current_ways)); SELECT setval('current_relations_id_seq', (SELECT max(id) from current_relations)); SELECT setval('changesets_id_seq', (SELECT max(id) from changesets));"

#create a login
#setup oauth keys
#follow steps here https://github.com/openstreetmap/openstreetmap-website/blob/master/CONFIGURE.md