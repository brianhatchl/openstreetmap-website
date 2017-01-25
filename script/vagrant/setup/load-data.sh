#set vagrant db password
VAGRANT_PW='vagrant!'
sudo -u postgres psql -c "alter user vagrant with password '$VAGRANT_PW';"

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

#truncate the api db
osmosis --truncate-apidb host="localhost" database="openstreetmap" \
user="vagrant" password="$VAGRANT_PW" validateSchemaVersion="no"

#create a login user with adminstrator and moderator privs
psql -d openstreetmap -c "INSERT INTO users (email, id, pass_crypt, creation_time, display_name, data_public, pass_salt, creation_ip, languages, status, terms_seen, terms_agreed) VALUES ('vagrant@digitalglobe.com', 1, 'RA0ZBkO9YJBSwx/E3zR1xhYP+CulIg+pMnotvMPpvys=', '2016-12-18 00:00:00', 'vagrant', TRUE, 'sha512!1000!VICMS6PNM8q+Wd3bvoJhBKvspw18ScNC4WRcp3qSje8=', '127.0.0.1', 'en-US,en', 'active', TRUE, '2016-12-18 00:00:00');"
psql -d openstreetmap -c "INSERT INTO user_roles (id, user_id, role, created_at, updated_at, granter_id) VALUES (1, 1, 'administrator', '2016-12-18 00:00:00', '2016-12-18 00:00:00', 1);"
psql -d openstreetmap -c "INSERT INTO user_roles (id, user_id, role, created_at, updated_at, granter_id) VALUES (2, 1, 'moderator', '2016-12-18 00:00:00', '2016-12-18 00:00:00', 1);"

#setup oauth keys
psql -d openstreetmap -c "INSERT INTO client_applications (id, name, url, key, secret, user_id, created_at, updated_at, allow_read_prefs, allow_write_prefs, allow_write_diary, allow_write_api, allow_read_gpx, allow_write_gpx, allow_write_notes) VALUES (1, 'Local iD', 'http://localhost:3000', '7VFoWFC53zIqBY9fLqjaufkumDxFRrjGP2BGayKL', 'hf0kTNizGA5Nr1Q4irwY4lOFI14JRCYbUwXUGD2S', 1, '2016-12-18 00:00:00', '2016-12-18 00:00:00', FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE);"
psql -d openstreetmap -c "INSERT INTO client_applications (id, name, url, key, secret, user_id, created_at, updated_at, allow_read_prefs, allow_write_prefs, allow_write_diary, allow_write_api, allow_read_gpx, allow_write_gpx, allow_write_notes) VALUES (2, 'Local Tasking Manager', 'http://localhost:6543', 'GitGwA0QZ25e8HxaACcRpLJ8QhiwEqHgtedELteG', '32UEYjGMyXZcuHPic8oCjPMhoG4tNwCfIZP1TMOW', 1, '2016-12-18 00:00:00', '2016-12-18 00:00:00', TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE);"

#download the data
if [ ! -f haiti-and-domrep-latest.osm.pbf ]; then
    wget http://download.geofabrik.de/central-america/haiti-and-domrep-latest.osm.pbf
fi

#load into api db
osmosis --read-pbf haiti-and-domrep-latest.osm.pbf \
--bounding-box top=18.549915 left=-72.504972 bottom=18.522925 right=-72.469980 clipIncompleteEntities=true \
--write-apidb host="localhost" database="openstreetmap" user="vagrant" \
password="$VAGRANT_PW" validateSchemaVersion="no"

#update db sequences
psql -d openstreetmap -c "SELECT setval('current_nodes_id_seq', (SELECT max(id) from current_nodes)); SELECT setval('current_ways_id_seq', (SELECT max(id) from current_ways)); SELECT setval('current_relations_id_seq', (SELECT max(id) from current_relations)); SELECT setval('changesets_id_seq', (SELECT max(id) from changesets));"
