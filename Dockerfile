FROM alpine AS builder
ARG nexus_version=3.20.1-01
ARG github_connect_version=2.0.2
RUN apk -U add curl
RUN mkdir /workdir
WORKDIR /workdir
RUN curl https://download.sonatype.com/nexus/3/nexus-${nexus_version}-unix.tar.gz|tar -xz
RUN mv nexus-* nexus && mkdir -p nexus/system/com/larscheidschmitzhermes/${github_connect_version}/
RUN curl -L https://github.com/larscheid-schmitzhermes/nexus3-github-oauth-plugin/releases/download/${github_connect_version}/nexus3-github-oauth-plugin.zip -o /tmp/nexus3-github-oauth-plugin.zip
RUN unzip /tmp/nexus3-github-oauth-plugin.zip && \
    mv nexus3-github-oauth-plugin/${github_connect_version}/nexus3-github-oauth-plugin-${github_connect_version}.jar nexus/system/com/larscheidschmitzhermes/${github_connect_version}/ &&\
    rm -fr nexus3-github-oauth-plugin
RUN echo "reference\:file\:com/larscheidschmitzhermes/${github_connect_version}/nexus3-github-oauth-plugin-${github_connect_version}.jar = 200" >> nexus/etc/karaf/startup.properties
FROM openjdk:8-alpine as runner
RUN adduser -D nexus nexus
COPY --from=builder --chown=nexus:nexus /workdir/ /opt/
COPY assets/entrypoint.sh /usr/local/bin/
USER nexus
VOLUME /opt/sonatype-work
EXPOSE 8081
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/opt/nexus/bin/nexus","run"]
