FROM ruby:3.0

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock (if exists) for reproducible builds
COPY Gemfile Gemfile.lock* ./

# Install gems for the correct platform
# If Gemfile.lock doesn't exist, create it and install
RUN bundle lock --add-platform x86_64-linux 2>/dev/null || true && \
    bundle install

# Copy the rest of the application
COPY . .

# Expose port 4000 for Jekyll
EXPOSE 4000

# Build the site and serve
CMD ["sh", "-c", "bundle exec jekyll serve --host=0.0.0.0 --port=4000"]