# Use a lightweight Ruby image
FROM ruby:3.0.0-alpine

# Install essential packages and dependencies
RUN apk update && \
    apk add --no-cache build-base postgresql-dev nodejs yarn tzdata git nano redis curl supervisor

# Install Cloud SQL Proxy
RUN wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O /cloud_sql_proxy && \
    chmod +x /cloud_sql_proxy


# Set environment variables for Rails
ENV RAILS_ENV=production
ENV RACK_ENV=production
ENV INSTANCE_CONNECTION_NAME=ror-deployment:asia-south1:ror-database-gcp

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
ENV SECRET_KEY_BASE=078c24e85f1ef9b22cbec893657d65830cc435f0ef4b04ab424748ecb635380d29e284f1ae81a1b33984f85997708909c108814c3e39bc70658c2a9da59b62cf

# Install Node modules for Rails' frontend assets
RUN yarn install --check-files

# Precompile assets for production
RUN bundle exec rails assets:precompile

# Expose the port your app runs on
EXPOSE 3000

# Start Supervisor, which will manage all services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
