FROM maven:3.6.1-jdk-8-alpine AS builder
ARG nexus_version=3.26.0-04
ARG github_connect_version=3.1.0
ARG nexus_composer_version=0.0.7
RUN apk -U add curl
RUN mkdir /composer
WORKDIR /composer
RUN curl --fail -L https://github.com/sonatype-nexus-community/nexus-repository-composer/archive/composer-parent-${nexus_composer_version}.tar.gz |tar -xz --strip=1
RUN  mvn clean package
RUN mkdir /nexus
WORKDIR /nexus
RUN curl --fail -L https://download.sonatype.com/nexus/3/nexus-${nexus_version}-unix.tar.gz|tar -xz
RUN mv nexus-* nexus && mkdir -p nexus/system/com/larscheidschmitzhermes/${github_connect_version}/
RUN curl --fail -L https://github.com/larscheid-schmitzhermes/nexus3-github-oauth-plugin/releases/download/${github_connect_version}/nexus3-github-oauth-plugin.kar -o nexus/deploy/nexus3-github-oauth-plugin.kar
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
