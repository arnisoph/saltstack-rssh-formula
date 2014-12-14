{#
  The following is very old legacy code and should be rewritten from scratch.
  User mgmt may belong to the users formula. Quota mgmt may belong to the
  quota formula. There is no automatic chroot/ jail setup here.
#}


/usr/lib/rssh/rssh_chroot_helper:
  file.managed:
    - mode: 4755 {# Hack #}
    - user: root
    - group: root
    - require:
      - pkg: rssh

{#TODO require state quota: #}

{% for user in salt['pillar.get']('chrootusers') %}
sysuser-{{ user['name'] }}:
  group.present:
    - name: {{ user['name'] }}
    - system: false
  user.present:
    - name: {{ user['name'] }}
    - home: /var/chroot/home/{{ user['name'] }}
    - shell: /usr/bin/rssh
    - gid: {{ user['group'] }}
    - groups:
      - "{{ user['name'] }}"
    - require:
      - group: sysuser-{{ user['name'] }}
      - group: sysgroup-{{ user['group'] }}

/var/chroot/home/{{ user['name'] }}:
  file.directory:
    - user: {{ user['name'] }}
    - group: {{ user['name'] }}
    - mode: 700
    - require:
      - user: sysuser-{{ user['name'] }}

sshpubkeys_{{ user['name'] }}:
  ssh_auth.present:
    - user: {{ user['name'] }}
    - config: /var/chroot/home/{{ user['name'] }}/.ssh/authorized_keys
    - names:
  {% for key in user['pubkeys'] %}
      - {{ key }}
  {% endfor %}
    - require:
      - user: sysuser-{{ user['name'] }}
{% endfor %}

{% for customergroup in salt['pillar.get']('quota:groups') %}
sysgroup-{{ customergroup['name'] }}:
  group.present:
    - name: {{ customergroup['name'] }}
    - system: false

setquota-{{ customergroup['name'] }}:
  cmd.run:
    - name: '/usr/sbin/setquota -g {{ customergroup['name'] }} 0 {{ customergroup['quota'] * 1024 * 1024 }} 0 0 /'
    - order: last
    {# TODO: onlyif? #}
{% endfor %}
