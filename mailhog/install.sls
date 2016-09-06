{%- set mailhog_initscript = salt['pillar.get']('mailhog:initscript', 'salt://mailhog/templates/initscript.jinja') %}
{%- set mailhog_systemdscript = salt['pillar.get']('mailhog:systemdscript', 'salt://mailhog/templates/systemdscript.jinja') %}
{%- set mailhog_version = salt['pillar.get']('mailhog:version', '0.2.0') %}
{%- set mailhog_architecture = salt['pillar.get']('mailhog:architecture', 'linux_amd64') %}
{%- set mailhog_smtp_port = salt['pillar.get']('mailhog:smtp:port', 1025) %}

nullmailer:
  pkg.installed: []
  service.running:
    - enable: True

/etc/nullmailer/remotes:
  file.managed:
    - contents: "localhost smtp --port={{mailhog_smtp_port}}"
    - require:
      - pkg: nullmailer
    - watch:
      - service: nullmailer

/opt/mailhog:
  file.directory: []

download-mailhog:
  cmd.run:
    - name: wget -qO /opt/mailhog/mailhog https://github.com/mailhog/MailHog/releases/download/v{{mailhog_version}}/MailHog_{{mailhog_architecture}} && chmod +x /opt/mailhog/mailhog
    - creates: /opt/mailhog/mailhog
    - requires:
      - file: /opt/mailhog

{% if grains['init'] != 'systemd' -%}
/etc/init.d/mailhog:
  file.managed:
    - source: {{ mailhog_initscript }}
    - template: jinja
    - mode: 755
    - watch_in:
      - service: mailhog
{% else %}
/lib/systemd/system/mailhog.service:
  file.managed:
    - source: {{ mailhog_systemdscript }}
    - template: jinja
    - mode: 755
    - watch_in:
      - service: mailhog
{% endif %}

mailhog:
  service.running:
    - enable: True
    - require:
      - cmd: download-mailhog
      - file: {% if grains['init'] != 'systemd' -%} /etc/init.d/mailhog {% else %} /lib/systemd/system/mailhog.service {% endif %}

