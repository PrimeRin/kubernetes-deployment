# Use the official Ruby image
FROM ruby:3.3.0

# Set environment variables
ENV RAILS_ENV=development

# Set the working directory in the Docker container
WORKDIR /app

# Copy the Gemfile and Gemfile.lock to the container
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the entire Rails app into the container
COPY . .

# Expose the Rails server port
EXPOSE 3000

# Remove a potentially pre-existing server.pid for Rails
RUN rm -f tmp/pids/server.pid

# Command to run the Rails server
CMD ["rails", "server", "-b", "0.0.0.0"]
