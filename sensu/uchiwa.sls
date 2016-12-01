{% from "sensu/pillar_map.jinja" import sensu with context -%}

include:
  - sensu

uchiwa:
  pkg.installed:
    - require:
      - pkgrepo: sensu
  file.serialize:
    - name: /etc/sensu/uchiwa.json
    - formatter: json
    - mode: 644
    - user: uchiwa
    - group: sensu
    - require:
      - pkg: uchiwa
    - dataset:
        sensu:
          {{ sensu.sites }}
        uchiwa:
          {{ sensu.uchiwa }}

  cmd.run:
    - name: setcap 'cap_net_bind_service=+ep' /opt/uchiwa/bin/uchiwa
    - unless: getcap /opt/uchiwa/bin/uchiwa | grep 'cap_net_bind_service+ep'
    - require:
      - pkg: uchiwa
  service.running:
    - enable: True
    - require:
      - file: /etc/sensu/uchiwa.json
    - watch:
      - file: /etc/sensu/uchiwa.json
