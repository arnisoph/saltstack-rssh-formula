#!jinja|yaml

{% from 'rssh/defaults.yaml' import rawmap_osfam with context %}
{% set datamap = salt['grains.filter_by'](rawmap_osfam, merge=salt['pillar.get']('rssh:lookup')) %}

{% set chroot_dirs %}

include: {{ datamap.sls_include|default([]) }}
extend: {{ datamap.sls_extend|default({}) }}

rssh:
  pkg:
    - installed
    - pkgs: {{ datamap.pkgs }}
  file:
    - managed
    - name: {{ datamap.config.main.path|default('/etc/rssh.conf') }}
    - source: salt://rssh/files/main
    - mode: 644
    - user: root
    - group: root
    - template: jinja
