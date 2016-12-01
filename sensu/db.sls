Need python-pip pkg:
  pkg.installed:
    - name: python-pip

Install influxdb pip pkg:
  pip.installed:
    - name: influxdb

Create the sensu influxdb database:
  influxdb_database.present:
    - name: "{{ pillar.sensu.db.db_name }}"
    - host: "localhost"

Create the sensu influxdb user account:
  influxdb_user.present:
    - name: "{{ pillar.sensu.db.username }}"
    - passwd: "{{pillar.sensu.db.password }}"
    - database: "{{ pillar.sensu.db.db_name }}"
