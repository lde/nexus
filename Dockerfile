FROM maven:3.6.1-jdk-8-alpine AS builder
ARG nexus_version=3.22.1-02
ARG github_connect_version=2.0.2
ARG nexus_composer_version=0.0.3
RUN apk -U add curl
RUN mkdir /composer
WORKDIR /composer
RUN curl -L https://github.com/sonatype-nexus-community/nexus-repository-composer/archive/composer-parent-${nexus_composer_version}.tar.gz |tar -xz --strip=1
RUN  mvn clean package
RUN mkdir /nexus
WORKDIR /nexus
RUN curl -L https://download.sonatype.com/nexus/3/nexus-${nexus_version}-unix.tar.gz|tar -xz
RUN mv nexus-* nexus && mkdir -p nexus/system/com/larscheidschmitzhermes/${github_connect_version}/
RUN curl -L https://github.com/larscheid-schmitzhermes/nexus3-github-oauth-plugin/releases/download/${github_connect_version}/nexus3-github-oauth-plugin.zip -o /tmp/nexus3-github-oauth-plugin.zip
RUN unzip /tmp/nexus3-github-oauth-plugin.zip && \
    mv nexus3-github-oauth-plugin/${github_connect_version}/nexus3-github-oauth-plugin-${github_connect_version}.jar nexus/system/com/larscheidschmitzhermes/${github_connect_version}/ &&\
    rm -fr nexus3-github-oauth-plugin
RUN echo "reference\:file\:com/larscheidschmitzhermes/${github_connect_version}/nexus3-github-oauth-plugin-${github_connect_version}.jar = 200" >> nexus/etc/karaf/startup.properties
RUN mkdir -p nexus/system/org/sonatype/nexus/plugins/nexus-repository-composer/${nexus_composer_version}
RUN cp /composer/nexus-repository-composer/target/nexus-repository-composer-${nexus_composer_version}.jar nexus/system/org/sonatype/nexus/plugins/nexus-repository-composer/${nexus_composer_version}/
RUN sed -i  '/<feature prerequisite="true" dependency="false">wrap<\/feature>.*/a <feature prerequisite="false" dependency="false">nexus-repository-composer</feature>' /nexus/nexus/system/org/sonatype/nexus/assemblies/nexus-core-feature/${nexus_version}/nexus-core-feature-${nexus_version}-features.xml
RUN sed -i "/<\/features>.*/i <feature name=\"nexus-repository-composer\" description=\"org.sonatype.nexus.plugins:nexus-repository-composer\" version=\"${nexus_composer_version}\">\n<details>org.sonatype.nexus.plugins:nexus-repository-composer</details>\n<bundle>mvn:org.sonatype.nexus.plugins/nexus-repository-composer/${nexus_composer_version}</bundle>\n</feature>" /nexus/nexus/system/org/sonatype/nexus/assemblies/nexus-core-feature/${nexus_version}/nexus-core-feature-${nexus_version}-features.xml
FROM openjdk:8-alpine as runner
RUN adduser -D nexus nexus
COPY --from=builder --chown=nexus:nexus /nexus/ /opt/
COPY assets/entrypoint.sh /usr/local/bin/
USER nexus
VOLUME /opt/sonatype-work
EXPOSE 8081
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/opt/nexus/bin/nexus","run"]
