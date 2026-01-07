FROM ruby:3.0

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile
COPY Gemfile ./

# Install gems for the correct platform
RUN bundle lock --add-platform x86_64-linux && bundle install

# Copy the rest of the application
COPY . .

# Expose port 4000 for Jekyll
EXPOSE 4000

# Build the site and serve
CMD ["sh", "-c", "bundle exec jekyll serve --host=0.0.0.0 --port=4000 --config=_config.yml,_config_dev.yml"]