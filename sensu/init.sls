{% from "sensu/pillar_map.jinja" import sensu with context %}

{% if grains['os_family'] == 'Debian' %}
python-apt:
  pkg:
    - installed
    - require_in:
      - pkgrepo: sensu
{% endif %}

sensu:
  {% if grains['os_family'] != 'Windows' %}
  pkgrepo.managed:
    - humanname: Sensu Repository
    {% if grains['os_family'] == 'Debian' %}
    - name: deb http://repositories.sensuapp.org/apt sensu main
    - file: /etc/apt/sources.list.d/sensu.list
    - key_url: http://repositories.sensuapp.org/apt/pubkey.gpg
    {% elif grains['os_family'] == 'RedHat' %}
    - baseurl: http://repositories.sensuapp.org/yum/el/$releasever/$basearch/
    - gpgcheck: 0
    - enabled: 1
    {% endif %}
    - require_in:
      - pkg: sensu
  {% endif %}
  {% if grains['os_family'] == 'Windows' and sensu.pkg.use_chocolatey %}
  chocolatey.installed:
    - source: {{ sensu.pkg.chocolatey_repo }}
    - version: {{ sensu.pkg.version }}
  {% else %}
  pkg:
    - installed
  {% endif %}


{% if grains['os_family'] != 'Windows' %}
old sensu repository:
  pkgrepo.absent:
    {% if grains['os_family'] == 'Debian' %}
    - name: deb http://repos.sensuapp.org/apt sensu main
    - keyid: 18609E3D7580C77F # key from http://repos.sensuapp.org/apt/pubkey.gpg
    {% elif grains['os_family'] == 'RedHat' %}
    - name: http://repos.sensuapp.org/yum/el/$releasever/$basearch/
    {% endif %}
    - require_in:
      - pkg: sensu
{% endif %}
