# Base image
FROM python:3.12-slim-bookworm

LABEL \
    name="Lochin" \
    author="Ajin Abraham <ajin25@gmail.com>" \
    maintainer="Ajin Abraham <ajin25@gmail.com>" \
    contributor_1="OscarAkaElvis <oscar.alfonso.diaz@gmail.com>" \
    contributor_2="Vincent Nadal <vincent.nadal@orange.fr>" \
    description="Mobile Security Framework (Lochin) is an automated, all-in-one mobile application (Android/iOS/Windows) pen-testing, malware analysis and security assessment framework capable of performing static and dynamic analysis."

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    Lochin_USER=Lochin \
    USER_ID=9901 \
    Lochin_PLATFORM=docker \
    Lochin_ADB_BINARY=/usr/bin/adb \
    JAVA_HOME=/jdk-22.0.2 \
    PATH=/jdk-22.0.2/bin:/root/.local/bin:$PATH \
    DJANGO_SUPERUSER_USERNAME=Lochin \
    DJANGO_SUPERUSER_PASSWORD=Lochin

# See https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
RUN apt update -y && \
    apt install -y --no-install-recommends \
    android-sdk-build-tools \
    android-tools-adb \
    build-essential \
    curl \
    fontconfig \
    fontconfig-config \
    git \
    libfontconfig1 \
    libjpeg62-turbo \
    libxext6 \
    libxrender1 \
    locales \
    python3-dev \
    sqlite3 \
    unzip \
    wget \
    xfonts-75dpi \
    xfonts-base && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    apt upgrade -y && \
    curl -sSL https://install.python-poetry.org | python3 - && \
    apt autoremove -y && apt clean -y && rm -rf /var/lib/apt/lists/* /tmp/*

ARG TARGETPLATFORM

# Install wkhtmltopdf, OpenJDK and jadx
COPY scripts/dependencies.sh Lochin/Lochin/tools_download.py ./
RUN ./dependencies.sh

# Install Python dependencies
COPY pyproject.toml .
RUN poetry config virtualenvs.create false && \
  poetry lock && \
  poetry install --only main --no-root --no-interaction --no-ansi && \
  poetry cache clear . --all && \
  rm -rf /root/.cache/

# Cleanup
RUN \
    apt remove -y \
        git \
        python3-dev \
        wget && \
    apt clean && \
    apt autoclean && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* > /dev/null 2>&1

# Copy source code
WORKDIR /home/Lochin/Mobile-Security-Framework-Lochin
COPY . .

HEALTHCHECK CMD curl --fail http://host.docker.internal:8000/ || exit 1

# Expose Lochin Port and Proxy Port
EXPOSE 8000 1337

# Create Lochin user
RUN groupadd --gid $USER_ID $Lochin_USER && \
    useradd $Lochin_USER --uid $USER_ID --gid $Lochin_USER --shell /bin/false && \
    chown -R $Lochin_USER:$Lochin_USER /home/Lochin

# Switch to Lochin user
USER $Lochin_USER

# Run Lochin
CMD ["/home/Lochin/Mobile-Security-Framework-Lochin/scripts/entrypoint.sh"]
