FROM debian:bullseye-slim

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-pip curl wget git bash gnupg2 \
    build-essential zlib1g-dev libpq-dev libpcap-dev \
    libsqlite3-dev autoconf bison libssl-dev libyaml-dev \
    libreadline6-dev libncurses5-dev libffi-dev libxml2-dev \
    libxslt1-dev postgresql postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Ruby via apt (Metasploit requires Ruby 2.7+)
RUN apt-get update && apt-get install -y ruby ruby-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Metasploit Framework using Rapid7's installer
RUN curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && \
    chmod +x msfinstall && \
    ./msfinstall && \
    rm msfinstall

# Install Trivy
RUN wget https://github.com/aquasecurity/trivy/releases/download/v0.54.1/trivy_0.54.1_Linux-ARM64.tar.gz && \
    tar -xzf trivy_0.54.1_Linux-ARM64.tar.gz && \
    mv trivy /usr/local/bin/trivy && \
    chmod +x /usr/local/bin/trivy && \
    rm trivy_0.54.1_Linux-ARM64.tar.gz

# Install Bandit
RUN pip3 install bandit==1.7.9

# Install Python dependencies
RUN pip3 install fastapi[all]==0.115.0 uvicorn==0.30.6 requests==2.32.3 pygithub==2.4.0 langchain==0.3.0

# Health check
RUN echo '#!/bin/bash\ncurl -f http://localhost:8000 || exit 1' > /healthcheck.sh && \
    chmod +x /healthcheck.sh

# Set PATH for Metasploit
ENV PATH="/opt/metasploit-framework/bin:${PATH}"

# Debug: Verify tools
RUN which msfconsole && msfconsole --version || echo "msfconsole not installed" && \
    which trivy && trivy --version || echo "trivy not installed" && \
    which bandit && bandit --version || echo "bandit not installed"

WORKDIR /app
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
HEALTHCHECK CMD ["/healthcheck.sh"]