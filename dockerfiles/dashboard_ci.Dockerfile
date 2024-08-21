FROM public.ecr.aws/docker/library/ruby:3.2.2-bullseye


RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -

RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list


RUN apt-get update -qq

# Install aws cli
RUN apt-get install -y python3 python3-pip python3-venv
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN pip install awscli

RUN apt-get install -y --no-install-recommends nodejs \
      locales \
      google-chrome-stable \
      yarn

# This is temporary so that we do not use the latest chrome due to an issue in the latest version. Matching the google chrome version in dashboard
# RUN curl -Ss "https://chromedriver.storage.googleapis.com/$(google-chrome --version | grep -Po '\d+\.\d+\.\d+' | tr -d '\n').16/chromedriver_linux64.zip" > /tmp/chromedriver.zip && \
RUN curl -Ss "https://storage.googleapis.com/chrome-for-testing-public/$(google-chrome --version | grep -Po '\d+\.\d+\.\d+\.\d+' | tr -d '\n')/linux64/chromedriver-linux64.zip" > /tmp/chromedriver.zip && \
    unzip /tmp/chromedriver.zip -d /tmp/chromedriver && \
    mv -f /tmp/chromedriver/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver && \
    rm /tmp/chromedriver.zip && \
    rm -r /tmp/chromedriver

RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true
