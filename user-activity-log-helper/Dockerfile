# or v0.14-onbuild if not using fluent-plugin-postgres
FROM fluent/fluentd:v0.12-onbuild

USER root

# below RUN includes plugin as examples elasticsearch is not required
# you may customize including plugins as you wish

RUN apk add --update --virtual .build-deps \
        sudo build-base ruby-dev zlib-dev postgresql-dev libc6-compat \
 && apk add --update --virtual libpq \
 && sudo gem install \
        fluent-plugin-elasticsearch \
        fluent-plugin-output-solr \
        fluent-plugin-mongo \
        fluent-plugin-postgres \
 && sudo fluent-gem install fluent-plugin-rewrite-tag-filter \
 && sudo gem sources --clear-all \
 && apk del .build-deps \
 && rm -rf /var/cache/apk/* \
           /home/fluent/.gem/ruby/2.3.0/cache/*.gem