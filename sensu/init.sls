{% from "sensu/pillar_map.jinja" import sensu with context %}
{% from "sensu/repos_map.jinja" import repos with context -%}

{% if grains['os_family'] == 'Debian' %}
python-apt:
  pkg:
    - installed
    - require_in:
      - pkgrepo: sensu
sensu_var_run_dir:
  file.directory:
    - name: /var/run/sensu
    - user: sensu
    - group: sensu
    - mode: 755
    - makedirs: True
    - require:
      - pkg: sensu
{% endif %}

sensu:
  {% if repos.get('enabled') %}
  pkgrepo.managed:
    - humanname: Sensu Repository
    {%- if grains['os_family'] == 'Debian' %}
    - name: {{ repos.get('name') }}
    - file: /etc/apt/sources.list.d/sensu.list
    - clean_file: true
    {%- if repos.get('key_url') %}
    - key_url: {{ repos.get('key_url') }}
    {%- endif %}
    {%- elif grains['os_family'] == 'RedHat' %}
    - baseurl: {{ repos.get('baseurl') }}
    - gpgcheck: {{ repos.get('gpgcheck') }}
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
