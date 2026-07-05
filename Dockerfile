# ============================================================================
# Dockerfile - Robot Framework test runner
# Talks to a Selenium Grid via REMOTE_URL - no local browser is installed in
# this image. Includes a headless JRE + the Allure CLI for report generation.
# ============================================================================

FROM python:3.12-slim

WORKDIR /app

ARG ALLURE_VERSION=2.44.0

# Headless JRE (required by the Allure CLI) + curl for the Allure download
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    default-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Install the Allure CLI from its GitHub release tarball (no APT package exists)
RUN curl -fsSL "https://github.com/allure-framework/allure2/releases/download/${ALLURE_VERSION}/allure-${ALLURE_VERSION}.tgz" \
    -o /tmp/allure.tgz \
    && tar -xzf /tmp/allure.tgz -C /opt \
    && ln -s /opt/allure-${ALLURE_VERSION}/bin/allure /usr/local/bin/allure \
    && rm /tmp/allure.tgz

# Install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create output directories
RUN mkdir -p reports/allure-results reports/allure-report screenshots

ENV PYTHONUNBUFFERED=1
ENV REMOTE_URL=""

# Default command: run the smoke suite against the Grid via argfile.robot.
# Override with: docker compose run robot-tests robot <args> <path>
CMD ["robot", "--argumentfile", "argfile.robot", "web", "api"]
