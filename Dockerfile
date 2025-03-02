# Use a lightweight Ruby image
FROM ruby:3.0.0-alpine

#Setting argument for gcp credentials
ARG GCP_SERVICE_ACCOUNT_KEY

# Install essential packages and dependencies
RUN apk update && \
    apk add --no-cache build-base postgresql-dev nodejs yarn tzdata git nano redis curl supervisor

# Install Cloud SQL Proxy
RUN wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O /cloud_sql_proxy && \
    chmod +x /cloud_sql_proxy


# Set environment variables for Rails
ENV RAILS_ENV=production
ENV RACK_ENV=production
ENV INSTANCE_CONNECTION_NAME=ror-app-instance:us-east5-c:ror-database-gcp
ENV GOOGLE_APPLICATION_CREDENTIALS=${GCP_SERVICE_ACCOUNT_KEY}

# Set the working directory in the container
WORKDIR /app

# Copy the Gemfile and Gemfile.lock to the container to install dependencies
COPY Gemfile Gemfile.lock ./

# Install bundler and gems
RUN gem install bundler && bundle config set --local without 'development test' && bundle install


# Copy the rest of the application code
COPY . .

# Copy the Supervisor configuration file
COPY supervisord.conf /etc/supervisord.conf

# Replace YOUR_GENERATED_KEY with the key you generated
ENV SECRET_KEY_BASE=d77bae9dd4b0331d80c738cda4c712477a9994f9

# Install Node modules for Rails' frontend assets
RUN yarn install --check-files

# Precompile assets for production
RUN bundle exec rails assets:precompile

# Expose the port your app runs on
EXPOSE 3000

# Start Supervisor, which will manage all services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
