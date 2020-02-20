FROM alpine
RUN apk --update add gawk
COPY wordfreq.sh /usr/local/bin
CMD /usr/local/bin/wordfreq.sh
