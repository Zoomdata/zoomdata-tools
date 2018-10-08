FROM fluent/fluentd:onbuild

#USER root

RUN apk add --update --virtual .build-deps \
        sudo build-base ruby-dev zlib-dev postgresql-dev libc6-compat \
 && apk add --update libpq mariadb-dev \
 && sudo gem install \
        fluent-plugin-elasticsearch \
        fluent-plugin-output-solr \
        fluent-plugin-mongo \
        fluent-plugin-postgres \
        fluent-plugin-mysql \
 && sudo fluent-gem install fluent-plugin-rewrite-tag-filter \
 && apk del .build-deps \
 && rm -rf /var/cache/apk/* \
           /home/fluent/.gem/ruby/2.3.0/cache/*.gem