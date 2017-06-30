{% from "sensu/pillar_map.jinja" import sensu with context -%}

include:
  - sensu
  - sensu.server

Install python libs:
  pip.installed:
    - pkgs:
      - click
      - purestorage
    - watch_in:
      - service: sensu-server

/opt/sensu/embedded/bin/metrics-pure-storage.py:
  file.managed:
    - source: salt://sensu/files/metrics-pure-storage.py
    - mode: 555
