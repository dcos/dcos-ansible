FROM python:3.7-slim
RUN apt update && apt install -y --no-install-recommends openssh-client && rm -rf /var/lib/apt/lists/*
RUN pip install ansible==2.7.8 jmespath
COPY dcos.yml /dcos_playbook.yml
COPY roles /roles
COPY ansible.cfg /ansible.cfg
